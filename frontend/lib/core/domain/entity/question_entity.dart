import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/difficulty.dart';
import 'package:skill_battles/core/domain/entity/question_option_entity.dart';

/// A question without its answer.
final class QuestionEntity extends Equatable {
  const QuestionEntity({
    required this.id,
    required this.topicCode,
    required this.topicName,
    required this.difficulty,
    required this.prompt,
    required this.options,
  });

  final String id;
  final String topicCode;
  final String topicName;
  final Difficulty difficulty;
  final String prompt;
  final List<QuestionOptionEntity> options;

  @override
  List<Object?> get props => <Object?>[
    id,
    topicCode,
    topicName,
    difficulty,
    prompt,
    options,
  ];
}
