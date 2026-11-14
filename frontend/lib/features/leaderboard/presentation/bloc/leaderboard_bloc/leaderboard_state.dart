part of 'leaderboard_bloc.dart';

final class LeaderboardState extends Equatable {
  const LeaderboardState({
    this.disciplines = const <DisciplineEntity>[],
    this.selectedCode,
    this.boardStatus = LoadStatus.initial,
    this.board,
    this.failure,
  });

  final List<DisciplineEntity> disciplines;
  final String? selectedCode;
  final LoadStatus boardStatus;
  final LeaderboardEntity? board;
  final Failure? failure;

  LeaderboardState copyWith({
    List<DisciplineEntity>? disciplines,
    String? selectedCode,
    LoadStatus? boardStatus,
    LeaderboardEntity? board,
    Failure? failure,
    bool resetBoard = false,
    bool resetFailure = false,
  }) {
    return LeaderboardState(
      disciplines: disciplines ?? this.disciplines,
      selectedCode: selectedCode ?? this.selectedCode,
      boardStatus: boardStatus ?? this.boardStatus,
      board: resetBoard ? null : board ?? this.board,
      failure: resetFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    disciplines,
    selectedCode,
    boardStatus,
    board,
    failure,
  ];
}
