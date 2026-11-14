import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_theme.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('AppButton', () {
    testWidgets('shows its label and calls onPressed on tap', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        _app(AppButton(label: 'Play again', onPressed: () => taps++)),
      );

      expect(find.text('Play again'), findsOneWidget);
      await tester.tap(find.text('Play again'));

      expect(taps, 1);
    });

    testWidgets('does nothing on tap when onPressed is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(const AppButton(label: 'Previous', onPressed: null)),
      );

      final InkWell ink = tester.widget<InkWell>(find.byType(InkWell));
      expect(ink.onTap, isNull);
      await tester.tap(find.text('Previous'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders the optional leading icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          AppButton(
            label: 'Copy code',
            icon: const Icon(Icons.copy, key: Key('lead')),
            onPressed: () {},
          ),
        ),
      );

      expect(find.byKey(const Key('lead')), findsOneWidget);
    });

    testWidgets('expand makes the button take the full available width', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(AppButton(label: 'Go', expand: true, onPressed: () {})),
      );

      final Size size = tester.getSize(find.byType(AppButton));
      expect(size.width, tester.getSize(find.byType(Scaffold)).width);
    });
  });
}
