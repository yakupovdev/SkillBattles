import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_theme.dart';
import 'package:skill_battles/core/domain/entity/answer_access_entity.dart';
import 'package:skill_battles/core/domain/entity/battle_mode.dart';
import 'package:skill_battles/core/domain/entity/difficulty.dart';
import 'package:skill_battles/core/domain/entity/question_entity.dart';
import 'package:skill_battles/core/domain/entity/question_option_entity.dart';
import 'package:skill_battles/core/domain/entity/round_answer_entity.dart';
import 'package:skill_battles/core/presentation/widgets/question_illustration.dart';
import 'package:skill_battles/features/battle_result/domain/entity/battle_review_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/review_question_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/review_round_entity.dart';
import 'package:skill_battles/features/battle_result/presentation/widgets/report_round_dialog.dart';
import 'package:skill_battles/features/battle_result/presentation/widgets/round_review_list.dart';

import '../../../../helpers/fake_image_http_client.dart';

const String _imageUrl =
    '/media/questions/SAT_MATH/3f5a3602/'
    '224eefc655e44ddac7e07d499e9fad2ba90e28bd8db675e8cd15b31156b7a203.png';

const String _me = 'me';
const String _them = 'them';

RoundAnswerEntity _answer(
  String userId,
  String optionId, {
  required bool correct,
}) => RoundAnswerEntity(
  userId: userId,
  selectedOptionId: optionId,
  correct: correct,
  elapsed: const Duration(seconds: 3),
  basePoints: correct ? 800 : 0,
  speedBonus: 0,
  streakBonus: 0,
  tieBreakPoints: 0,
  points: correct ? 800 : 0,
  timedOut: false,
);

BattleReviewEntity _review({String? imageUrl}) => BattleReviewEntity(
  battleId: 'battle',
  disciplineCode: 'MATH',
  mode: BattleMode.ranked,
  mistakesOnly: false,
  answerAccess: const AnswerAccessEntity(
    canViewCorrectAnswer: true,
    canViewExplanation: true,
    entitlementVersion: 1,
  ),
  rounds: <ReviewRoundEntity>[
    ReviewRoundEntity(
      roundId: 'round-1',
      number: 1,
      isOvertime: false,
      completed: true,
      question: ReviewQuestionEntity(
        question: QuestionEntity(
          id: 'q1',
          topicCode: 'ALGEBRA',
          topicName: 'Algebra',
          difficulty: Difficulty.medium,
          prompt: r'Find $\sqrt{16}$ in **x**',
          imageUrl: imageUrl,
          options: const <QuestionOptionEntity>[
            QuestionOptionEntity(id: 'a', text: r'$2$'),
            QuestionOptionEntity(id: 'b', text: r'$\pm 2$'),
            QuestionOptionEntity(id: 'c', text: 'No roots'),
            QuestionOptionEntity(id: 'd', text: r'$4$'),
          ],
        ),
        correctOptionId: 'b',
        explanation: r'Both $2^2$ and $(-2)^2$ give $4$.',
      ),
      answers: <RoundAnswerEntity>[
        _answer(_me, 'a', correct: false),
        _answer(_them, 'b', correct: true),
      ],
    ),
  ],
  myUserId: _me,
);

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('RoundReviewList', () {
    testWidgets('renders formulas in the row, the answer tags and the '
        'explanation', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          RoundReviewList(
            review: _review(),
            disciplineName: 'Math',
            opponentNickname: 'timur_b',
            opponentId: _them,
            mistakesOnly: false,
            canFilterMistakes: false,
            reportedRoundIds: const <String>{},
          ),
        ),
      );

      // The first round opens expanded: the question, "Correct: B", "You: A"
      // and the three formulas of the explanation.
      expect(find.byType(Math), findsNWidgets(6));
      expect(find.textContaining(r'$', findRichText: true), findsNothing);
      expect(tester.takeException(), isNull);

      // Collapsed: only the question in one cut line.
      await tester.tap(find.byType(Math).first);
      await tester.pump();
      expect(find.byType(Math), findsOneWidget);
    });
  });

  group('RoundReviewList illustration', () {
    Widget list(BattleReviewEntity review) => _app(
      RoundReviewList(
        review: review,
        disciplineName: 'Math',
        opponentNickname: 'timur_b',
        opponentId: _them,
        mistakesOnly: false,
        canFilterMistakes: false,
        reportedRoundIds: const <String>{},
      ),
    );

    testWidgets('the expanded row shows the illustration above the prompt; '
        'the collapsed row hides it', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final FakeImageHttpClient client = FakeImageHttpClient()..install();

      await tester.pumpWidget(list(_review(imageUrl: _imageUrl)));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();

      final Finder illustration = find.byType(QuestionIllustration);
      expect(illustration, findsOneWidget);
      expect(
        tester.getBottomLeft(illustration).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.byType(Math).first).dy),
      );
      expect(client.requests, hasLength(1));
      expect(tester.takeException(), isNull);

      // Collapse the row by tapping its prompt.
      await tester.tap(find.byType(Math).first);
      await tester.pump();
      expect(illustration, findsNothing);
    });

    testWidgets('a tap on the illustration opens it full size and keeps '
        'the row expanded', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      FakeImageHttpClient().install();

      await tester.pumpWidget(list(_review(imageUrl: _imageUrl)));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();

      await tester.tap(
        find.descendant(
          of: find.byType(QuestionIllustration),
          matching: find.byType(RawImage),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);

      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(QuestionIllustration), findsOneWidget);
    });

    testWidgets('a question without an illustration shows no image', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final FakeImageHttpClient client = FakeImageHttpClient()..install();

      await tester.pumpWidget(list(_review()));

      expect(find.byType(QuestionIllustration), findsNothing);
      expect(client.requests, isEmpty);
    });
  });

  group('ReportRoundDialog', () {
    testWidgets('quotes the question without Markdown and TeX delimiters', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const ReportRoundDialog(
            battleId: 'battle',
            roundId: 'round-1',
            eyebrow: 'Round 01',
            prompt: r'Solve $x^2 = 4$ for **x**',
          ),
        ),
      );

      expect(
        find.textContaining('"Solve x^2 = 4 for x" — our content team'),
        findsOneWidget,
      );
    });
  });
}
