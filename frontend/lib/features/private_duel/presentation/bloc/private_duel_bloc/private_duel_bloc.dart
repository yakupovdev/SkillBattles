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
import 'package:skill_battles/features/private_duel/domain/entity/create_duel_params_entity.dart';
import 'package:skill_battles/features/private_duel/domain/entity/duel_entity.dart';
import 'package:skill_battles/features/private_duel/domain/entity/duel_params_entity.dart';
import 'package:skill_battles/features/private_duel/domain/entity/duel_status.dart';
import 'package:skill_battles/features/private_duel/domain/usecases/cancel_duel_usecase.dart';
import 'package:skill_battles/features/private_duel/domain/usecases/create_duel_usecase.dart';
import 'package:skill_battles/features/private_duel/domain/usecases/get_duel_usecase.dart';
import 'package:skill_battles/features/private_duel/domain/usecases/watch_duel_usecase.dart';

part 'private_duel_event.dart';
part 'private_duel_state.dart';

/// The host's code room: create (or resume), wait for the guest, cancel.
/// MATCHED hands over to the battle, where both players pass Ready.
final class PrivateDuelBloc extends SignalBloc<PrivateDuelEvent, PrivateDuelState> {
  PrivateDuelBloc({
    required this._createDuel,
    required this._getDuel,
    required this._cancelDuel,
    required this._watchDuel,
    required this._watchConnection,
    this.pollInterval = const Duration(seconds: 4),
  }) : super(const PrivateDuelState()) {
    handle<PrivateDuelStarted>(_onStarted, transformer: droppable());
    handle<PrivateDuelCancelRequested>(_onCancel, transformer: droppable());
    handle<_DuelReceived>(_onDuelReceived);
    handle<_DuelRefreshTick>(_onRefreshTick, transformer: droppable());
  }

  final CreateDuelUsecase _createDuel;
  final GetDuelUsecase _getDuel;
  final CancelDuelUsecase _cancelDuel;
  final WatchDuelUsecase _watchDuel;
  final WatchConnectionUsecase _watchConnection;
  final Duration pollInterval;

  StreamSubscription<DuelEntity>? _duelSubscription;
  StreamSubscription<RealtimeStatus>? _connectionSubscription;
  Timer? _poll;
  Future<Either<Failure, DuelEntity>>? _initialDuelRequest;
  Future<Either<Failure, Unit>>? _cancelRequest;
  String? _cancelRequestDuelId;
  Future<void>? _closeFuture;
  bool _isClosing = false;

  Future<void> _onStarted(
    PrivateDuelStarted event,
    Emitter<PrivateDuelState> emit,
  ) async {
    if (_isClosing) return;
    // A retry follows a new resource.
    await _duelSubscription?.cancel();
    if (emit.isDone || _isClosing) return;
    _duelSubscription = null;
    _poll?.cancel();
    _poll = null;
    _initialDuelRequest = null;
    emit(const PrivateDuelState(loadStatus: LoadStatus.loading));
    final String? duelId = event.duelId;
    if (duelId != null) {
      _follow(duelId);
      await _refresh(duelId, emit, initial: true);
      return;
    }
    final String? code = event.disciplineCode;
    if (code == null) {
      emit(stateValue.copyWith(loadStatus: LoadStatus.failure));
      return;
    }
    final Future<Either<Failure, DuelEntity>> request = _createDuel(
      CreateDuelParamsEntity(disciplineCode: code),
    );
    _initialDuelRequest = request;
    final Either<Failure, DuelEntity> result = await request;
    if (emit.isDone || _isClosing) return;
    await result.match(
      (Failure failure) async => emit(
        stateValue.copyWith(loadStatus: LoadStatus.failure, failure: failure),
      ),
      (DuelEntity duel) async {
        _apply(duel, emit);
        _follow(duel.id);
        await _refresh(duel.id, emit);
      },
    );
  }

  void _follow(String duelId) {
    if (_isClosing) return;
    _duelSubscription ??= _watchDuel(DuelParamsEntity(duelId: duelId))
        .listen((DuelEntity duel) {
          if (!_isClosing) add(_DuelReceived(duel));
        });
    _connectionSubscription ??= _watchConnection(const NoParams())
        .where((RealtimeStatus status) => status == RealtimeStatus.connected)
        .listen((_) {
          if (!_isClosing) add(const _DuelRefreshTick());
        });
    _poll ??= Timer.periodic(
      pollInterval,
      (_) => add(const _DuelRefreshTick()),
    );
  }

  Future<void> _refresh(
    String duelId,
    Emitter<PrivateDuelState> emit, {
    bool initial = false,
  }) async {
    if (_isClosing) return;
    final Future<Either<Failure, DuelEntity>> request = _getDuel(
      DuelParamsEntity(duelId: duelId),
    );
    if (initial) _initialDuelRequest = request;
    final Either<Failure, DuelEntity> result = await request;
    if (emit.isDone || _isClosing) return;
    result.match((Failure failure) {
      if (stateValue.duel == null) {
        emit(stateValue.copyWith(loadStatus: LoadStatus.failure, failure: failure));
      }
    }, (DuelEntity duel) => _apply(duel, emit));
  }

  void _onDuelReceived(_DuelReceived event, Emitter<PrivateDuelState> emit) {
    _apply(event.duel, emit);
  }

  Future<void> _onRefreshTick(
    _DuelRefreshTick event,
    Emitter<PrivateDuelState> emit,
  ) async {
    final DuelEntity? duel = stateValue.duel;
    if (duel == null || duel.status != DuelStatus.waiting) return;
    await _refresh(duel.id, emit);
  }

  void _apply(DuelEntity duel, Emitter<PrivateDuelState> emit) {
    if (emit.isDone || _isClosing) return;
    final DuelEntity? current = stateValue.duel;
    if (current != null &&
        current.id == duel.id &&
        duel.version < current.version) {
      return;
    }
    emit(
      stateValue.copyWith(
        loadStatus: LoadStatus.success,
        duel: duel,
        resetFailure: true,
      ),
    );
    if (duel.status != DuelStatus.waiting) _stopPolling();
  }

  Future<void> _onCancel(
    PrivateDuelCancelRequested event,
    Emitter<PrivateDuelState> emit,
  ) async {
    if (_isClosing) return;
    final DuelEntity? duel = stateValue.duel;
    if (duel == null ||
        duel.status != DuelStatus.waiting ||
        duel.guest != null) {
      emit(stateValue.copyWith(cancelStatus: LoadStatus.success));
      return;
    }
    emit(stateValue.copyWith(cancelStatus: LoadStatus.loading));
    final Either<Failure, Unit> result = await _cancel(duel.id);
    if (emit.isDone || _isClosing) return;
    await result.match(
      (Failure failure) async {
        if (failure.hasCode(ApiErrorCodes.matchAlreadyFound)) {
          emit(stateValue.copyWith(cancelStatus: LoadStatus.initial));
          await _refresh(duel.id, emit);
          return;
        }
        _cancelRequest = null;
        emit(
          stateValue.copyWith(
            cancelStatus: LoadStatus.failure,
            cancelFailure: failure,
          ),
        );
      },
      (_) async {
        _stopPolling();
        emit(stateValue.copyWith(cancelStatus: LoadStatus.success));
      },
    );
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  Future<Either<Failure, Unit>> _cancel(String duelId) {
    if (_cancelRequestDuelId == duelId && _cancelRequest != null) {
      return _cancelRequest!;
    }
    _cancelRequestDuelId = duelId;
    return _cancelRequest = _cancelDuel(DuelParamsEntity(duelId: duelId));
  }

  @override
  Future<void> close() {
    final Future<void>? closing = _closeFuture;
    if (closing != null) return closing;
    _isClosing = true;
    _stopPolling();
    return _closeFuture = _finishClosing(<Future<void>>[
      _duelSubscription?.cancel() ?? Future<void>.value(),
      _connectionSubscription?.cancel() ?? Future<void>.value(),
      super.close(),
    ]);
  }

  Future<void> _finishClosing(List<Future<void>> cleanup) async {
    await Future.wait(cleanup);
    // Leaving while creation/resume is in flight must also release that room.
    final DuelEntity? acquired = (await _initialDuelRequest)?.toNullable();
    DuelEntity? duel = stateValue.duel;
    if (acquired != null &&
        (duel == null ||
            (duel.id == acquired.id && acquired.version > duel.version))) {
      duel = acquired;
    }
    if (duel != null &&
        duel.status == DuelStatus.waiting &&
        duel.guest == null) {
      // The server rejects cancellation if a guest joined before this request.
      await _cancel(duel.id);
    }
  }
}
