import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';

/// 14 px faint crossed-out eye before the opponent's nickname while their
/// stickers are hidden. Not tappable.
final class StickersHiddenIndicator extends StatelessWidget {
  const StickersHiddenIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Opponent stickers are hidden',
      child: const AppSvgIcon(
        AppIcons.eyeOff,
        width: 14,
        height: 14,
        color: AppColors.faint,
      ),
    );
  }
}
