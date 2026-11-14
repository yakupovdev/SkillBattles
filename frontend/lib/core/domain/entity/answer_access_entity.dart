import 'package:equatable/equatable.dart';

/// What the caller may see of answers, decided by the server per reader.
final class AnswerAccessEntity extends Equatable {
  const AnswerAccessEntity({
    required this.canViewCorrectAnswer,
    required this.canViewExplanation,
    required this.entitlementVersion,
  });

  final bool canViewCorrectAnswer;
  final bool canViewExplanation;
  final int entitlementVersion;

  @override
  List<Object?> get props => <Object?>[
    canViewCorrectAnswer,
    canViewExplanation,
    entitlementVersion,
  ];
}
