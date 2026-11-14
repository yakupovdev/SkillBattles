import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_theme.dart';
import 'package:skill_battles/core/presentation/widgets/app_segmented_control.dart';

void main() {
  for (final AppSegmentedControlSize size in AppSegmentedControlSize.values) {
    group('AppSegmentedControl (${size.name})', () {
      testWidgets('shows every segment label', (WidgetTester tester) async {
        await tester.pumpWidget(_app(size: size, onSelected: (_) {}));

        expect(find.text('All'), findsOneWidget);
        expect(find.text('Ranked'), findsOneWidget);
        expect(find.text('Private'), findsOneWidget);
      });

      testWidgets('tapping a segment reports its value', (
        WidgetTester tester,
      ) async {
        final List<String> selected = <String>[];
        await tester.pumpWidget(_app(size: size, onSelected: selected.add));

        await tester.tap(find.text('Private'));
        await tester.tap(find.text('Ranked'));

        expect(selected, <String>['private', 'ranked']);
      });
    });
  }
}

Widget _app({
  required AppSegmentedControlSize size,
  required ValueChanged<String> onSelected,
  String selected = 'all',
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          child: AppSegmentedControl<String>(
            size: size,
            selected: selected,
            onSelected: onSelected,
            segments: const <AppSegment<String>>[
              AppSegment<String>(value: 'all', label: 'All'),
              AppSegment<String>(value: 'ranked', label: 'Ranked'),
              AppSegment<String>(value: 'private', label: 'Private'),
            ],
          ),
        ),
      ),
    ),
  );
}
