import 'dart:async';

import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/battle_mode.dart';
import 'package:skill_battles/core/domain/entity/battle_result_entity.dart';
import 'package:skill_battles/core/presentation/bloc/load_status.dart';
import 'package:skill_battles/core/presentation/bloc/signal_bloc.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/battle_result/domain/entity/battle_review_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/rematch_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/rematch_status.dart';
import 'package:skill_battles/features/battle_result/domain/entity/report_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/report_params_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/result_params_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/review_params_entity.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/cancel_rematch_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/get_rematch_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/get_result_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/get_review_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/report_round_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/request_rematch_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/watch_rematch_usecase.dart';

part 'battle_result_event.dart';
part 'battle_result_state.dart';

/// Saved result, plan-gated review, private rematch and question reports.
/// Everything is re-read when the entitlement version changes, so an
/// upgrade opens old reviews and a downgrade closes them again.
final class BattleResultBloc
    extends SignalBloc<BattleResultEvent, BattleResultState> {
  BattleResultBloc({
    required this.battleId,
    required this._getResult,
    required this._getReview,
    required this._getRematch,
    required this._requestRematch,
    required this._cancelRematch,
    required this._watchRematch,
    required this._reportRound,
  }) : super(const BattleResultState()) {
    handle<BattleResultStarted>(_onStarted, transformer: restartable());
    handle<BattleResultRefreshRequested>(_onStarted, transformer: restartable());
    handle<BattleResultMistakesOnlyChanged>(
      _onMistakesOnlyChanged,
      transformer: restartable(),
    );
    handle<BattleResultRematchRequested>(
      _onRematchRequested,
      transformer: droppable(),
    );
    handle<BattleResultRematchCancelled>(
      _onRematchCancelled,
      transformer: droppable(),
    );
    handle<BattleResultReportSubmitted>(
      _onReportSubmitted,
      transformer: droppable(),
    );
    handle<BattleResultReportDismissed>(_onReportDismissed);
    handle<_RematchReceived>(_onRematchReceived);
  }

  final String battleId;
  final GetResultUsecase _getResult;
  final GetReviewUsecase _getReview;
  final GetRematchUsecase _getRematch;
  final RequestRematchUsecase _requestRematch;
  final CancelRematchUsecase _cancelRematch;
  final WatchRematchUsecase _watchRematch;
  final ReportRoundUsecase _reportRound;

  StreamSubscription<RematchEntity>? _rematchSubscription;

  ResultParamsEntity get _params => ResultParamsEntity(battleId: battleId);

  Future<void> _onStarted(
    BattleResultEvent event,
    Emitter<BattleResultState> emit,
  ) async {
    // Paid data of the previous rights is dropped before the new read.
    emit(
      stateValue.copyWith(
        resultStatus: LoadStatus.loading,
        reviewStatus: LoadStatus.loading,
        resetReview: true,
      ),
    );
    final Either<Failure, BattleResultEntity> result = await _getResult(
      _params,
    );
    if (emit.isDone) return;
    final BattleResultEntity? loaded = result.toNullable();
    if (loaded == null) {
      final Failure failure = result.getLeft()!;
      emit(
        stateValue.copyWith(
          resultStatus: LoadStatus.failure,
          resultFailure: failure,
          reviewStatus: LoadStatus.initial,
        ),
      );
      return;
    }
    emit(
      stateValue.copyWith(
        resultStatus: LoadStatus.success,
        result: loaded,
        resetResultFailure: true,
      ),
    );
    if (loaded.mode == BattleMode.private) {
      _rematchSubscription ??= _watchRematch(_params)
          .listen((RematchEntity rematch) => add(_RematchReceived(rematch)));
    }
    await Future.wait(<Future<void>>[
      _loadReview(emit),
      if (loaded.mode == BattleMode.private) _loadRematch(emit),
    ]);
  }

  Future<void> _loadReview(Emitter<BattleResultState> emit) async {
    final bool mistakesOnly = stateValue.mistakesOnly;
    final Either<Failure, BattleReviewEntity> review = await _getReview(
      ReviewParamsEntity(battleId: battleId, mistakesOnly: mistakesOnly),
    );
    if (emit.isDone || mistakesOnly != stateValue.mistakesOnly) return;
    review.match(
      (Failure failure) => emit(
        stateValue.copyWith(
          reviewStatus: LoadStatus.failure,
          reviewFailure: failure,
        ),
      ),
      (BattleReviewEntity value) => emit(
        stateValue.copyWith(
          reviewStatus: LoadStatus.success,
          review: value,
          resetReviewFailure: true,
        ),
      ),
    );
  }

  Future<void> _loadRematch(Emitter<BattleResultState> emit) async {
    final Either<Failure, RematchEntity?> rematch = await _getRematch(_params);
    if (emit.isDone) return;
    rematch.match((_) {}, (RematchEntity? value) {
      if (value != null) _applyRematch(value, emit);
    });
  }

  Future<void> _onMistakesOnlyChanged(
    BattleResultMistakesOnlyChanged event,
    Emitter<BattleResultState> emit,
  ) async {
    emit(
      stateValue.copyWith(
        mistakesOnly: event.mistakesOnly,
        reviewStatus: LoadStatus.loading,
        resetReview: true,
      ),
    );
    await _loadReview(emit);
  }

  Future<void> _onRematchRequested(
    BattleResultRematchRequested event,
    Emitter<BattleResultState> emit,
  ) async {
    emit(
      stateValue.copyWith(
        rematchActionStatus: LoadStatus.loading,
        resetRematchFailure: true,
      ),
    );
    final Either<Failure, RematchEntity> result = await _requestRematch(
      _params,
    );
    if (emit.isDone) return;
    result.match(
      (Failure failure) => emit(
        stateValue.copyWith(
          rematchActionStatus: LoadStatus.failure,
          rematchFailure: failure,
        ),
      ),
      (RematchEntity rematch) {
        emit(stateValue.copyWith(rematchActionStatus: LoadStatus.success));
        _applyRematch(rematch, emit);
      },
    );
  }

  Future<void> _onRematchCancelled(
    BattleResultRematchCancelled event,
    Emitter<BattleResultState> emit,
  ) async {
    emit(stateValue.copyWith(rematchActionStatus: LoadStatus.loading));
    final Either<Failure, Unit> result = await _cancelRematch(_params);
    if (emit.isDone) return;
    await result.match(
      (Failure failure) async => emit(
        stateValue.copyWith(
          rematchActionStatus: LoadStatus.failure,
          rematchFailure: failure,
        ),
      ),
      (_) async {
        emit(stateValue.copyWith(rematchActionStatus: LoadStatus.success));
        await _loadRematch(emit);
      },
    );
  }

  void _onRematchReceived(
    _RematchReceived event,
    Emitter<BattleResultState> emit,
  ) => _applyRematch(event.rematch, emit);

  void _applyRematch(RematchEntity rematch, Emitter<BattleResultState> emit) {
    final RematchEntity? current = stateValue.rematch;
    if (current != null && rematch.version < current.version) return;
    emit(stateValue.copyWith(rematch: rematch));
  }

  Future<void> _onReportSubmitted(
    BattleResultReportSubmitted event,
    Emitter<BattleResultState> emit,
  ) async {
    emit(
      stateValue.copyWith(
        reportStatus: LoadStatus.loading,
        reportingRoundId: event.params.roundId,
        resetReportFailure: true,
      ),
    );
    final Either<Failure, ReportEntity> result = await _reportRound(
      event.params,
    );
    if (emit.isDone) return;
    result.match(
      (Failure failure) => emit(
        stateValue.copyWith(
          reportStatus: LoadStatus.failure,
          reportFailure: failure,
        ),
      ),
      (ReportEntity report) => emit(
        stateValue.copyWith(
          reportStatus: LoadStatus.success,
          reportedRoundIds: <String>{...stateValue.reportedRoundIds, report.roundId},
        ),
      ),
    );
  }

  void _onReportDismissed(
    BattleResultReportDismissed event,
    Emitter<BattleResultState> emit,
  ) {
    emit(
      stateValue.copyWith(
        reportStatus: LoadStatus.initial,
        resetReportFailure: true,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _rematchSubscription?.cancel();
    return super.close();
  }
}

/// Whether the rematch is waiting for this player to answer.
extension RematchView on RematchEntity {
  bool get isActive => status == RematchStatus.waiting;
}
