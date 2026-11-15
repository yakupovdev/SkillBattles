import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_theme.dart';
import 'package:skill_battles/core/domain/entity/question_option_entity.dart';
import 'package:skill_battles/features/battle/presentation/widgets/battle_option_card.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('BattleOptionCard', () {
    testWidgets('renders a LaTeX option as a formula and reads it as text', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      int taps = 0;
      await tester.pumpWidget(
        _app(
          BattleOptionCard(
            option: const QuestionOptionEntity(
              id: 'a',
              text: r'$\frac{1}{2}$ of **it**',
            ),
            letter: 'A',
            state: BattleOptionState.idle,
            onPressed: () => taps++,
          ),
        ),
      );

      expect(find.byType(Math), findsOneWidget);
      expect(find.textContaining(r'$'), findsNothing);
      expect(
        find.bySemanticsLabel(RegExp(r'Answer A: \\frac\{1\}\{2\} of it')),
        findsOneWidget,
      );

      await tester.tap(find.byType(Math));
      expect(taps, 1);
      semantics.dispose();
    });

    testWidgets('a long formula next to a note does not overflow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 420,
            child: BattleOptionCard(
              option: const QuestionOptionEntity(
                id: 'a',
                text:
                    r'$\sum_{k=1}^{n} k^2 = \frac{n(n+1)(2n+1)}{6} = '
                    r'a + b + c + d + e + f + g + h + i + j + k + l + m$',
              ),
              letter: 'A',
              state: BattleOptionState.selected,
              onPressed: null,
              trailingLabel: 'Your answer',
            ),
          ),
        ),
      );

      expect(find.byType(Math), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
