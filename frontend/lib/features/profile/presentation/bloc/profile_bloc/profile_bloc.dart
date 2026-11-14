import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:skill_battles/core/domain/entity/battle_mode.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/presentation/bloc/load_status.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/account/domain/entity/season_history_page_entity.dart';
import 'package:skill_battles/features/account/domain/entity/season_history_params_entity.dart';
import 'package:skill_battles/features/account/domain/entity/statistics_entity.dart';
import 'package:skill_battles/features/account/domain/usecases/get_season_history_usecase.dart';
import 'package:skill_battles/features/account/domain/usecases/get_statistics_usecase.dart';
import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';
import 'package:skill_battles/features/catalog/domain/entity/rank_ladder_entity.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_disciplines_usecase.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_ranks_usecase.dart';
import 'package:skill_battles/features/history/domain/entity/history_page_entity.dart';
import 'package:skill_battles/features/history/domain/entity/history_params_entity.dart';
import 'package:skill_battles/features/history/domain/usecases/get_history_usecase.dart';

part 'profile_event.dart';
part 'profile_state.dart';

/// Statistics (basic for all, advanced for Pro), season peaks and the
/// server-paged match history.
final class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required this._getStatistics,
    required this._getDisciplines,
    required this._getRanks,
    required this._getSeasonHistory,
    required this._getHistory,
  }) : super(const ProfileState()) {
    on<ProfileStarted>(_onStarted, transformer: restartable());
    on<ProfileRefreshRequested>(_onStarted, transformer: restartable());
    on<ProfileDisciplineSelected>(_onDisciplineSelected);
    on<ProfileHistoryChanged>(_onHistoryChanged, transformer: restartable());
  }

  final GetStatisticsUsecase _getStatistics;
  final GetDisciplinesUsecase _getDisciplines;
  final GetRanksUsecase _getRanks;
  final GetSeasonHistoryUsecase _getSeasonHistory;
  final GetHistoryUsecase _getHistory;

  static const int historyPageSize = 10;

  Future<void> _onStarted(
    ProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(
      state.copyWith(
        loadStatus: LoadStatus.loading,
        historyStatus: LoadStatus.loading,
      ),
    );
    final (
      Either<Failure, StatisticsEntity> statistics,
      Either<Failure, List<DisciplineEntity>> disciplines,
      Either<Failure, RankLadderEntity> ranks,
      Either<Failure, SeasonHistoryPageEntity> seasons,
      Either<Failure, HistoryPageEntity> history,
    ) = await (
      _getStatistics(const NoParams()),
      _getDisciplines(const NoParams()),
      _getRanks(const NoParams()),
      _getSeasonHistory(const SeasonHistoryParamsEntity()),
      _getHistory(state.historyParams),
    ).wait;
    if (emit.isDone) return;
    statistics.match(
      (Failure failure) => emit(
        state.copyWith(loadStatus: LoadStatus.failure, failure: failure),
      ),
      (StatisticsEntity value) {
        final List<DisciplineEntity> list = disciplines.getOrElse(
          (_) => const <DisciplineEntity>[],
        );
        final String? selected =
            state.selectedCode ??
            (list.isNotEmpty
                ? list.first.code
                : value.disciplines.isEmpty
                ? null
                : value.disciplines.first.disciplineCode);
        emit(
          state.copyWith(
            loadStatus: LoadStatus.success,
            statistics: value,
            disciplines: list,
            ranks: ranks.toNullable(),
            seasons: seasons.toNullable(),
            selectedCode: selected,
            resetFailure: true,
          ),
        );
      },
    );
    _applyHistory(history, emit);
  }

  void _onDisciplineSelected(
    ProfileDisciplineSelected event,
    Emitter<ProfileState> emit,
  ) {
    emit(state.copyWith(selectedCode: event.code));
  }

  Future<void> _onHistoryChanged(
    ProfileHistoryChanged event,
    Emitter<ProfileState> emit,
  ) async {
    final HistoryParamsEntity params = HistoryParamsEntity(
      page: event.page,
      size: historyPageSize,
      mode: event.mode,
      disciplineCode: event.disciplineCode,
    );
    emit(
      state.copyWith(historyStatus: LoadStatus.loading, historyParams: params),
    );
    final Either<Failure, HistoryPageEntity> result = await _getHistory(params);
    if (emit.isDone || params != state.historyParams) return;
    _applyHistory(result, emit);
  }

  void _applyHistory(
    Either<Failure, HistoryPageEntity> result,
    Emitter<ProfileState> emit,
  ) {
    result.match(
      (Failure failure) => emit(
        state.copyWith(
          historyStatus: LoadStatus.failure,
          historyFailure: failure,
        ),
      ),
      (HistoryPageEntity page) => emit(
        state.copyWith(
          historyStatus: LoadStatus.success,
          history: page,
          resetHistoryFailure: true,
        ),
      ),
    );
  }
}
