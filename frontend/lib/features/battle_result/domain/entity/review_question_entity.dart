import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/question_entity.dart';

/// A reviewed question. [correctOptionId] and [explanation] are `null` for
/// Free readers — the server never sends them.
final class ReviewQuestionEntity extends Equatable {
  const ReviewQuestionEntity({
    required this.question,
    required this.correctOptionId,
    required this.explanation,
  });

  final QuestionEntity question;
  final String? correctOptionId;
  final String? explanation;

  @override
  List<Object?> get props => <Object?>[question, correctOptionId, explanation];
}
