part of 'leaderboard_bloc.dart';

final class LeaderboardState extends Equatable {
  const LeaderboardState({
    this.disciplines = const <DisciplineEntity>[],
    this.selectedCode,
    this.boardStatus = LoadStatus.initial,
    this.board,
    this.failure,
    this.statistics,
    this.seasons,
  });

  final List<DisciplineEntity> disciplines;
  final String? selectedCode;
  final LoadStatus boardStatus;
  final LeaderboardEntity? board;
  final Failure? failure;

  /// Own peaks; `null` when they could not be loaded.
  final StatisticsEntity? statistics;

  /// Own completed seasons; `null` when they could not be loaded.
  final SeasonHistoryPageEntity? seasons;

  LeaderboardState copyWith({
    List<DisciplineEntity>? disciplines,
    String? selectedCode,
    LoadStatus? boardStatus,
    LeaderboardEntity? board,
    Failure? failure,
    StatisticsEntity? statistics,
    SeasonHistoryPageEntity? seasons,
    bool resetBoard = false,
    bool resetFailure = false,
  }) {
    return LeaderboardState(
      disciplines: disciplines ?? this.disciplines,
      selectedCode: selectedCode ?? this.selectedCode,
      boardStatus: boardStatus ?? this.boardStatus,
      board: resetBoard ? null : board ?? this.board,
      failure: resetFailure ? null : failure ?? this.failure,
      statistics: statistics ?? this.statistics,
      seasons: seasons ?? this.seasons,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    disciplines,
    selectedCode,
    boardStatus,
    board,
    failure,
    statistics,
    seasons,
  ];
}
