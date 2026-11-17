import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_shadows.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/overlay/app_overlay.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';

/// The modal shell of "19 Report question": white, radius 20, dialog shadow,
/// 32 px padding, an eyebrow and a title with a close button. Open it with
/// `showAppDialog`.
///
/// A `null` [onClose] hides the × but keeps its slot, and blocks dismissal by
/// Esc and the scrim (a request is in flight).
final class FriendsDialogShell extends StatelessComponent {
  const FriendsDialogShell({
    required this.eyebrow,
    required this.title,
    required this.onClose,
    required this.children,
    this.width = 480,
    super.key,
  });

  final String eyebrow;
  final String title;
  final VoidCallback? onClose;
  final List<Component> children;
  final double width;

  @override
  Component build(BuildContext context) {
    final VoidCallback? close = onClose;
    return DialogDismissGuard(
      canDismiss: close != null,
      child: div(
        classes: 'friends-dialog',
        styles: Styles(width: Unit.pixels(width)),
        <Component>[
          div(classes: 'friends-dialog__header', <Component>[
            div(classes: 'friends-dialog__heading', <Component>[
              AppEyebrow(eyebrow),
              h2(classes: 'friends-dialog__title', <Component>[Component.text(title)]),
            ]),
            if (close == null)
              const span(classes: 'friends-dialog__close-slot', <Component>[])
            else
              AppTappable(
                onTap: close,
                radius: 24,
                semanticLabel: 'Close',
                classes: 'friends-dialog__close',
                child: const AppSvgIcon(AppIcons.close, width: 20, height: 20),
              ),
          ]),
          ...children,
        ],
      ),
    );
  }
}

@css
List<StyleRule> get friendsDialogShellStyles => <StyleRule>[
  css('.friends-dialog').styles(
    display: Display.flex,
    maxWidth: const Unit.percent(100),
    padding: const Padding.all(Unit.pixels(32)),
    boxSizing: BoxSizing.borderBox,
    radius: const BorderRadius.circular(Unit.pixels(20)),
    shadow: AppShadows.dialog,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(22)),
    backgroundColor: AppColors.white,
  ),
  css('.friends-dialog__header').styles(
    display: Display.flex,
    alignItems: AlignItems.start,
  ),
  css('.friends-dialog__heading').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(8)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.friends-dialog__title')
      .combine(AppTextStyles.titleXlCompact)
      .combine(const Styles(letterSpacing: Unit.em(-0.02), lineHeight: Unit.pixels(32))),
  css('.friends-dialog__close, .friends-dialog__close-slot').styles(
    display: Display.flex,
    width: const Unit.pixels(48),
    height: const Unit.pixels(48),
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
    flex: const Flex(shrink: 0),
  ),
  // The body text and the action row of the friends dialogs.
  css('.friends-dialog-text')
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(color: AppColors.muted, lineHeight: Unit.pixels(20))),
  css('.friends-dialog-actions').styles(
    display: Display.flex,
    justifyContent: JustifyContent.end,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(10)),
  ),
  css('.friends-dialog-actions__cancel').styles(
    display: Display.flex,
    height: const Unit.pixels(48),
    padding: const Padding.symmetric(horizontal: Unit.pixels(18)),
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
  ),
];
