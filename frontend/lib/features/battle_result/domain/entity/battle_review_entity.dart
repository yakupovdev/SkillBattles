import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/answer_access_entity.dart';
import 'package:skill_battles/core/domain/entity/battle_mode.dart';
import 'package:skill_battles/features/battle_result/domain/entity/review_round_entity.dart';

final class BattleReviewEntity extends Equatable {
  const BattleReviewEntity({
    required this.battleId,
    required this.disciplineCode,
    required this.mode,
    required this.mistakesOnly,
    required this.answerAccess,
    required this.rounds,
    required this.myUserId,
  });

  final String battleId;
  final String disciplineCode;
  final BattleMode mode;
  final bool mistakesOnly;
  final AnswerAccessEntity answerAccess;
  final List<ReviewRoundEntity> rounds;
  final String myUserId;

  @override
  List<Object?> get props => <Object?>[
    battleId,
    disciplineCode,
    mode,
    mistakesOnly,
    answerAccess,
    rounds,
    myUserId,
  ];
}
