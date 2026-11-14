import 'package:equatable/equatable.dart';

final class LeaderboardParamsEntity extends Equatable {
  const LeaderboardParamsEntity({required this.disciplineCode});

  final String disciplineCode;

  @override
  List<Object?> get props => <Object?>[disciplineCode];
}
