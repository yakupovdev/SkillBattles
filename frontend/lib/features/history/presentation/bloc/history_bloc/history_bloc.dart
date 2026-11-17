import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/battle_mode.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/presentation/bloc/load_status.dart';
import 'package:skill_battles/core/presentation/bloc/signal_bloc.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_disciplines_usecase.dart';
import 'package:skill_battles/features/history/domain/entity/history_page_entity.dart';
import 'package:skill_battles/features/history/domain/entity/history_params_entity.dart';
import 'package:skill_battles/features/history/domain/usecases/get_history_usecase.dart';

part 'history_event.dart';
part 'history_state.dart';

/// Server-paged match history with a discipline and a mode filter. The
/// latest filter or page wins; an older answer never replaces a newer one.
final class HistoryBloc extends SignalBloc<HistoryEvent, HistoryState> {
  HistoryBloc({required this._getDisciplines, required this._getHistory})
    : super(const HistoryState()) {
    handle<HistoryStarted>(_onStarted, transformer: droppable());
    handle<HistoryParamsChanged>(_onParamsChanged, transformer: restartable());
  }

  final GetDisciplinesUsecase _getDisciplines;
  final GetHistoryUsecase _getHistory;

  static const int pageSize = 10;

  Future<void> _onStarted(
    HistoryStarted event,
    Emitter<HistoryState> emit,
  ) async {
    emit(stateValue.copyWith(loadStatus: LoadStatus.loading));
    final HistoryParamsEntity params = stateValue.params;
    final (
      Either<Failure, List<DisciplineEntity>> disciplines,
      Either<Failure, HistoryPageEntity> history,
    ) = await (
      _getDisciplines(const NoParams()),
      _getHistory(params),
    ).wait;
    if (emit.isDone || params != stateValue.params) return;
    // Discipline names fall back to the code, so a missing catalogue does
    // not fail the page.
    emit(
      stateValue.copyWith(
        disciplines: disciplines.getOrElse((_) => const <DisciplineEntity>[]),
      ),
    );
    _apply(history, emit);
  }

  Future<void> _onParamsChanged(
    HistoryParamsChanged event,
    Emitter<HistoryState> emit,
  ) async {
    final HistoryParamsEntity params = HistoryParamsEntity(
      page: event.page,
      size: pageSize,
      mode: event.mode,
      disciplineCode: event.disciplineCode,
    );
    emit(stateValue.copyWith(loadStatus: LoadStatus.loading, params: params));
    final Either<Failure, HistoryPageEntity> result = await _getHistory(params);
    if (emit.isDone || params != stateValue.params) return;
    _apply(result, emit);
  }

  void _apply(
    Either<Failure, HistoryPageEntity> result,
    Emitter<HistoryState> emit,
  ) {
    result.match(
      (Failure failure) => emit(
        stateValue.copyWith(loadStatus: LoadStatus.failure, failure: failure),
      ),
      (HistoryPageEntity page) => emit(
        stateValue.copyWith(
          loadStatus: LoadStatus.success,
          page: page,
          resetFailure: true,
        ),
      ),
    );
  }
}
