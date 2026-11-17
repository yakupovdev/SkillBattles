import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';

/// 14 px faint crossed-out eye before the opponent's nickname while their
/// stickers are hidden. Not tappable.
final class StickersHiddenIndicator extends StatelessComponent {
  const StickersHiddenIndicator({super.key});

  @override
  Component build(BuildContext context) {
    return const span(
      classes: 'stickers-hidden-indicator',
      attributes: <String, String>{'role': 'img', 'aria-label': 'Opponent stickers are hidden'},
      <Component>[AppSvgIcon(AppIcons.eyeOff, width: 14, height: 14, color: AppColors.faint)],
    );
  }
}

@css
List<StyleRule> get stickersHiddenIndicatorStyles => <StyleRule>[
  css('.stickers-hidden-indicator').styles(display: Display.inlineFlex, flex: const Flex(shrink: 0)),
];
