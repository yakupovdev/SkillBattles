import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/answer_access_entity.dart';
import 'package:skill_battles/core/domain/entity/round_answer_entity.dart';

/// Reveal of a closed round. [correctOptionId] is `null` for Free; there is
/// never an explanation in a live reveal.
final class RoundRevealEntity extends Equatable {
  const RoundRevealEntity({
    required this.correctOptionId,
    required this.answers,
    required this.answerAccess,
  });

  final String? correctOptionId;
  final List<RoundAnswerEntity> answers;
  final AnswerAccessEntity answerAccess;

  RoundAnswerEntity? answerOf(String userId) {
    for (final RoundAnswerEntity answer in answers) {
      if (answer.userId == userId) return answer;
    }
    return null;
  }

  @override
  List<Object?> get props => <Object?>[correctOptionId, answers, answerAccess];
}
