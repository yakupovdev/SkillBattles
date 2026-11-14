import 'package:equatable/equatable.dart';

/// The server accepted the answer; correctness is never in the receipt.
final class AnswerReceiptEntity extends Equatable {
  const AnswerReceiptEntity({
    required this.roundId,
    required this.submissionId,
    required this.acceptedAt,
  });

  final String roundId;
  final String submissionId;
  final DateTime acceptedAt;

  @override
  List<Object?> get props => <Object?>[roundId, submissionId, acceptedAt];
}
