import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_theme.dart';
import 'package:skill_battles/core/presentation/widgets/app_logo.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

String _markAsset(WidgetTester tester) {
  final SvgPicture picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
  return (picture.bytesLoader as SvgAssetLoader).assetName;
}

void main() {
  group('AppLogo', () {
    testWidgets('on light shows the blue 28 px mark and the wordmark', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_app(const AppLogo()));

      expect(_markAsset(tester), AppIcons.logoMark);
      expect(tester.getSize(find.byType(AppSvgIcon)), const Size.square(28));
      expect(find.text('SkillBattles'), findsOneWidget);
      expect(find.text('SB'), findsNothing);
    });

    testWidgets('on primary shows the inverse 32 px mark', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(const AppLogo(variant: AppLogoVariant.onPrimary)),
      );

      expect(_markAsset(tester), AppIcons.logoMarkInverse);
      expect(tester.getSize(find.byType(AppSvgIcon)), const Size.square(32));
    });

    testWidgets('is announced once as SkillBattles', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(const AppLogo()));

      expect(find.bySemanticsLabel('SkillBattles'), findsOneWidget);
      handle.dispose();
    });
  });
}
