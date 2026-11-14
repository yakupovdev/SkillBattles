// Temporary: renders history / leaderboard / ranked search to PNG for a
// visual check against Paper.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';

import '../helpers/app_test_harness.dart';

const String outDir = String.fromEnvironment('OUT');
const String historyPath = String.fromEnvironment(
  'HISTORY',
  defaultValue: '/profile',
);

Future<void> _loadFonts() async {
  final Map<String, List<String>> fonts = <String, List<String>>{
    'Inter': <String>['Regular', 'Medium', 'SemiBold', 'Bold'],
    'SpaceGrotesk': <String>['Regular', 'Medium', 'SemiBold', 'Bold'],
    'JetBrainsMono': <String>['Regular', 'Medium', 'SemiBold'],
  };
  for (final MapEntry<String, List<String>> e in fonts.entries) {
    final FontLoader loader = FontLoader(e.key);
    for (final String w in e.value) {
      loader.addFont(rootBundle.load('assets/fonts/${e.key}-$w.ttf'));
    }
    await loader.load();
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  final RenderRepaintBoundary boundary = tester.renderObject(
    find.byType(RepaintBoundary).first,
  );
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage();
    final ByteData? data = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    await File('$outDir/$name.png').writeAsBytes(data!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async => _loadFonts());

  testWidgets('leaderboard', (WidgetTester tester) async {
    final AppDependencies deps = await pumpApp(
      tester,
      signedIn: true,
      location: '/leaderboard',
    );
    await settle(tester, 10);
    await _shot(tester, 'leaderboard');
    await finishApp(tester, deps);
  });

  testWidgets('history', (WidgetTester tester) async {
    final AppDependencies deps = await pumpApp(
      tester,
      signedIn: true,
      location: historyPath,
    );
    await settle(tester, 10);
    await _shot(tester, 'history');
    await finishApp(tester, deps);
  });

  testWidgets('ranked search', (WidgetTester tester) async {
    final AppDependencies deps = await pumpApp(
      tester,
      signedIn: true,
      location: '/play/search?discipline=SAT_MATH',
    );
    await settle(tester, 4);
    await _shot(tester, 'ranked');
    await finishApp(tester, deps);
  });
}
