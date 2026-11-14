import 'package:flutter_test/flutter_test.dart';

import 'package:skill_battles/core/data/models/battle_format_model.dart';
import 'package:skill_battles/core/data/models/discipline_request_model.dart';
import 'package:skill_battles/features/account/data/models/limits_response_model.dart';
import 'package:skill_battles/features/matchmaking/data/models/queue_entry_model.dart';

void main() {
  test('LimitsResponseModel parses the contract example', () {
    final LimitsResponseModel model = LimitsResponseModel.fromJson(
      <String, dynamic>{
        'planCode': 'PRO_MONTHLY',
        'timezone': 'America/New_York',
        'date': '2026-11-14',
        'freeRankedLimit': 5,
        'rankedStartedToday': 2,
        'freeRankedRemaining': null,
        'resetsAt': '2026-11-15T05:00:00Z',
        'canStartRanked': true,
        'entitlements': <String, dynamic>{
          'isPro': true,
          'version': 1,
          'unlimitedRanked': true,
          'historyMatchLimit': null,
          'canViewCorrectAnswers': true,
          'canViewExplanations': true,
          'canViewAdvancedAnalytics': true,
          'canFilterMistakes': true,
          'canPracticeSimilar': true,
        },
      },
    );
    expect(model.freeRankedRemaining, isNull);
    expect(model.entitlements.isPro, isTrue);
  });

  test('a missing required key is rejected', () {
    expect(
      () => QueueEntryModel.fromJson(<String, dynamic>{'id': 'x'}),
      throwsA(isA<Exception>()),
    );
  });

  test('request enums serialise as API constants', () {
    expect(
      const DisciplineRequestModel(
        disciplineCode: 'SAT_MATH',
        format: BattleFormatModel.standard,
      ).toJson(),
      <String, dynamic>{'disciplineCode': 'SAT_MATH', 'format': 'STANDARD'},
    );
  });
}
