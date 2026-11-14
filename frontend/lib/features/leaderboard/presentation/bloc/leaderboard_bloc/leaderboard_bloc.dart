import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/presentation/bloc/load_status.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_disciplines_usecase.dart';
import 'package:skill_battles/features/leaderboard/domain/entity/leaderboard_entity.dart';
import 'package:skill_battles/features/leaderboard/domain/entity/leaderboard_params_entity.dart';
import 'package:skill_battles/features/leaderboard/domain/usecases/get_leaderboard_usecase.dart';

part 'leaderboard_event.dart';
part 'leaderboard_state.dart';

/// Season leaderboard per discipline; the latest selected tab wins.
final class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  LeaderboardBloc({
    required this._getDisciplines,
    required this._getLeaderboard,
  }) : super(const LeaderboardState()) {
    on<LeaderboardStarted>(_onStarted, transformer: droppable());
    on<LeaderboardDisciplineSelected>(_onSelected, transformer: restartable());
  }

  final GetDisciplinesUsecase _getDisciplines;
  final GetLeaderboardUsecase _getLeaderboard;

  Future<void> _onStarted(
    LeaderboardStarted event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(state.copyWith(boardStatus: LoadStatus.loading));
    final Either<Failure, List<DisciplineEntity>> result =
        await _getDisciplines(const NoParams());
    if (emit.isDone) return;
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
