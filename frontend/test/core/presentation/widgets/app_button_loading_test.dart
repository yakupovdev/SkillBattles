import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_theme.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('AppButton.isLoading', () {
    testWidgets('shows a spinner before the label and ignores taps', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        _app(
          AppButton(label: 'Accept', isLoading: true, onPressed: () => taps++),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      final InkWell ink = tester.widget<InkWell>(find.byType(InkWell));
      expect(ink.onTap, isNull);
      await tester.tap(find.text('Accept'));
      expect(taps, 0);
    });

    testWidgets('keeps full opacity even without a callback', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const AppButton(label: 'Accept', isLoading: true, onPressed: null),
        ),
      );

      final Opacity opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(AppButton),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 1);
    });

    testWidgets('shows no spinner and is tappable when not loading', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        _app(AppButton(label: 'Accept', onPressed: () => taps++)),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.tap(find.text('Accept'));
      expect(taps, 1);
    });
  });
}
