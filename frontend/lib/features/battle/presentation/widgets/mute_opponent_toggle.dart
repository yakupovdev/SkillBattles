import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';

/// 40 px icon button in the picker header that hides or shows the
/// opponent's stickers for this battle (Paper states H and I).
final class MuteOpponentToggle extends StatelessComponent {
  const MuteOpponentToggle({
    required this.isHidden,
    required this.opponentNickname,
    required this.onTap,
    super.key,
  });

  final bool isHidden;
  final String opponentNickname;
  final VoidCallback onTap;

  @override
  Component build(BuildContext context) {
    final String message = isHidden ? "Show $opponentNickname's stickers" : "Hide $opponentNickname's stickers";
    // The tooltip of the Flutter app is the native `title` hint.
    return Component.wrapElement(
      attributes: <String, String>{'title': message},
      child: AppTappable(
        onTap: onTap,
        radius: 10,
        semanticLabel: message,
        isSelected: isHidden,
        classes: isHidden ? 'mute-opponent-toggle mute-opponent-toggle--hidden' : 'mute-opponent-toggle',
        child: AppSvgIcon(
          isHidden ? AppIcons.eyeOff : AppIcons.eye,
          width: 18,
          height: 18,
          color: isHidden ? AppColors.accentText : AppColors.muted,
        ),
      ),
    );
  }
}

@css
List<StyleRule> get muteOpponentToggleStyles => <StyleRule>[
  css('.mute-opponent-toggle').styles(
    display: Display.flex,
    width: const Unit.pixels(40),
    height: const Unit.pixels(40),
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
    flex: const Flex(shrink: 0),
    backgroundColor: Colors.transparent,
  ),
  css('.mute-opponent-toggle:hover').styles(backgroundColor: AppColors.surface),
  css('.mute-opponent-toggle--hidden, .mute-opponent-toggle--hidden:hover').styles(
    backgroundColor: AppColors.accentTint,
  ),
];
