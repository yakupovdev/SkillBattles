import 'package:equatable/equatable.dart';

/// One final answer. Keep [submissionId] for retries of the same answer.
final class SubmitAnswerParamsEntity extends Equatable {
  const SubmitAnswerParamsEntity({
    required this.battleId,
    required this.roundId,
    required this.optionId,
    required this.submissionId,
  });

  final String battleId;
  final String roundId;
  final String optionId;
  final String submissionId;

  @override
  List<Object?> get props => <Object?>[
    battleId,
    roundId,
    optionId,
    submissionId,
  ];
}
