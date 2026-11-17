import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/presentation/bloc/load_status.dart';
import 'package:skill_battles/core/presentation/bloc/signal_bloc.dart';
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

part 'profile_event.dart';
part 'profile_state.dart';

/// Statistics (basic for all, advanced for Pro) and season peaks.
final class ProfileBloc extends SignalBloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required this._getStatistics,
    required this._getDisciplines,
    required this._getRanks,
    required this._getSeasonHistory,
  }) : super(const ProfileState()) {
    handle<ProfileStarted>(_onStarted, transformer: restartable());
    handle<ProfileRefreshRequested>(_onStarted, transformer: restartable());
    handle<ProfileDisciplineSelected>(_onDisciplineSelected);
  }

  final GetStatisticsUsecase _getStatistics;
  final GetDisciplinesUsecase _getDisciplines;
  final GetRanksUsecase _getRanks;
  final GetSeasonHistoryUsecase _getSeasonHistory;

  Future<void> _onStarted(
    ProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(stateValue.copyWith(loadStatus: LoadStatus.loading));
    final (
      Either<Failure, StatisticsEntity> statistics,
      Either<Failure, List<DisciplineEntity>> disciplines,
      Either<Failure, RankLadderEntity> ranks,
      Either<Failure, SeasonHistoryPageEntity> seasons,
    ) = await (
      _getStatistics(const NoParams()),
      _getDisciplines(const NoParams()),
      _getRanks(const NoParams()),
      _getSeasonHistory(const SeasonHistoryParamsEntity()),
    ).wait;
    if (emit.isDone) return;
    statistics.match(
      (Failure failure) => emit(
        stateValue.copyWith(loadStatus: LoadStatus.failure, failure: failure),
      ),
      (StatisticsEntity value) {
        final List<DisciplineEntity> list = disciplines.getOrElse(
          (_) => const <DisciplineEntity>[],
        );
        final String? selected =
            stateValue.selectedCode ??
            (list.isNotEmpty
                ? list.first.code
                : value.disciplines.isEmpty
                ? null
                : value.disciplines.first.disciplineCode);
        emit(
          stateValue.copyWith(
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
  }

  void _onDisciplineSelected(
    ProfileDisciplineSelected event,
    Emitter<ProfileState> emit,
  ) {
    emit(stateValue.copyWith(selectedCode: event.code));
  }
}
