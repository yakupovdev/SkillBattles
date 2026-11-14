import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_theme.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

SvgPicture _picture(WidgetTester tester) =>
    tester.widget<SvgPicture>(find.byType(SvgPicture));

void main() {
  group('AppIcons', () {
    for (final String path in AppIcons.all) {
      testWidgets('$path is bundled and parses as SVG', (
        WidgetTester tester,
      ) async {
        final PictureInfo? info = await tester.runAsync(
          () => vg.loadPicture(SvgAssetLoader(path), null),
        );

        expect(info, isNotNull);
        expect(info!.size.isEmpty, isFalse);
        info.picture.dispose();
      });
    }
  });

  group('AppSvgIcon', () {
    testWidgets('is laid out at its width and height before the file loads', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(const AppSvgIcon(AppIcons.arrowLong, width: 20, height: 12)),
      );

      expect(tester.getSize(find.byType(AppSvgIcon)), const Size(20, 12));
    });

    testWidgets('loads the given asset and keeps its colors without a color', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(const AppSvgIcon(AppIcons.flame, width: 12, height: 14)),
      );

      final SvgPicture picture = _picture(tester);
      expect((picture.bytesLoader as SvgAssetLoader).assetName, AppIcons.flame);
      expect(picture.colorFilter, isNull);
    });

    testWidgets('tints the icon with the given color', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const AppSvgIcon(
            AppIcons.copy,
            width: 16,
            height: 16,
            color: AppColors.ink,
          ),
        ),
      );

      expect(
        _picture(tester).colorFilter,
        const ColorFilter.mode(AppColors.ink, BlendMode.srcIn),
      );
    });

    testWidgets('is excluded from semantics', (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(const AppSvgIcon(AppIcons.check, width: 12, height: 12)),
      );

      expect(_picture(tester).excludeFromSemantics, isTrue);
    });
  });
}
