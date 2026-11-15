import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_theme.dart';
import 'package:skill_battles/core/domain/entity/battle_mode.dart';
import 'package:skill_battles/core/domain/entity/difficulty.dart';
import 'package:skill_battles/core/domain/entity/entitlements_entity.dart';
import 'package:skill_battles/core/domain/entity/question_entity.dart';
import 'package:skill_battles/core/domain/entity/question_option_entity.dart';
import 'package:skill_battles/core/presentation/widgets/question_illustration.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_phase.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_player_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_round_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_snapshot_entity.dart';
import 'package:skill_battles/features/battle/presentation/bloc/battle_bloc/battle_bloc.dart';
import 'package:skill_battles/features/battle/presentation/widgets/battle_round_view.dart';

import '../../../../helpers/fake_image_http_client.dart';

const String _imageUrl =
    '/media/questions/SAT_MATH/3f5a3602/'
    '224eefc655e44ddac7e07d499e9fad2ba90e28bd8db675e8cd15b31156b7a203.png';

Widget _roundApp(BattleSnapshotEntity snapshot) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: SingleChildScrollView(
      child: BattleRoundView(
        snapshot: snapshot,
        round: snapshot.round!,
        state: const BattleState(),
      ),
    ),
  ),
);

BattlePlayerEntity _player(String id) => BattlePlayerEntity(
  id: id,
  nickname: id,
  isPro: false,
  rating: 1000,
  rankCode: 'SILVER_I',
  ready: true,
  connected: true,
  reconnectDeadline: null,
  score: 0,
  correctCount: 0,
  streak: 0,
  answeredCurrentRound: false,
);

BattleSnapshotEntity _questionSnapshot({String? imageUrl}) {
  final DateTime now = DateTime.now().toUtc();
  return BattleSnapshotEntity(
    id: 'b1',
    disciplineCode: 'SAT_MATH',
    mode: BattleMode.ranked,
    seasonId: 'FALL_2026',
    phase: BattlePhase.question,
    version: 1,
    serverTime: now,
    receivedAt: now,
    questionCount: 5,
    overtimePlayed: false,
    readyDeadline: null,
    countdownEndsAt: null,
    nextRoundStartsAt: null,
    players: <BattlePlayerEntity>[_player('me'), _player('them')],
    round: BattleRoundEntity(
      id: 'r1',
      number: 1,
      isOvertime: false,
      startedAt: now,
      deadline: now.add(const Duration(seconds: 45)),
      limitSeconds: 45,
      question: QuestionEntity(
        id: 'q1',
        topicCode: 'T',
        topicName: 'Topic',
        difficulty: Difficulty.easy,
        prompt: 'What is 2 + 2?',
        options: const <QuestionOptionEntity>[
          QuestionOptionEntity(id: 'o1', text: '3'),
          QuestionOptionEntity(id: 'o2', text: '4'),
          QuestionOptionEntity(id: 'o3', text: '5'),
          QuestionOptionEntity(id: 'o4', text: '6'),
        ],
        imageUrl: imageUrl,
      ),
      mySelectedOptionId: null,
      reveal: null,
    ),
    result: null,
    entitlements: const EntitlementsEntity(
      isPro: false,
      version: 1,
      unlimitedRanked: false,
      historyMatchLimit: 10,
      canViewCorrectAnswers: false,
      canViewExplanations: false,
      canViewAdvancedAnalytics: false,
      canFilterMistakes: false,
    ),
    myUserId: 'me',
  );
}

void main() {
  group('BattleRoundView', () {
    testWidgets('the question and options of a live round are not '
        'selectable, so they cannot be copied', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final BattleSnapshotEntity snapshot = _questionSnapshot();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: BattleRoundView(
                snapshot: snapshot,
                round: snapshot.round!,
                state: const BattleState(),
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('What is 2 + 2?'), findsOneWidget);
      expect(find.byType(SelectionArea), findsNothing);
      expect(find.byType(SelectableRegion), findsNothing);
      expect(find.byType(SelectableText), findsNothing);

      // Drop the countdown's timer.
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a question without an illustration shows no image and '
        'requests nothing', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final FakeImageHttpClient client = FakeImageHttpClient()..install();

      await tester.pumpWidget(_roundApp(_questionSnapshot()));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );

      expect(find.byType(QuestionIllustration), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(client.requests, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('the illustration is shown above the prompt, and a failed '
        'load keeps the prompt and the options usable', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      FakeImageHttpClient(statuses: <int>[404]).install();

      await tester.pumpWidget(
        _roundApp(_questionSnapshot(imageUrl: _imageUrl)),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();

      final Finder illustration = find.byType(QuestionIllustration);
      final Finder prompt = find.textContaining('What is 2 + 2?');
      expect(illustration, findsOneWidget);
      expect(
        tester.getBottomLeft(illustration).dy,
        lessThanOrEqualTo(tester.getTopLeft(prompt).dy),
      );
      expect(find.text(QuestionIllustration.errorMessage), findsOneWidget);
      expect(prompt, findsOneWidget);
      expect(find.textContaining('4'), findsWidgets);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
