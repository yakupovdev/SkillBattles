import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/question_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/round_reveal_entity.dart';

/// The round currently open or revealed. Its own deadline and difficulty;
/// the grid of future rounds is never sent.
final class BattleRoundEntity extends Equatable {
  const BattleRoundEntity({
    required this.id,
    required this.number,
    required this.isOvertime,
    required this.startedAt,
    required this.deadline,
    required this.limitSeconds,
    required this.question,
    required this.mySelectedOptionId,
    required this.reveal,
  });

  final String id;

  /// 1..5 regular, 6 overtime.
  final int number;
  final bool isOvertime;
  final DateTime startedAt;

  /// An answer that reaches the server at the deadline is already late.
  final DateTime deadline;
  final int limitSeconds;
  final QuestionEntity question;

  /// Own accepted answer.
  final String? mySelectedOptionId;

  /// `null` while the question is open.
  final RoundRevealEntity? reveal;

  @override
  List<Object?> get props => <Object?>[
    id,
    number,
    isOvertime,
    startedAt,
    deadline,
    limitSeconds,
    question,
    mySelectedOptionId,
    reveal,
  ];
}
