import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
import 'package:skill_battles/features/leaderboard/domain/entity/leaderboard_entity.dart';
import 'package:skill_battles/features/leaderboard/domain/entity/leaderboard_params_entity.dart';
import 'package:skill_battles/features/leaderboard/domain/usecases/get_leaderboard_usecase.dart';

part 'leaderboard_event.dart';
part 'leaderboard_state.dart';

/// Season leaderboard per discipline; the latest selected tab wins. The own
/// peaks and past seasons of the side panel load once, next to the
/// catalogue. The rank ladder enriches climb progress; optional data failures
/// leave the corresponding details out without blocking the leaderboard.
final class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  LeaderboardBloc({
    required this._getDisciplines,
    required this._getRanks,
    required this._getLeaderboard,
    required this._getStatistics,
    required this._getSeasonHistory,
  }) : super(const LeaderboardState()) {
    on<LeaderboardStarted>(_onStarted, transformer: droppable());
    on<LeaderboardDisciplineSelected>(_onSelected, transformer: restartable());
  }

  final GetDisciplinesUsecase _getDisciplines;
  final GetRanksUsecase _getRanks;
  final GetLeaderboardUsecase _getLeaderboard;
  final GetStatisticsUsecase _getStatistics;
  final GetSeasonHistoryUsecase _getSeasonHistory;

  Future<void> _onStarted(
    LeaderboardStarted event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(state.copyWith(boardStatus: LoadStatus.loading));
    final (
      Either<Failure, List<DisciplineEntity>> result,
      Either<Failure, RankLadderEntity> ranks,
      Either<Failure, StatisticsEntity> statistics,
      Either<Failure, SeasonHistoryPageEntity> seasons,
    ) = await (
      _getDisciplines(const NoParams()),
      _getRanks(const NoParams()),
      _getStatistics(const NoParams()),
      _getSeasonHistory(const SeasonHistoryParamsEntity()),
    ).wait;
    if (emit.isDone) return;
    emit(
      state.copyWith(
        ranks: ranks.toNullable(),
        resetRanks: ranks.isLeft(),
        statistics: statistics.toNullable(),
        seasons: seasons.toNullable(),
      ),
    );
    final List<DisciplineEntity>? disciplines = result.toNullable();
    if (disciplines == null || disciplines.isEmpty) {
      emit(
        state.copyWith(
          boardStatus: LoadStatus.failure,
          failure: result.getLeft(),
        ),
      );
      return;
    }
    final String code =
        event.disciplineCode != null &&
            disciplines.any(
              (DisciplineEntity d) => d.code == event.disciplineCode,
            )
        ? event.disciplineCode!
        : disciplines.first.code;
    emit(state.copyWith(disciplines: disciplines, selectedCode: code));
    await _load(code, emit);
  }

  Future<void> _onSelected(
    LeaderboardDisciplineSelected event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedCode: event.code,
        boardStatus: LoadStatus.loading,
        resetBoard: true,
      ),
    );
    await _load(event.code, emit);
  }

  Future<void> _load(String code, Emitter<LeaderboardState> emit) async {
    final Either<Failure, LeaderboardEntity> result = await _getLeaderboard(
      LeaderboardParamsEntity(disciplineCode: code),
    );
    if (emit.isDone || state.selectedCode != code) return;
    result.match(
      (Failure failure) => emit(
        state.copyWith(boardStatus: LoadStatus.failure, failure: failure),
      ),
      (LeaderboardEntity board) => emit(
        state.copyWith(
          boardStatus: LoadStatus.success,
          board: board,
          resetFailure: true,
        ),
      ),
    );
  }
}
