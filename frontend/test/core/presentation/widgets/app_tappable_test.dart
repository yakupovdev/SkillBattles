import 'dart:ui' show Tristate;

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';

const Key _childKey = Key('child');

Future<void> _pump(
  WidgetTester tester, {
  VoidCallback? onTap,
  Color? focusColor,
  bool? isSelected,
  String? semanticLabel,
  String? semanticValue,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppTappable(
                onTap: onTap,
                focusColor: focusColor ?? AppColors.primary,
                isSelected: isSelected,
                semanticLabel: semanticLabel,
                semanticValue: semanticValue,
                child: const SizedBox(
                  key: _childKey,
                  width: 120,
                  height: 40,
                  child: Text('Card'),
                ),
              ),
              TextButton(onPressed: () {}, child: const Text('Other')),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The ring is a 2 px stroke centered 4 px outside the 120 × 40 child
/// (3 px gap + half the stroke), concentric with the child's corners, so it
/// never coincides with the child's own border.
final RRect _ringRRect = RRect.fromLTRBR(
  -4,
  -4,
  124,
  44,
  const Radius.circular(4),
);

Finder get _tappable => find.byType(AppTappable);

/// Whether the node offers a tap action (read from the action bit mask).
bool _hasTapAction(SemanticsNode node) =>
    node.getSemanticsData().actions & SemanticsAction.tap.index != 0;

void main() {
  group('AppTappable activation', () {
    testWidgets('a tap calls onTap', (WidgetTester tester) async {
      int taps = 0;
      await _pump(tester, onTap: () => taps++);

      await tester.tap(find.byKey(_childKey));

      expect(taps, 1);
    });

    testWidgets('Tab focuses it, Enter and Space activate it', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await _pump(tester, onTap: () => taps++);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(taps, 2);
    });

    testWidgets('without onTap a tap and the keyboard do nothing', (
      WidgetTester tester,
    ) async {
      await _pump(tester);

      await tester.tap(find.byKey(_childKey));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('without onTap it cannot take focus', (
      WidgetTester tester,
    ) async {
      await _pump(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final BuildContext? focused = FocusManager.instance.primaryFocus?.context;
      // The first Tab skips the disabled tappable and reaches the button.
      expect(focused, isNotNull);
      expect(focused!.findAncestorWidgetOfExactType<AppTappable>(), isNull);
      expect(focused.findAncestorWidgetOfExactType<TextButton>(), isNotNull);
    });
  });

  group('AppTappable focus ring', () {
    testWidgets('is drawn outside the child only while focused', (
      WidgetTester tester,
    ) async {
      await _pump(tester, onTap: () {}, focusColor: AppColors.danger);
      expect(_tappable, isNot(paints..rrect(color: AppColors.danger)));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        _tappable,
        paints..rrect(
          rrect: _ringRRect,
          color: AppColors.danger,
          strokeWidth: 2,
          style: PaintingStyle.stroke,
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_tappable, isNot(paints..rrect(color: AppColors.danger)));
    });

    testWidgets('uses the primary color by default', (
      WidgetTester tester,
    ) async {
      await _pump(tester, onTap: () {});

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(
        _tappable,
        paints..rrect(color: AppColors.primary, strokeWidth: 2),
      );
    });
  });

  group('AppTappable semantics', () {
    testWidgets('is an enabled button with a tap action', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, onTap: () {});

      final SemanticsNode node = tester.getSemantics(find.text('Card'));

      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isEnabled, Tristate.isTrue);
      expect(_hasTapAction(node), isTrue);
      handle.dispose();
    });

    testWidgets('semantic tap activates onTap', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      int taps = 0;
      await _pump(tester, onTap: () => taps++);

      tester.semantics.tap(find.semantics.byLabel('Card'));
      await tester.pump();

      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('a disabled one is a button without a tap action', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester);

      final SemanticsNode node = tester.getSemantics(find.text('Card'));

      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      expect(_hasTapAction(node), isFalse);
      handle.dispose();
    });

    testWidgets('isSelected is reported as selected', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester, onTap: () {}, isSelected: true);

      expect(
        tester.getSemantics(find.text('Card')).flagsCollection.isSelected,
        Tristate.isTrue,
      );
      handle.dispose();
    });

    testWidgets('semanticLabel replaces the child semantics, with value', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(
        tester,
        onTap: () {},
        semanticLabel: 'Answer B',
        semanticValue: 'Your answer',
      );

      final SemanticsNode node = tester.getSemantics(find.byType(AppTappable));

      expect(node.label, 'Answer B');
      expect(node.value, 'Your answer');
      expect(node.label, isNot(contains('Card')));
      handle.dispose();
    });
  });
}
