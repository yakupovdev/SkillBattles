import 'package:material_ui/material_ui.dart';

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
/// taps.
final class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.icon,
    this.trailingIcon,
    this.expand = false,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;

  /// Optional leading icon, drawn in the label color.
  final Widget? icon;

  /// Optional icon after the label ("Continue →", "Manage in Stripe ↗").
  final Widget? trailingIcon;

  /// Whether the button takes the full available width.
  final bool expand;

  /// Whether a request of this button is in flight.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final bool canTap = onPressed != null && !isLoading;
    final bool enabled = onPressed != null || isLoading;
    final Color background = switch (variant) {
      AppButtonVariant.primary => AppColors.primary,
      AppButtonVariant.dark => AppColors.ink,
      AppButtonVariant.outline => Colors.transparent,
      AppButtonVariant.accent => AppColors.accent,
      AppButtonVariant.danger => AppColors.danger,
    };
    final Color foreground = switch (variant) {
      AppButtonVariant.outline => enabled ? AppColors.ink : AppColors.faint,
      AppButtonVariant.accent => AppColors.ink,
      _ => AppColors.white,
    };
    // A disabled outline is the 1 px light border in every size.
    final BorderSide side = variant == AppButtonVariant.outline
        ? BorderSide(
            color: enabled ? AppColors.ink : AppColors.border,
            width: enabled ? size.outlineWidth : 1,
          )
        : BorderSide.none;
    final TextStyle labelStyle = switch (size) {
      AppButtonSize.large || AppButtonSize.medium => AppTextStyles.buttonLg,
      AppButtonSize.field ||
      AppButtonSize.small ||
      AppButtonSize.dense => AppTextStyles.buttonMd,
      AppButtonSize.compact => AppTextStyles.buttonMd.copyWith(
        fontWeight: enabled ? FontWeight.w600 : FontWeight.w500,
      ),
    };
    final BorderRadius radius = BorderRadius.circular(size.radius);
    final Widget? leading = icon;
    final Widget? trailing = trailingIcon;

    return Semantics(
      button: true,
      enabled: canTap,
      child: Opacity(
        opacity: enabled || variant == AppButtonVariant.outline ? 1 : 0.4,
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(borderRadius: radius, side: side),
          child: InkWell(
            onTap: canTap ? onPressed : null,
            borderRadius: radius,
            hoverColor: foreground.withValues(alpha: 0.06),
            highlightColor: foreground.withValues(alpha: 0.1),
            // Keyboard focus: a clearly visible wash in the label color (the
            // theme default, 12% black, disappears on the ink variant).
            focusColor: foreground.withValues(alpha: 0.24),
            child: SizedBox(
              height: size.height,
              width: expand ? double.infinity : null,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.horizontalPadding,
                ),
                child: Row(
                  mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: <Widget>[
                    if (isLoading)
                      SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: foreground,
                        ),
                      )
                    else if (leading != null)
                      IconTheme.merge(
                        data: IconThemeData(color: foreground, size: 16),
                        child: leading,
                      ),
                    Flexible(
                      child: Text(
                        label,
                        style: labelStyle.copyWith(color: foreground),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (trailing != null) ExcludeSemantics(child: trailing),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
