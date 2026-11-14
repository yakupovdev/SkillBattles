import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/round_answer_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/review_question_entity.dart';

/// A started round of the review; never opened rounds are not sent.
final class ReviewRoundEntity extends Equatable {
  const ReviewRoundEntity({
    required this.roundId,
    required this.number,
    required this.isOvertime,
    required this.completed,
    required this.question,
    required this.answers,
  });

  final String roundId;
  final int number;
  final bool isOvertime;

  /// `false` for a round interrupted by a forfeit.
  final bool completed;
  final ReviewQuestionEntity question;
  final List<RoundAnswerEntity> answers;

  RoundAnswerEntity? answerOf(String userId) {
    for (final RoundAnswerEntity answer in answers) {
      if (answer.userId == userId) return answer;
    }
    return null;
  }

  @override
  List<Object?> get props => <Object?>[
    roundId,
    number,
    isOvertime,
    completed,
    question,
    answers,
  ];
}
