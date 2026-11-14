// Temporary: renders screens to PNG for a visual check against Paper.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/router/app_routes.dart';
import 'package:skill_battles/dev/mock_backend.dart';

import '../helpers/app_test_harness.dart';

const String outDir = String.fromEnvironment('OUT');

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
  final RenderView view = tester.binding.renderViews.first;
  final OffsetLayer layer = view.debugLayer! as OffsetLayer;
  await tester.runAsync(() async {
    final ui.Image image = await layer.toImage(Offset.zero & view.size);
    final ByteData? data = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    await File('$outDir/$name.png').writeAsBytes(data!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async => _loadFonts());

  testWidgets('auth', (WidgetTester tester) async {
    final AppDependencies deps = await pumpApp(tester);
    await settle(tester, 6);
    await _shot(tester, 'auth_age');
    await tester.tap(find.text('Log in').last);
    await settle(tester, 4);
    await _shot(tester, 'auth_login');
    await finishApp(tester, deps);
  });

  testWidgets('auth day + restricted', (WidgetTester tester) async {
    final AppDependencies deps = await pumpApp(tester);
    await settle(tester, 6);
    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await settle(tester, 2);
    await tester.tap(find.text('January').last);
    await settle(tester, 2);
    await tester.tap(find.byType(DropdownButtonFormField<int>).last);
    await settle(tester, 2);
    await tester.tap(find.text('2020').last);
    await settle(tester, 2);
    await tester.tap(find.text('Continue'));
    await settle(tester, 2);
    await _shot(tester, 'auth_restricted');
    await finishApp(tester, deps);
  });

  testWidgets('auth needs day', (WidgetTester tester) async {
    final AppDependencies deps = await pumpApp(tester);
    await settle(tester, 6);
    final DateTime now = DateTime.now();
    const List<String> months = <String>['January','February','March','April','May','June','July','August','September','October','November','December'];
    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await settle(tester, 2);
    await tester.dragUntilVisible(
      find.text(months[now.month - 1]),
      find.byType(Scrollable).last,
      const Offset(0, -100),
    );
    await tester.tap(find.text(months[now.month - 1]).last);
    await settle(tester, 2);
    await tester.tap(find.byType(DropdownButtonFormField<int>).last);
    await settle(tester, 2);
    await tester.dragUntilVisible(
      find.text('${now.year - 13}'),
      find.byType(Scrollable).last,
      const Offset(0, -200),
    );
    await tester.tap(find.text('${now.year - 13}').last);
    await settle(tester, 2);
    await tester.tap(find.text('Continue'));
    await settle(tester, 2);
    await _shot(tester, 'auth_day');
    await finishApp(tester, deps);
  });

  testWidgets('forgot', (WidgetTester tester) async {
    final AppDependencies deps = await pumpApp(
      tester,
      location: AppRoutes.forgotPassword.path,
    );
    await settle(tester, 6);
    await _shot(tester, 'forgot');
    await finishApp(tester, deps);
  });

  testWidgets('reset', (WidgetTester tester) async {
    final AppDependencies deps = await pumpApp(
      tester,
      location: AppRoutes.resetPassword.path,
    );
    await settle(tester, 6);
    await _shot(tester, 'reset');
    await finishApp(tester, deps);
  });

  testWidgets('home', (WidgetTester tester) async {
    final AppDependencies deps = await pumpApp(tester, signedIn: true);
    await settle(tester, 10);
    await _shot(tester, 'home');
    await finishApp(tester, deps);
  });

  testWidgets('home limit', (WidgetTester tester) async {
    final AppDependencies deps = await pumpApp(tester, signedIn: true);
    await tester.runAsync(() async {
      deps.getDep<MockBackend>().setDailyLimitReached(true);
    });
    deps.getDep<GoRouter>().goNamed(AppRoutes.profile.name);
    await settle(tester, 6);
    deps.getDep<GoRouter>().goNamed(AppRoutes.home.name);
    await settle(tester, 8);
    await tester.tap(find.text('Find ranked match'));
    await settle(tester, 4);
    await _shot(tester, 'home_limit');
    await finishApp(tester, deps);
  });

  testWidgets('account pro', (WidgetTester tester) async {
    final AppDependencies deps = await pumpApp(
      tester,
      signedIn: true,
      isPro: true,
      location: AppRoutes.editProfile.path,
    );
    await settle(tester, 10);
    await _shot(tester, 'account');
    await finishApp(tester, deps);
  });
}
