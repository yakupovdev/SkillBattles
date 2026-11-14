import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';

const Key _contentKey = Key('content');

Future<void> _pump(
  WidgetTester tester, {
  required Size window,
  Widget? child,
  bool fullBleed = false,
}) async {
  tester.view.physicalSize = window;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AppDesktopViewport(
          fullBleed: fullBleed,
          child:
              child ??
              const SizedBox(
                key: _contentKey,
                width: double.infinity,
                height: 100,
              ),
        ),
      ),
    ),
  );
}

Finder get _horizontalScroll => find.byWidgetPredicate(
  (Widget w) =>
      w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
);

void main() {
  group('AppDesktopViewport', () {
    testWidgets('below 1280 it scrolls horizontally over a 1280 wide child', (
      WidgetTester tester,
    ) async {
      await _pump(tester, window: const Size(1024, 700));

      expect(_horizontalScroll, findsOneWidget);
      expect(tester.getSize(find.byKey(_contentKey)).width, 1280);
    });

    testWidgets('from 1280 there is no horizontal scroll', (
      WidgetTester tester,
    ) async {
      await _pump(tester, window: const Size(1280, 700));

      expect(_horizontalScroll, findsNothing);
      expect(tester.getSize(find.byKey(_contentKey)).width, 1280);
    });

    testWidgets('at 1920 the child is capped at 1440 and centered', (
      WidgetTester tester,
    ) async {
      await _pump(tester, window: const Size(1920, 1080));

      expect(_horizontalScroll, findsNothing);
      expect(tester.getSize(find.byKey(_contentKey)).width, 1440);
      expect(tester.getTopLeft(find.byKey(_contentKey)).dx, 240);
    });

    testWidgets('fullBleed at 1920 spans the whole window', (
      WidgetTester tester,
    ) async {
      await _pump(tester, window: const Size(1920, 1080), fullBleed: true);

      expect(tester.getSize(find.byKey(_contentKey)).width, 1920);
      expect(tester.getTopLeft(find.byKey(_contentKey)).dx, 0);
    });

    testWidgets('the child gets the window height as its minimum height', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        window: const Size(1440, 700),
        child: const Column(
          children: <Widget>[
            SizedBox(key: _contentKey, width: double.infinity, height: 100),
          ],
        ),
      );

      final Size page = tester.getSize(find.byType(Column));
      expect(page.height, 700);
    });

    testWidgets('a taller child grows and scrolls vertically', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        window: const Size(1440, 700),
        child: const SizedBox(
          key: _contentKey,
          width: double.infinity,
          height: 1500,
        ),
      );

      expect(tester.getSize(find.byKey(_contentKey)).height, 1500);
      final ScrollableState vertical = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      expect(vertical.position.maxScrollExtent, 800);

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pump();
      expect(vertical.position.pixels, 300);
    });

    testWidgets('spaceBetween pins the last item to the bottom', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        window: const Size(1440, 700),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            SizedBox(height: 50),
            SizedBox(key: _contentKey, width: double.infinity, height: 40),
          ],
        ),
      );

      expect(tester.getBottomLeft(find.byKey(_contentKey)).dy, 700);
    });
  });
}
