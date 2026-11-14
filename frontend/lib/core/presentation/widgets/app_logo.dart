import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';

/// Where the [AppLogo] is placed.
enum AppLogoVariant {
  /// Blue mark, ink wordmark — the top bar.
  onLight,

  /// Inverse mark on a white tile, white wordmark — the blue auth panel.
  onPrimary,
}

/// The SkillBattles mark (two chevrons facing each other) with the wordmark.
final class AppLogo extends StatelessWidget {
  const AppLogo({this.variant = AppLogoVariant.onLight, super.key});

  final AppLogoVariant variant;

  @override
  Widget build(BuildContext context) {
    final bool onPrimary = variant == AppLogoVariant.onPrimary;
    final double markSize = onPrimary ? 32 : 28;
    final TextStyle wordmarkStyle = onPrimary
        ? AppTextStyles.titleMd.copyWith(
            color: AppColors.white,
            letterSpacing: -0.01 * 20,
          )
        : AppTextStyles.titleSm;

    return Semantics(
      label: 'SkillBattles',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: <Widget>[
          AppSvgIcon(
            onPrimary ? AppIcons.logoMarkInverse : AppIcons.logoMark,
            width: markSize,
            height: markSize,
          ),
          Text('SkillBattles', style: wordmarkStyle),
        ],
      ),
    );
  }
}
