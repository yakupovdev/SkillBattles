import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/presentation/bloc/load_status.dart';
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
final class PrivateDuelBloc extends Bloc<PrivateDuelEvent, PrivateDuelState> {
  PrivateDuelBloc({
    required this._createDuel,
    required this._getDuel,
    required this._cancelDuel,
    required this._watchDuel,
    required this._watchConnection,
    this.pollInterval = const Duration(seconds: 4),
  }) : super(const PrivateDuelState()) {
    on<PrivateDuelStarted>(_onStarted, transformer: droppable());
    on<PrivateDuelCancelRequested>(_onCancel, transformer: droppable());
    on<_DuelReceived>(_onDuelReceived);
    on<_DuelRefreshTick>(_onRefreshTick, transformer: droppable());
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

  Future<void> _onStarted(
    PrivateDuelStarted event,
    Emitter<PrivateDuelState> emit,
  ) async {
    // A retry follows a new resource.
    await _duelSubscription?.cancel();
    _duelSubscription = null;
    _poll?.cancel();
    _poll = null;
    emit(const PrivateDuelState(loadStatus: LoadStatus.loading));
    final String? duelId = event.duelId;
    if (duelId != null) {
      _follow(duelId);
      await _refresh(duelId, emit);
      return;
    }
    final String? code = event.disciplineCode;
    if (code == null) {
      emit(state.copyWith(loadStatus: LoadStatus.failure));
      return;
    }
    final Either<Failure, DuelEntity> result = await _createDuel(
      CreateDuelParamsEntity(disciplineCode: code),
    );
    if (emit.isDone) return;
    await result.match(
      (Failure failure) async => emit(
        state.copyWith(loadStatus: LoadStatus.failure, failure: failure),
      ),
      (DuelEntity duel) async {
        _apply(duel, emit);
        _follow(duel.id);
        await _refresh(duel.id, emit);
      },
    );
  }

  void _follow(String duelId) {
    _duelSubscription ??= _watchDuel(DuelParamsEntity(duelId: duelId))
        .listen((DuelEntity duel) => add(_DuelReceived(duel)));
    _connectionSubscription ??= _watchConnection(const NoParams())
        .where((RealtimeStatus status) => status == RealtimeStatus.connected)
        .listen((_) => add(const _DuelRefreshTick()));
    _poll ??= Timer.periodic(
      pollInterval,
      (_) => add(const _DuelRefreshTick()),
    );
  }

  Future<void> _refresh(String duelId, Emitter<PrivateDuelState> emit) async {
    final Either<Failure, DuelEntity> result = await _getDuel(
      DuelParamsEntity(duelId: duelId),
    );
    if (emit.isDone) return;
    result.match((Failure failure) {
      if (state.duel == null) {
        emit(state.copyWith(loadStatus: LoadStatus.failure, failure: failure));
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
    final DuelEntity? duel = state.duel;
    if (duel == null || duel.status != DuelStatus.waiting) return;
    await _refresh(duel.id, emit);
  }

  void _apply(DuelEntity duel, Emitter<PrivateDuelState> emit) {
    final DuelEntity? current = state.duel;
    if (current != null &&
        current.id == duel.id &&
        duel.version < current.version) {
      return;
    }
    emit(
      state.copyWith(
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
    final DuelEntity? duel = state.duel;
    if (duel == null || duel.status != DuelStatus.waiting) {
      emit(state.copyWith(cancelStatus: LoadStatus.success));
      return;
    }
    emit(state.copyWith(cancelStatus: LoadStatus.loading));
    final Either<Failure, Unit> result = await _cancelDuel(
      DuelParamsEntity(duelId: duel.id),
    );
    if (emit.isDone) return;
    await result.match(
      (Failure failure) async {
        if (failure.hasCode(ApiErrorCodes.matchAlreadyFound)) {
          emit(state.copyWith(cancelStatus: LoadStatus.initial));
          await _refresh(duel.id, emit);
          return;
        }
        emit(
          state.copyWith(
            cancelStatus: LoadStatus.failure,
            cancelFailure: failure,
          ),
        );
      },
      (_) async {
        _stopPolling();
        emit(state.copyWith(cancelStatus: LoadStatus.success));
      },
    );
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  @override
  Future<void> close() async {
    _stopPolling();
    await _duelSubscription?.cancel();
    await _connectionSubscription?.cancel();
    return super.close();
  }
}
