import 'package:skill_battles/core/domain/entity/answer_access_entity.dart';
import 'package:skill_battles/core/domain/entity/battle_mode.dart';
import 'package:skill_battles/core/domain/entity/battle_outcome.dart';
import 'package:skill_battles/core/domain/entity/battle_reason.dart';
import 'package:skill_battles/core/domain/entity/battle_result_entity.dart';
import 'package:skill_battles/core/domain/entity/battle_status.dart';
import 'package:skill_battles/core/domain/entity/difficulty.dart';
import 'package:skill_battles/core/domain/entity/question_entity.dart';
import 'package:skill_battles/core/domain/entity/question_option_entity.dart';
import 'package:skill_battles/core/domain/entity/result_player_entity.dart';
import 'package:skill_battles/core/domain/entity/round_answer_entity.dart';
import 'package:skill_battles/core/presentation/skeleton/skeletonizer.dart';
import 'package:skill_battles/features/battle_result/domain/entity/battle_review_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/review_question_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/review_round_entity.dart';

/// Mock entities rendered as bones while the result and review load.
final class BattleResultSkeletonData {
  BattleResultSkeletonData._();

  static const String _me = 'skeleton-me';
  static const String _them = 'skeleton-them';

  static ResultPlayerEntity _player(String id) => ResultPlayerEntity(
    id: id,
    nickname: BoneMock.name,
    isPro: false,
    score: 4200,
    correctCount: 4,
    ratingBefore: 1000,
    ratingAfter: 1032,
    ratingDelta: 32,
    kFactor: 32,
    rankBefore: 'SILVER_I',
    rankAfter: 'SILVER_I',
    calibrationMatchesRemaining: 0,
  );

  static final BattleResultEntity result = BattleResultEntity(
    battleId: 'skeleton',
    disciplineCode: 'SKELETON',
    mode: BattleMode.ranked,
    seasonId: null,
    status: BattleStatus.finished,
    reason: BattleReason.normal,
    winnerUserId: _me,
    myOutcome: BattleOutcome.win,
    finishedAt: DateTime.utc(2026),
    overtimePlayed: false,
    players: <ResultPlayerEntity>[_player(_me), _player(_them)],
    myUserId: _me,
  );

  static RoundAnswerEntity _answer(String id) => RoundAnswerEntity(
    userId: id,
    selectedOptionId: null,
    correct: true,
    elapsed: const Duration(seconds: 20),
    basePoints: 800,
    speedBonus: 100,
    streakBonus: 0,
    tieBreakPoints: 0,
    points: 900,
    timedOut: false,
  );

  static final BattleReviewEntity review = BattleReviewEntity(
    battleId: 'skeleton',
    disciplineCode: 'SKELETON',
    mode: BattleMode.ranked,
    mistakesOnly: false,
    answerAccess: const AnswerAccessEntity(
      canViewCorrectAnswer: true,
      canViewExplanation: true,
      entitlementVersion: 0,
    ),
    rounds: <ReviewRoundEntity>[
      for (int i = 1; i <= 5; i++)
        ReviewRoundEntity(
          roundId: 'skeleton-$i',
          number: i,
          isOvertime: false,
          completed: true,
          question: ReviewQuestionEntity(
            question: QuestionEntity(
              id: 'skeleton-$i',
              topicCode: 'SKELETON',
              topicName: BoneMock.words(1),
              difficulty: Difficulty.easy,
              prompt: BoneMock.words(8),
              options: <QuestionOptionEntity>[
                for (int o = 0; o < 4; o++)
                  QuestionOptionEntity(
                    id: 'skeleton-$i-$o',
                    text: BoneMock.words(1),
                  ),
              ],
            ),
            correctOptionId: null,
            explanation: null,
          ),
          answers: <RoundAnswerEntity>[_answer(_me), _answer(_them)],
        ),
    ],
    myUserId: _me,
  );
}
