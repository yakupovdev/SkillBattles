import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/season_entity.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/presentation/bloc/load_status.dart';
import 'package:skill_battles/core/presentation/bloc/signal_bloc.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/account/domain/entity/activity_entity.dart';
import 'package:skill_battles/features/account/domain/entity/statistics_entity.dart';
import 'package:skill_battles/features/account/domain/usecases/get_activity_usecase.dart';
import 'package:skill_battles/features/account/domain/usecases/get_statistics_usecase.dart';
import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';
import 'package:skill_battles/features/catalog/domain/entity/rank_ladder_entity.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_current_season_usecase.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_disciplines_usecase.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_ranks_usecase.dart';
import 'package:skill_battles/features/private_duel/domain/entity/duel_entity.dart';
import 'package:skill_battles/features/private_duel/domain/entity/join_duel_params_entity.dart';
import 'package:skill_battles/features/private_duel/domain/usecases/join_duel_usecase.dart';

part 'home_event.dart';
part 'home_state.dart';

/// Catalogue, current season, ratings, streaks and the live activity to
/// resume; joining a private duel by code.
final class HomeBloc extends SignalBloc<HomeEvent, HomeState> {
  HomeBloc({
    required this._getDisciplines,
    required this._getRanks,
    required this._getStatistics,
    required this._getActivity,
    required this._getCurrentSeason,
    required this._joinDuel,
  }) : super(const HomeState()) {
    handle<HomeStarted>(_onStarted, transformer: restartable());
    handle<HomeRefreshRequested>(_onStarted, transformer: restartable());
    handle<HomeDisciplineSelected>(_onDisciplineSelected);
    handle<HomeJoinDuelSubmitted>(_onJoinDuelSubmitted, transformer: droppable());
    handle<HomeJoinCodeEdited>(_onJoinCodeEdited);
  }

  final GetDisciplinesUsecase _getDisciplines;
  final GetRanksUsecase _getRanks;
  final GetStatisticsUsecase _getStatistics;
  final GetActivityUsecase _getActivity;
  final GetCurrentSeasonUsecase _getCurrentSeason;
  final JoinDuelUsecase _joinDuel;

  Future<void> _onStarted(HomeEvent event, Emitter<HomeState> emit) async {
    emit(stateValue.copyWith(loadStatus: LoadStatus.loading));
    final (
      Either<Failure, List<DisciplineEntity>> disciplines,
      Either<Failure, RankLadderEntity> ranks,
      Either<Failure, StatisticsEntity> statistics,
      Either<Failure, ActivityEntity> activity,
      Either<Failure, SeasonEntity> season,
    ) = await (
      _getDisciplines(const NoParams()),
      _getRanks(const NoParams()),
      _getStatistics(const NoParams()),
      _getActivity(const NoParams()),
      _getCurrentSeason(const NoParams()),
    ).wait;
    if (emit.isDone) return;
    // The catalogue and statistics are the page; the rest degrades quietly.
    final Failure? required = disciplines.getLeft() ?? statistics.getLeft();
    if (required != null) {
      emit(stateValue.copyWith(loadStatus: LoadStatus.failure, failure: required));
      return;
    }
    final List<DisciplineEntity> list = disciplines.getOrElse(
      (_) => const <DisciplineEntity>[],
    );
    final String? selected =
        list.any((DisciplineEntity d) => d.code == stateValue.selectedCode)
        ? stateValue.selectedCode
        : (list.isEmpty ? null : list.first.code);
    emit(
      stateValue.copyWith(
        loadStatus: LoadStatus.success,
        disciplines: list,
        ranks: ranks.toNullable(),
        statistics: statistics.toNullable(),
        season: season.toNullable(),
        activity: activity.getOrElse((_) => ActivityEntity.none),
        selectedCode: selected,
        resetFailure: true,
      ),
    );
  }

  void _onDisciplineSelected(
    HomeDisciplineSelected event,
    Emitter<HomeState> emit,
  ) {
    emit(stateValue.copyWith(selectedCode: event.code));
  }

  Future<void> _onJoinDuelSubmitted(
    HomeJoinDuelSubmitted event,
    Emitter<HomeState> emit,
  ) async {
    emit(
      stateValue.copyWith(joinStatus: LoadStatus.loading, resetJoinFailure: true),
    );
    final Either<Failure, DuelEntity> result = await _joinDuel(event.params);
    if (emit.isDone) return;
    result.match(
      (Failure failure) => emit(
        stateValue.copyWith(joinStatus: LoadStatus.failure, joinFailure: failure),
      ),
      (DuelEntity duel) => emit(
        stateValue.copyWith(
          joinStatus: LoadStatus.success,
          joinedBattleId: duel.battleId,
        ),
      ),
    );
  }

  void _onJoinCodeEdited(HomeJoinCodeEdited event, Emitter<HomeState> emit) {
    if (stateValue.joinFailure == null) return;
    emit(
      stateValue.copyWith(resetJoinFailure: true, joinStatus: LoadStatus.initial),
    );
  }
}
