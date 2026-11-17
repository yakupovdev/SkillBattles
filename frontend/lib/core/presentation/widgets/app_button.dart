import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';

/// Look of an [AppButton].
enum AppButtonVariant {
  /// Filled with the brand blue ("I'm ready", "Play again").
  primary,

  /// Filled with ink ("Create account & play", "Copy code", "Join").
  dark,

  /// Transparent with an ink outline ("Cancel search", "Back to home").
  outline,

  /// Filled with amber, ink label ("Choose annual", "See plans").
  accent,

  /// Filled with red, white label ("Remove friend").
  danger,
}

/// Height, corner radius, padding and label style of an [AppButton].
enum AppButtonSize {
  /// 52 high, radius 12, 15 semibold.
  large(52, 12, 28, 1.5),

  /// 48 high, radius 12, 15 semibold.
  medium(48, 12, 22, 1.5),

  /// 48 high, radius 10, 14 semibold — next to a 48 px input ("Save").
  field(48, 10, 20, 1.5),

  /// 44 high, radius 10, 14 semibold.
  small(44, 10, 18, 1.5),

  /// 40 high, radius 10, 14 semibold ("Unlock history").
  dense(40, 10, 16, 1.5),

  /// 36 high, radius 8, 14 — pagination.
  compact(36, 8, 14, 1.5);

  const AppButtonSize(
    this.height,
    this.radius,
    this.horizontalPadding,
    this.outlineWidth,
  );

  final double height;
  final double radius;
  final double horizontalPadding;
  final double outlineWidth;
}

/// The filled and outlined buttons of the Paper design.
///
/// A `null` [onPressed] renders the disabled look (faint label; outlined
/// buttons get the light border). While [isLoading] the button keeps its
/// enabled look at full opacity, shows a spinner before the label and ignores
/// clicks.
final class AppButton extends StatelessComponent {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.icon,
    this.trailingIcon,
    this.expand = false,
    this.isLoading = false,
    this.type = ButtonType.button,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;

  /// Optional leading icon (an `AppSvgIcon` in the label color).
  final Component? icon;

  /// Optional icon after the label ("Continue →", "Manage in Stripe ↗").
  final Component? trailingIcon;

  /// Whether the button takes the full available width.
  final bool expand;

  /// Whether a request of this button is in flight.
  final bool isLoading;

  /// `submit` inside a `form` lets Enter in a field press it.
  final ButtonType type;

  /// The label color of [variant], for icons passed in [icon].
  static Color foregroundOf(AppButtonVariant variant, {bool enabled = true}) =>
      switch (variant) {
        AppButtonVariant.outline => enabled ? AppColors.ink : AppColors.faint,
        AppButtonVariant.accent => AppColors.ink,
        _ => AppColors.white,
      };

  @override
  Component build(BuildContext context) {
    final VoidCallback? press = onPressed;
    final bool canTap = press != null && !isLoading;
    final bool enabled = press != null || isLoading;
    final Color background = switch (variant) {
      AppButtonVariant.primary => AppColors.primary,
      AppButtonVariant.dark => AppColors.ink,
      AppButtonVariant.outline => Colors.transparent,
      AppButtonVariant.accent => AppColors.accent,
      AppButtonVariant.danger => AppColors.danger,
    };
    final Color foreground = foregroundOf(variant, enabled: enabled);
    // A disabled outline is the 1 px light border in every size.
    final Border? border = variant == AppButtonVariant.outline
        ? Border.all(
            color: enabled ? AppColors.ink : AppColors.border,
            width: Unit.pixels(enabled ? size.outlineWidth : 1),
          )
        : null;
    final Styles labelStyle = switch (size) {
      AppButtonSize.large || AppButtonSize.medium => AppTextStyles.buttonLg,
      AppButtonSize.field ||
      AppButtonSize.small ||
      AppButtonSize.dense => AppTextStyles.buttonMd,
      AppButtonSize.compact => AppTextStyles.buttonMd.combine(
        Styles(fontWeight: enabled ? FontWeight.w600 : FontWeight.w500),
      ),
    };
    final Component? leading = icon;
    final Component? trailing = trailingIcon;

    return button(
      type: type,
      disabled: !canTap,
      classes: 'app-button',
      styles: Styles.combine(<Styles>[
        labelStyle,
        Styles(
          display: expand ? Display.flex : Display.inlineFlex,
          width: expand ? const Unit.percent(100) : null,
          height: Unit.pixels(size.height),
          padding: Padding.symmetric(
            horizontal: Unit.pixels(size.horizontalPadding),
          ),
          border: border,
          radius: BorderRadius.circular(Unit.pixels(size.radius)),
          opacity: enabled || variant == AppButtonVariant.outline ? 1 : 0.4,
          cursor: canTap ? Cursor.pointer : Cursor.defaultCursor,
          color: foreground,
          backgroundColor: background,
          raw: <String, String>{'--fg': foreground.value},
        ),
      ]),
      attributes: <String, String>{if (isLoading) 'aria-busy': 'true'},
      onClick: canTap ? press : null,
      <Component>[
        if (isLoading)
          const span(classes: 'app-button__spinner', <Component>[])
        else if (leading != null)
          span(classes: 'app-button__icon', <Component>[leading]),
        span(classes: 'app-button__label', <Component>[Component.text(label)]),
        if (trailing != null)
          span(
            classes: 'app-button__icon',
            attributes: const <String, String>{'aria-hidden': 'true'},
            <Component>[trailing],
          ),
      ],
    );
  }
}

@css
List<StyleRule> get appButtonStyles => <StyleRule>[
  css.keyframes('app-spin', <String, Styles>{
    'to': const Styles(transform: Transform.rotate(Angle.deg(360))),
  }),
  css('.app-button', <StyleRule>[
    css('&').styles(
      position: const Position.relative(),
      overflow: Overflow.hidden,
      boxSizing: BoxSizing.borderBox,
      justifyContent: JustifyContent.center,
      alignItems: AlignItems.center,
      gap: const Gap.column(Unit.pixels(10)),
      whiteSpace: WhiteSpace.noWrap,
      raw: const <String, String>{'flex-shrink': '0'},
    ),
    // Hover / pressed / keyboard focus washes in the label color.
    css('&::after').styles(
      content: '',
      position: const Position.absolute(
        top: Unit.zero,
        left: Unit.zero,
        right: Unit.zero,
        bottom: Unit.zero,
      ),
      opacity: 0,
      pointerEvents: PointerEvents.none,
      backgroundColor: const Color.variable('--fg'),
    ),
    css('&:not(:disabled):hover::after').styles(opacity: 0.06),
    css('&:not(:disabled):active::after').styles(opacity: 0.1),
    css('&:focus-visible').styles(
      raw: const <String, String>{'outline': 'none'},
    ),
    css('&:focus-visible::after').styles(opacity: 0.24),
  ]),
  css('.app-button__label').styles(
    overflow: Overflow.hidden,
    textOverflow: TextOverflow.ellipsis,
    raw: const <String, String>{'min-width': '0'},
  ),
  css('.app-button__icon').styles(
    display: Display.inlineFlex,
    alignItems: AlignItems.center,
  ),
  css('.app-button__spinner').styles(
    display: Display.inlineBlock,
    width: const Unit.pixels(16),
    height: const Unit.pixels(16),
    boxSizing: BoxSizing.borderBox,
    border: Border.all(
      color: const Color.variable('--fg'),
      width: const Unit.pixels(2),
    ),
    radius: const BorderRadius.circular(Unit.percent(50)),
    raw: const <String, String>{
      'border-right-color': 'transparent',
      'animation': 'app-spin 0.8s linear infinite',
      'flex-shrink': '0',
    },
  ),
];
