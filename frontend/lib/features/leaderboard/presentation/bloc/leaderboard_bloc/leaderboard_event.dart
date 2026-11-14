part of 'leaderboard_bloc.dart';

sealed class LeaderboardEvent extends Equatable {
  const LeaderboardEvent();

  @override
  List<Object?> get props => <Object?>[];
}

final class LeaderboardStarted extends LeaderboardEvent {
  const LeaderboardStarted({this.disciplineCode});

  final String? disciplineCode;

  @override
  List<Object?> get props => <Object?>[disciplineCode];
}

final class LeaderboardDisciplineSelected extends LeaderboardEvent {
  const LeaderboardDisciplineSelected(this.code);

  final String code;

  @override
  List<Object?> get props => <Object?>[code];
}
