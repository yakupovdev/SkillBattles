import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';
import 'package:skill_battles/features/battle/presentation/controllers/sticker_compositions.dart';
import 'package:skill_battles/features/battle/presentation/widgets/battle_sticker_slots.dart';
import 'package:skill_battles/features/battle/presentation/widgets/mute_opponent_toggle.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_cell.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_compositions_scope.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_picker.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_trigger_button.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_view.dart';

/// Parsed once from the real asset files.
final Map<String, LottieComposition> _parsed = <String, LottieComposition>{};
final Map<String, int> _sizes = <String, int>{};

Future<LottieComposition> _fromCache(String path) async => _parsed[path]!;

/// Pumps [child] under a compositions scope. The scope loads first; the
/// child is added in a second frame, like a bubble that appears after the
/// app warmed the cache.
Future<void> _pumpLoaded(
  WidgetTester tester,
  Widget child, {
  StickerCompositionLoader loader = _fromCache,
}) async {
  await tester.pumpWidget(_LoadedTestApp(loader: loader));
  await tester.pump();
  await tester.pumpWidget(_LoadedTestApp(loader: loader, content: child));
  await tester.pump();
}

final class _LoadedTestApp extends StatelessWidget {
  const _LoadedTestApp({required this.loader, this.content});

  final StickerCompositionLoader loader;
  final Widget? content;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: StickerCompositionsScope(
      loader: loader,
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            const StickerCompositionsPreload(),
            Center(child: content),
          ],
        ),
      ),
    ),
  );
}

double _progress(WidgetTester tester) =>
    tester.widget<Lottie>(find.byType(Lottie)).controller!.value;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final StickerId id in StickerId.supported) {
      final String path = StickerCompositions.assetOf(id);
      final ByteData data = await rootBundle.load(path);
      _sizes[path] = data.lengthInBytes;
      _parsed[path] = await LottieComposition.fromByteData(data);
    }
  });

  group('StickerLayout', () {
    test('nothing shows below the 1280 px canvas, where the page scrolls '
        'sideways under a window-sized overlay', () {
      for (final double width in <double>[1100, 1200, 1279]) {
        expect(StickerLayout.fits(width, 120), isFalse, reason: '$width');
        expect(StickerLayout.fits(width, 200), isFalse, reason: '$width');
      }
    });

    test('a bubble fits from 1280 px, the picker from 1344 px, and neither '
        'reaches the 880 px column', () {
      expect(StickerLayout.fits(1280, 120), isTrue);
      expect(StickerLayout.fits(1280, 200), isFalse);
      expect(StickerLayout.fits(1343, 200), isFalse);
      expect(StickerLayout.fits(1344, 200), isTrue);
      for (final double width in <double>[1280, 1344, 1440, 1920]) {
        final double columnLeft = (width - StickerLayout.columnWidth) / 2;
        expect(
          StickerLayout.gutterOf(width),
          columnLeft,
          reason: 'the gutter ends where the column starts at $width',
        );
      }
    });
  });

  group('assets', () {
    for (final StickerId id in StickerId.supported) {
      test('${id.wireId} is a self-contained Lottie of at most 20 KB', () {
        final String path = StickerCompositions.assetOf(id);
        final LottieComposition composition = _parsed[path]!;

        expect(path, 'assets/stickers/${id.wireId}.json');
        expect(_sizes[path], lessThanOrEqualTo(20 * 1024));
        expect(composition.images, isEmpty);
        expect(composition.fonts, isEmpty);
        expect(composition.characters, isEmpty);
        expect(composition.duration, greaterThan(Duration.zero));
        expect(
          composition.duration,
          lessThanOrEqualTo(const Duration(seconds: 3)),
        );
      });
    }
  });

  group('StickerView', () {
    testWidgets('plays once from the start and holds the last frame', (
      WidgetTester tester,
    ) async {
      await _pumpLoaded(
        tester,
        const StickerView(stickerId: StickerId.lol, size: 96),
      );
      expect(_progress(tester), lessThan(0.1));

      await tester.pump(const Duration(seconds: 3));

      expect(_progress(tester), 1);
      expect(
        (tester.widget<Lottie>(find.byType(Lottie)).controller!
                as AnimationController)
            .isAnimating,
        isFalse,
      );
    });

    testWidgets('a new key (the same sticker sent again) restarts it', (
      WidgetTester tester,
    ) async {
      await _pumpLoaded(
        tester,
        const StickerView(
          key: ValueKey<String>('s1'),
          stickerId: StickerId.gg,
          size: 96,
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(_progress(tester), 1);

      await _pumpLoaded(
        tester,
        const StickerView(
          key: ValueKey<String>('s2'),
          stickerId: StickerId.gg,
          size: 96,
        ),
      );

      expect(_progress(tester), lessThan(0.1));
    });

    testWidgets('reduced motion shows the static last frame', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await _pumpLoaded(
        tester,
        const StickerView(stickerId: StickerId.crying, size: 96),
      );

      expect(_progress(tester), 1);
    });

    testWidgets('an asset that fails to load shows the sticker name', (
      WidgetTester tester,
    ) async {
      await _pumpLoaded(
        tester,
        const StickerView(stickerId: StickerId.waitWhat, size: 96),
        loader: (String path) async => path.endsWith('wait_what.json')
            ? throw const FormatException('broken')
            : _parsed[path]!,
      );

      expect(find.byType(Lottie), findsNothing);
      expect(find.text('Wait, what?'), findsOneWidget);
    });

    testWidgets('a composition that arrives after the view was shown does not '
        'replay', (WidgetTester tester) async {
      final Completer<void> gate = Completer<void>();
      await _pumpLoaded(
        tester,
        const StickerView(stickerId: StickerId.fire, size: 96),
        loader: (String path) async {
          await gate.future;
          return _parsed[path]!;
        },
      );
      expect(find.text('On fire'), findsOneWidget);

      gate.complete();
      await tester.pump();
      await tester.pump();

      expect(find.byType(Lottie), findsNothing);
      expect(find.text('On fire'), findsOneWidget);
    });
  });

  group('StickerTriggerButton', () {
    testWidgets('under reduced motion the cooldown still counts down the '
        'seconds instead of jumping to 0', (WidgetTester tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await _pumpLoaded(
        tester,
        StickerTriggerButton(
          isOpen: false,
          cooldownUntil: DateTime.now().add(const Duration(milliseconds: 3600)),
          cooldown: const Duration(seconds: 4),
          onTap: () {},
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('4'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });
  });

  group('StickerPicker', () {
    testWidgets('shows the nine stickers in the designed order with their '
        'labels', (WidgetTester tester) async {
      await _pumpLoaded(tester, _TestPicker());

      final List<StickerId> order = tester
          .widgetList<StickerCell>(find.byType(StickerCell))
          .map((StickerCell cell) => cell.stickerId)
          .toList();
      expect(order, <StickerId>[
        StickerId.gg,
        StickerId.fire,
        StickerId.ez,
        StickerId.lol,
        StickerId.tooSlow,
        StickerId.facepalm,
        StickerId.hmm,
        StickerId.waitWhat,
        StickerId.crying,
      ]);
      expect(find.bySemanticsLabel('LOL, taunt'), findsOneWidget);
      expect(find.bySemanticsLabel('Crying, emotion'), findsOneWidget);
      expect(find.text('Tap a sticker to send'), findsOneWidget);
    });

    testWidgets('a tap selects the sticker', (WidgetTester tester) async {
      final List<StickerId> selected = <StickerId>[];
      await _pumpLoaded(tester, _TestPicker(onSelected: selected.add));

      await tester.tap(find.byKey(const ValueKey<StickerId>(StickerId.ez)));
      await tester.pump();

      expect(selected, <StickerId>[StickerId.ez]);
    });

    testWidgets('Esc closes it', (WidgetTester tester) async {
      int closed = 0;
      await _pumpLoaded(tester, _TestPicker(onClose: () => closed++));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(closed, 1);
    });

    testWidgets('with the web shortcuts, arrows move inside the grid and '
        'Enter sends', (WidgetTester tester) async {
      final List<StickerId> selected = <StickerId>[];
      // The browser maps Enter to ButtonActivateIntent and the arrows to
      // scrolling (WidgetsApp.defaultShortcuts on the web).
      await _pumpLoaded(
        tester,
        Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.enter): ButtonActivateIntent(),
            SingleActivator(LogicalKeyboardKey.arrowDown): ScrollIntent(
              direction: AxisDirection.down,
            ),
            SingleActivator(LogicalKeyboardKey.arrowRight): ScrollIntent(
              direction: AxisDirection.right,
            ),
          },
          child: _TestPicker(onSelected: selected.add),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(selected, <StickerId>[StickerId.tooSlow]);
    });

    testWidgets('Tab and Shift Tab cycle between the grid and mute without '
        'reaching the background, and Escape still closes', (
      WidgetTester tester,
    ) async {
      int closed = 0;
      await _pumpLoaded(
        tester,
        _BackgroundAction(child: _TestPicker(onClose: () => closed++)),
      );
      final Finder first = find.byKey(const ValueKey<StickerId>(StickerId.gg));
      final Finder last = find.byKey(
        const ValueKey<StickerId>(StickerId.crying),
      );
      final Finder mute = find.byType(MuteOpponentToggle);
      expect(_focusOf(tester, first).hasPrimaryFocus, isTrue);

      await _tab(tester, reverse: true);
      expect(_focusOf(tester, mute).hasPrimaryFocus, isTrue);
      await _tab(tester);
      expect(_focusOf(tester, first).hasPrimaryFocus, isTrue);

      _focusOf(tester, last).requestFocus();
      await tester.pump();
      await _tab(tester);
      expect(_focusOf(tester, mute).hasPrimaryFocus, isTrue);
      await _tab(tester, reverse: true);
      expect(_focusOf(tester, last).hasPrimaryFocus, isTrue);
      expect(
        _focusOf(tester, find.byKey(_backgroundKey)).hasPrimaryFocus,
        isFalse,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(closed, 1);
    });

    testWidgets('arrow keys stop at grid boundaries instead of reaching mute '
        'or the background', (WidgetTester tester) async {
      await _pumpLoaded(tester, const _BackgroundAction(child: _TestPicker()));
      final Finder first = find.byKey(const ValueKey<StickerId>(StickerId.gg));
      final Finder last = find.byKey(
        const ValueKey<StickerId>(StickerId.crying),
      );
      for (final LogicalKeyboardKey key in <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowLeft,
      ]) {
        await tester.sendKeyEvent(key);
        await tester.pump();
        expect(_focusOf(tester, first).hasPrimaryFocus, isTrue);
      }
      _focusOf(tester, last).requestFocus();
      await tester.pump();
      for (final LogicalKeyboardKey key in <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowRight,
      ]) {
        await tester.sendKeyEvent(key);
        await tester.pump();
        expect(_focusOf(tester, last).hasPrimaryFocus, isTrue);
      }
    });

    testWidgets('during cooldown both Tab directions stay on mute and Escape '
        'closes after traversal', (WidgetTester tester) async {
      int closed = 0;
      await _pumpLoaded(
        tester,
        _BackgroundAction(
          child: _TestPicker(
            cooldownUntil: DateTime.now().add(const Duration(seconds: 4)),
            onClose: () => closed++,
          ),
        ),
      );
      final Finder mute = find.byType(MuteOpponentToggle);
      await _tab(tester);
      expect(_focusOf(tester, mute).hasPrimaryFocus, isTrue);
      await _tab(tester);
      expect(_focusOf(tester, mute).hasPrimaryFocus, isTrue);
      await _tab(tester, reverse: true);
      expect(_focusOf(tester, mute).hasPrimaryFocus, isTrue);
      expect(
        _focusOf(tester, find.byKey(_backgroundKey)).hasPrimaryFocus,
        isFalse,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(closed, 1);
    });

    testWidgets('an active picker keeps mute accessible when cooldown starts '
        'and restores cell traversal when it ends', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<DateTime?> cooldown = ValueNotifier<DateTime?>(null);
      addTearDown(cooldown.dispose);
      final List<StickerId> selected = <StickerId>[];
      int closed = 0;
      await _pumpLoaded(
        tester,
        _BackgroundAction(
          child: ValueListenableBuilder<DateTime?>(
            valueListenable: cooldown,
            builder:
                (BuildContext context, DateTime? deadline, Widget? child) =>
                    _TestPicker(
                      cooldownUntil: deadline,
                      onSelected: selected.add,
                      onClose: () => closed++,
                    ),
          ),
        ),
      );
      final Finder first = find.byKey(const ValueKey<StickerId>(StickerId.gg));
      final Finder mute = find.byType(MuteOpponentToggle);
      expect(_focusOf(tester, first).hasPrimaryFocus, isTrue);

      cooldown.value = DateTime.now().add(const Duration(seconds: 4));
      await tester.pump();
      expect(_focusOf(tester, first).hasPrimaryFocus, isFalse);
      await _tab(tester);
      expect(_focusOf(tester, mute).hasPrimaryFocus, isTrue);
      await _tab(tester, reverse: true);
      expect(_focusOf(tester, mute).hasPrimaryFocus, isTrue);

      cooldown.value = null;
      await tester.pump();
      await _tab(tester);
      expect(_focusOf(tester, first).hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected, <StickerId>[StickerId.gg]);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(closed, 1);
    });

    testWidgets('during the cooldown the cells do nothing', (
      WidgetTester tester,
    ) async {
      final List<StickerId> selected = <StickerId>[];
      await _pumpLoaded(
        tester,
        _TestPicker(
          cooldownUntil: DateTime.now().add(const Duration(seconds: 4)),
          onSelected: selected.add,
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<StickerId>(StickerId.gg)),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(selected, isEmpty);
      expect(find.textContaining('Next sticker in'), findsOneWidget);
    });
  });
}

const Key _backgroundKey = ValueKey<String>('background-answer');

FocusNode _focusOf(WidgetTester tester, Finder target) => Focus.of(
  tester.element(
    find.descendant(of: target, matching: find.byType(GestureDetector)).first,
  ),
);

Future<void> _tab(WidgetTester tester, {bool reverse = false}) async {
  if (reverse) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  if (reverse) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pump();
}

final class _BackgroundAction extends StatelessWidget {
  const _BackgroundAction({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      TextButton(
        key: _backgroundKey,
        onPressed: () {},
        child: const Text('Background answer'),
      ),
      child,
    ],
  );
}

final class _TestPicker extends StatelessWidget {
  const _TestPicker({this.cooldownUntil, this.onSelected, this.onClose});

  final DateTime? cooldownUntil;
  final ValueChanged<StickerId>? onSelected;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => StickerPicker(
    opponentNickname: 'timur.b',
    isOpponentHidden: false,
    cooldownUntil: cooldownUntil,
    caretCenter: 32,
    onSelected: onSelected ?? (_) {},
    onToggleOpponentHidden: () {},
    onClose: onClose ?? () {},
  );
}
