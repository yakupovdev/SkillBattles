import 'dart:async';

import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/presentation/bloc/load_status.dart';
import 'package:skill_battles/core/presentation/bloc/signal_bloc.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/account/domain/entity/statistics_entity.dart';
import 'package:skill_battles/features/account/domain/usecases/get_statistics_usecase.dart';
import 'package:skill_battles/features/matchmaking/domain/entity/join_queue_params_entity.dart';
import 'package:skill_battles/features/matchmaking/domain/entity/queue_entry_entity.dart';
import 'package:skill_battles/features/matchmaking/domain/entity/queue_entry_params_entity.dart';
import 'package:skill_battles/features/matchmaking/domain/entity/queue_status.dart';
import 'package:skill_battles/features/matchmaking/domain/usecases/cancel_queue_entry_usecase.dart';
import 'package:skill_battles/features/matchmaking/domain/usecases/get_queue_entry_usecase.dart';
import 'package:skill_battles/features/matchmaking/domain/usecases/join_queue_usecase.dart';
import 'package:skill_battles/features/matchmaking/domain/usecases/watch_queue_entry_usecase.dart';

part 'ranked_search_event.dart';
part 'ranked_search_state.dart';

/// Ranked search: join (or resume) an entry, follow QUEUE_CHANGED with a
/// polling fallback, cancel. MATCHED hands over to the battle; an
/// asynchronous cancellation (e.g. QUOTA_EXHAUSTED) frees the screen.
final class RankedSearchBloc
    extends SignalBloc<RankedSearchEvent, RankedSearchState> {
  RankedSearchBloc({
    required this._joinQueue,
    required this._getEntry,
    required this._cancelEntry,
    required this._watchEntry,
    required this._watchConnection,
    required this._getStatistics,
    this.pollInterval = const Duration(seconds: 4),
  }) : super(const RankedSearchState()) {
    handle<RankedSearchStarted>(_onStarted, transformer: droppable());
    handle<RankedSearchCancelRequested>(_onCancel, transformer: droppable());
    handle<_EntryReceived>(_onEntryReceived);
    handle<_RefreshTick>(_onRefreshTick, transformer: droppable());
    handle<_StatisticsRequested>(_onStatisticsRequested, transformer: droppable());
  }

  final JoinQueueUsecase _joinQueue;
  final GetQueueEntryUsecase _getEntry;
  final CancelQueueEntryUsecase _cancelEntry;
  final WatchQueueEntryUsecase _watchEntry;
  final WatchConnectionUsecase _watchConnection;
  final GetStatisticsUsecase _getStatistics;
  final Duration pollInterval;

  StreamSubscription<QueueEntryEntity>? _entrySubscription;
  StreamSubscription<RealtimeStatus>? _connectionSubscription;
  Timer? _poll;

  Future<void> _onStarted(
    RankedSearchStarted event,
    Emitter<RankedSearchState> emit,
  ) async {
    // A retry follows a new resource.
    await _entrySubscription?.cancel();
    _entrySubscription = null;
    _poll?.cancel();
    _poll = null;
    emit(
      RankedSearchState(
        status: RankedSearchStatus.joining,
        disciplineCode: event.disciplineCode,
        statistics: stateValue.statistics,
      ),
    );
    if (stateValue.statistics == null) add(const _StatisticsRequested());
    final String? resumeId = event.entryId;
    if (resumeId != null) {
      _follow(resumeId);
      await _refresh(resumeId, emit);
      return;
    }
    final String? code = event.disciplineCode;
    if (code == null) {
      emit(stateValue.copyWith(status: RankedSearchStatus.failure));
      return;
    }
    final Either<Failure, QueueEntryEntity> result = await _joinQueue(
      JoinQueueParamsEntity(disciplineCode: code),
    );
    if (emit.isDone) return;
    await result.match(
      (Failure failure) async => emit(
        stateValue.copyWith(status: RankedSearchStatus.failure, failure: failure),
      ),
      (QueueEntryEntity entry) async {
        _apply(entry, emit);
        if (!entry.isTerminal && entry.status != QueueStatus.matched) {
          // Subscribe, then re-read to close the gap since the response.
          _follow(entry.id);
          await _refresh(entry.id, emit);
        }
      },
    );
  }

  void _follow(String entryId) {
    final QueueEntryParamsEntity params = QueueEntryParamsEntity(
      entryId: entryId,
    );
    _entrySubscription ??= _watchEntry(params)
        .listen((QueueEntryEntity entry) => add(_EntryReceived(entry)));
    _connectionSubscription ??= _watchConnection(const NoParams())
        .where((RealtimeStatus status) => status == RealtimeStatus.connected)
        .listen((_) => add(const _RefreshTick()));
    _poll ??= Timer.periodic(pollInterval, (_) => add(const _RefreshTick()));
  }

  Future<void> _refresh(String entryId, Emitter<RankedSearchState> emit) async {
    final Either<Failure, QueueEntryEntity> result = await _getEntry(
      QueueEntryParamsEntity(entryId: entryId),
    );
    if (emit.isDone) return;
    result.match((Failure failure) {
      if (stateValue.entry == null) {
        emit(
          stateValue.copyWith(status: RankedSearchStatus.failure, failure: failure),
        );
      }
    }, (QueueEntryEntity entry) => _apply(entry, emit));
  }

  /// The own rating turns the ± window into a rating range. The search
  /// works without it, so a failure only leaves the range out.
  Future<void> _onStatisticsRequested(
    _StatisticsRequested event,
    Emitter<RankedSearchState> emit,
  ) async {
    final Either<Failure, StatisticsEntity> result = await _getStatistics(
      const NoParams(),
    );
    if (emit.isDone) return;
    final StatisticsEntity? statistics = result.toNullable();
    if (statistics != null) emit(stateValue.copyWith(statistics: statistics));
  }

  void _onEntryReceived(_EntryReceived event, Emitter<RankedSearchState> emit) {
    _apply(event.entry, emit);
  }

  Future<void> _onRefreshTick(
    _RefreshTick event,
    Emitter<RankedSearchState> emit,
  ) async {
    final QueueEntryEntity? entry = stateValue.entry;
    if (entry == null || stateValue.isOver) return;
    await _refresh(entry.id, emit);
  }

  void _apply(QueueEntryEntity entry, Emitter<RankedSearchState> emit) {
    final QueueEntryEntity? current = stateValue.entry;
    if (current != null &&
        current.id == entry.id &&
        entry.version < current.version) {
      return;
    }
    final RankedSearchStatus status = switch (entry.status) {
      QueueStatus.searching => RankedSearchStatus.searching,
      QueueStatus.matched => RankedSearchStatus.matched,
      QueueStatus.cancelled || QueueStatus.expired => RankedSearchStatus.ended,
    };
    emit(
      stateValue.copyWith(
        status: status,
        entry: entry,
        disciplineCode: entry.disciplineCode,
        resetFailure: true,
      ),
    );
    if (stateValue.isOver) _stopFollowing();
  }

  Future<void> _onCancel(
    RankedSearchCancelRequested event,
    Emitter<RankedSearchState> emit,
  ) async {
    final QueueEntryEntity? entry = stateValue.entry;
    if (entry == null || stateValue.isOver) {
      emit(stateValue.copyWith(cancelStatus: LoadStatus.success));
      return;
    }
    emit(stateValue.copyWith(cancelStatus: LoadStatus.loading));
    final Either<Failure, Unit> result = await _cancelEntry(
      QueueEntryParamsEntity(entryId: entry.id),
    );
    if (emit.isDone) return;
    await result.match(
      (Failure failure) async {
        if (failure.hasCode(ApiErrorCodes.matchAlreadyFound)) {
          // Too late: the match exists. Go on to it.
          emit(stateValue.copyWith(cancelStatus: LoadStatus.initial));
          await _refresh(entry.id, emit);
          return;
        }
        emit(
          stateValue.copyWith(
            cancelStatus: LoadStatus.failure,
            cancelFailure: failure,
          ),
        );
      },
      (_) async {
        _stopFollowing();
        emit(stateValue.copyWith(cancelStatus: LoadStatus.success));
      },
    );
  }

  void _stopFollowing() {
    _poll?.cancel();
    _poll = null;
  }

  @override
  Future<void> close() async {
    _stopFollowing();
    await _entrySubscription?.cancel();
    await _connectionSubscription?.cancel();
    return super.close();
  }
}
