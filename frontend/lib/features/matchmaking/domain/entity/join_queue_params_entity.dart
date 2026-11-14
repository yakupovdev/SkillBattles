import 'package:equatable/equatable.dart';

/// Ranked search in one discipline (format is always STANDARD).
final class JoinQueueParamsEntity extends Equatable {
  const JoinQueueParamsEntity({required this.disciplineCode});

  final String disciplineCode;

  @override
  List<Object?> get props => <Object?>[disciplineCode];
}
