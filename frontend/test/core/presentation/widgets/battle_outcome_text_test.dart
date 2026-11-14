import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_theme.dart';
import 'package:skill_battles/core/domain/entity/battle_outcome.dart';
import 'package:skill_battles/core/presentation/widgets/battle_outcome_text.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

Color? _colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  group('BattleOutcomeText', () {
    testWidgets('shows WIN in the success color', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(const BattleOutcomeText(outcome: BattleOutcome.win)),
      );

      expect(_colorOf(tester, 'WIN'), AppColors.success);
    });

    testWidgets('shows LOSS in the danger color', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(const BattleOutcomeText(outcome: BattleOutcome.loss)),
      );

      expect(_colorOf(tester, 'LOSS'), AppColors.danger);
    });

    testWidgets('shows DRAW in the muted color', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(const BattleOutcomeText(outcome: BattleOutcome.draw)),
      );

      expect(_colorOf(tester, 'DRAW'), AppColors.muted);
    });
  });

  group('RatingDeltaText.format', () {
    test('positive delta gets a plus sign', () {
      expect(RatingDeltaText.format(16), '+16');
    });

    test('negative delta uses the true minus sign U+2212', () {
      final String text = RatingDeltaText.format(-14);

      expect(text, '−14');
      expect(text.startsWith('-'), isFalse);
    });

    test('null and zero show an em dash', () {
      expect(RatingDeltaText.format(null), '—');
      expect(RatingDeltaText.format(0), '—');
    });
  });

  group('RatingDeltaText', () {
    testWidgets('colors the delta by sign', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          const Column(
            children: <Widget>[
              RatingDeltaText(delta: 16),
              RatingDeltaText(delta: -14),
              RatingDeltaText(delta: null),
            ],
          ),
        ),
      );

      expect(_colorOf(tester, '+16'), AppColors.success);
      expect(_colorOf(tester, '−14'), AppColors.danger);
      expect(_colorOf(tester, '—'), AppColors.faint);
    });
  });
}
