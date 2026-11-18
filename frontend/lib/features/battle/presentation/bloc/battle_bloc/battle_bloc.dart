import 'dart:async';

import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/core/domain/usecases/generate_id_usecase.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/presentation/bloc/load_status.dart';
import 'package:skill_battles/core/presentation/bloc/signal_bloc.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/battle/domain/entity/answer_receipt_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_params_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_phase.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_round_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_snapshot_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/submit_answer_params_entity.dart';
import 'package:skill_battles/features/battle/domain/usecases/get_battle_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/set_ready_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/submit_answer_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/surrender_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/watch_battle_usecase.dart';

part 'battle_event.dart';
part 'battle_state.dart';

/// The live battle.
///
/// - Subscribes to BATTLE_CHANGED first, then reads the snapshot; applies
///   only newer versions, or the same version with a new entitlement
///   version (an upgrade/downgrade changes what this reader may see).
/// - The answer is chosen locally, then submitted with a client
///   `submissionId` that is kept for retries. Pending is not accepted; an
///   accepted answer never changes.
/// - Local clocks never advance the phase: when a server transition is due
///   and no event came, the snapshot is read again.
final class BattleBloc extends SignalBloc<BattleEvent, BattleState> {
  BattleBloc({
    required this.battleId,
    required this._getBattle,
    required this._setReady,
    required this._submitAnswer,
    required this._surrender,
    required this._watchBattle,
    required this._watchConnection,
    required this._generateId,
    this.transitionGrace = const Duration(milliseconds: 1500),
    this.offlinePollInterval = const Duration(seconds: 3),
  }) : super(const BattleState()) {
    handle<BattleStarted>(_onStarted, transformer: droppable());
    handle<BattleRefreshRequested>(_onRefreshRequested, transformer: restartable());
    handle<BattleOptionSelected>(_onOptionSelected);
    handle<BattleAnswerSubmitted>(_onAnswerSubmitted, transformer: droppable());
    handle<BattleReadyPressed>(_onReadyPressed, transformer: droppable());
    handle<BattleSurrenderRequested>(_onSurrender, transformer: droppable());
    handle<_SnapshotReceived>(_onSnapshotReceived);
    handle<_ConnectionChanged>(_onConnectionChanged);
  }

  final String battleId;
  final GetBattleUsecase _getBattle;
  final SetReadyUsecase _setReady;
  final SubmitAnswerUsecase _submitAnswer;
  final SurrenderUsecase _surrender;
  final WatchBattleUsecase _watchBattle;
  final WatchConnectionUsecase _watchConnection;
  final GenerateIdUsecase _generateId;
  final Duration transitionGrace;
  final Duration offlinePollInterval;

  StreamSubscription<BattleSnapshotEntity>? _battleSubscription;
  StreamSubscription<RealtimeStatus>? _connectionSubscription;
  Timer? _transitionTimer;
  Timer? _offlinePoll;

  BattleParamsEntity get _params => BattleParamsEntity(battleId: battleId);

  Future<void> _onStarted(
    BattleStarted event,
    Emitter<BattleState> emit,
  ) async {
    _battleSubscription ??= _watchBattle(_params).listen(
      (BattleSnapshotEntity snapshot) => add(_SnapshotReceived(snapshot)),
    );
    _connectionSubscription ??= _watchConnection(const NoParams())
        .listen((RealtimeStatus status) => add(_ConnectionChanged(status)));
    emit(stateValue.copyWith(loadStatus: LoadStatus.loading));
    await _load(emit, force: false);
  }

  Future<void> _onRefreshRequested(
    BattleRefreshRequested event,
    Emitter<BattleState> emit,
  ) => _load(emit, force: event.entitlementsChanged);

  Future<void> _load(Emitter<BattleState> emit, {required bool force}) async {
    final Either<Failure, BattleSnapshotEntity> result = await _getBattle(
      _params,
    );
    if (emit.isDone) return;
    result.match((Failure failure) {
      emit(stateValue.copyWith(loadStatus: LoadStatus.failure, failure: failure));
      if (stateValue.snapshot != null) _scheduleTransition(stateValue.snapshot!);
    }, (BattleSnapshotEntity snapshot) => _apply(snapshot, emit, force: force));
  }

  void _onSnapshotReceived(_SnapshotReceived event, Emitter<BattleState> emit) {
    _apply(event.snapshot, emit, force: false);
  }

  void _apply(
    BattleSnapshotEntity next,
    Emitter<BattleState> emit, {
    required bool force,
  }) {
    final BattleSnapshotEntity? current = stateValue.snapshot;
    final bool isNewer =
        current == null ||
        next.version > current.version ||
        (next.version == current.version &&
            (force ||
                next.entitlements.version != current.entitlements.version));
    if (!isNewer) {
      if (stateValue.loadStatus != LoadStatus.success) {
        emit(
          stateValue.copyWith(loadStatus: LoadStatus.success, resetFailure: true),
        );
      }
      return;
    }
    final BattleRoundEntity? round = next.round;
    final bool sameRound = round != null && round.id == stateValue.roundId;
    AnswerSubmission? submission = sameRound ? stateValue.submission : null;
    String? selected = sameRound ? stateValue.selectedOptionId : null;
    final String? accepted = round?.mySelectedOptionId;
    if (round != null && accepted != null) {
      // The server holds this answer: it is final.
      submission = AnswerSubmission(
        roundId: round.id,
        optionId: accepted,
        submissionId: submission?.submissionId ?? '',
        status: SubmissionStatus.accepted,
      );
      selected = accepted;
    } else if (submission != null &&
        submission.status == SubmissionStatus.sending &&
        next.phase != BattlePhase.question) {
      submission = submission.copyWith(status: SubmissionStatus.closed);
    }
    emit(
      BattleState(
        loadStatus: LoadStatus.success,
        snapshot: next,
        roundId: round?.id,
        selectedOptionId: selected,
        submission: submission,
        readyStatus: stateValue.readyStatus,
        readyFailure: stateValue.readyFailure,
        surrenderStatus: stateValue.surrenderStatus,
        surrenderFailure: stateValue.surrenderFailure,
        connection: stateValue.connection,
      ),
    );
    _scheduleTransition(next);
  }

  /// Re-reads shortly after the next expected server transition.
  void _scheduleTransition(BattleSnapshotEntity snapshot) {
    _transitionTimer?.cancel();
    final DateTime? at = snapshot.nextTransitionAt;
    if (at == null || snapshot.phase.isTerminal) return;
    final DateTime localAt = at.subtract(snapshot.clockOffset);
    Duration wait = localAt.difference(DateTime.now()) + transitionGrace;
    if (wait.isNegative) wait = transitionGrace;
    _transitionTimer = Timer(wait, () {
      if (!isClosed) add(const BattleRefreshRequested());
    });
  }

  void _onConnectionChanged(
    _ConnectionChanged event,
    Emitter<BattleState> emit,
  ) {
    final RealtimeStatus previous = stateValue.connection;
    emit(stateValue.copyWith(connection: event.status));
    if (event.status == RealtimeStatus.connected) {
      _offlinePoll?.cancel();
      _offlinePoll = null;
      // Events may have been missed while offline.
      if (previous != RealtimeStatus.connected && stateValue.snapshot != null) {
        add(const BattleRefreshRequested());
      }
    } else {
      _offlinePoll ??= Timer.periodic(offlinePollInterval, (_) {
        if (!isClosed && !(stateValue.snapshot?.phase.isTerminal ?? false)) {
          add(const BattleRefreshRequested());
        }
      });
    }
  }

  void _onOptionSelected(
    BattleOptionSelected event,
    Emitter<BattleState> emit,
  ) {
    if (!stateValue.canChangeSelection) return;
    emit(stateValue.copyWith(selectedOptionId: event.optionId));
  }

  Future<void> _onAnswerSubmitted(
    BattleAnswerSubmitted event,
    Emitter<BattleState> emit,
  ) async {
    final BattleSnapshotEntity? snapshot = stateValue.snapshot;
    final BattleRoundEntity? round = snapshot?.round;
    final String? optionId = stateValue.selectedOptionId;
    if (snapshot == null ||
        round == null ||
        optionId == null ||
        snapshot.phase != BattlePhase.question ||
        !stateValue.canSubmit) {
      return;
    }
    final AnswerSubmission? previous = stateValue.submission;
    // A retry keeps the id (and the option) of the first attempt.
    final String submissionId =
        previous != null &&
            previous.roundId == round.id &&
            previous.submissionId.isNotEmpty
        ? previous.submissionId
        : _generateId(const NoParams());
    final AnswerSubmission sending = AnswerSubmission(
      roundId: round.id,
      optionId: previous?.optionId ?? optionId,
      submissionId: submissionId,
      status: SubmissionStatus.sending,
    );
    emit(stateValue.copyWith(submission: sending));
    final Either<Failure, AnswerReceiptEntity> result = await _submitAnswer(
      SubmitAnswerParamsEntity(
        battleId: battleId,
        roundId: round.id,
        optionId: sending.optionId,
        submissionId: submissionId,
      ),
    );
    if (emit.isDone) return;
    // The round may have moved on while waiting.
    final AnswerSubmission? latest = stateValue.submission;
    if (latest == null || latest.submissionId != submissionId) return;
    await result.match(
      (Failure failure) async {
        if (failure.hasCode(ApiErrorCodes.answerAlreadySubmitted) ||
            failure.hasCode(ApiErrorCodes.idempotencyConflict) ||
            failure.hasCode(ApiErrorCodes.invalidBattleState)) {
          await _load(emit, force: false);
          return;
        }
        if (failure.hasCode(ApiErrorCodes.roundClosed)) {
          emit(
            stateValue.copyWith(
              submission: latest.copyWith(
                status: SubmissionStatus.closed,
                failure: failure,
              ),
            ),
          );
          return;
        }
        emit(
          stateValue.copyWith(
            submission: latest.copyWith(
              status: SubmissionStatus.failed,
              failure: failure,
            ),
          ),
        );
      },
      (AnswerReceiptEntity receipt) async {
        emit(
          stateValue.copyWith(
            submission: latest.copyWith(
              status: SubmissionStatus.accepted,
              resetFailure: true,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onReadyPressed(
    BattleReadyPressed event,
    Emitter<BattleState> emit,
  ) async {
    emit(
      stateValue.copyWith(readyStatus: LoadStatus.loading, resetReadyFailure: true),
    );
    final Either<Failure, BattleSnapshotEntity> result = await _setReady(
      _params,
    );
    if (emit.isDone) return;
    result.match(
      (Failure failure) => emit(
        stateValue.copyWith(readyStatus: LoadStatus.failure, readyFailure: failure),
      ),
      (BattleSnapshotEntity snapshot) {
        emit(stateValue.copyWith(readyStatus: LoadStatus.success));
        _apply(snapshot, emit, force: false);
      },
    );
  }

  Future<void> _onSurrender(
    BattleSurrenderRequested event,
    Emitter<BattleState> emit,
  ) async {
    emit(stateValue.copyWith(surrenderStatus: LoadStatus.loading));
    final Either<Failure, BattleSnapshotEntity> result = await _surrender(
      _params,
    );
    if (emit.isDone) return;
    result.match(
      (Failure failure) => emit(
        stateValue.copyWith(
          surrenderStatus: LoadStatus.failure,
          surrenderFailure: failure,
        ),
      ),
      (BattleSnapshotEntity snapshot) {
        emit(stateValue.copyWith(surrenderStatus: LoadStatus.success));
        _apply(snapshot, emit, force: false);
      },
    );
  }

  @override
  Future<void> close() async {
    _transitionTimer?.cancel();
    _offlinePoll?.cancel();
    await _battleSubscription?.cancel();
    await _connectionSubscription?.cancel();
    return super.close();
  }
}
