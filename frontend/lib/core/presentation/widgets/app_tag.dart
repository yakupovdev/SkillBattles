import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_markdown_text.dart';

/// Color pair of an [AppTag].
enum AppTagTone {
  /// Blue on light blue ("Percentages", "Challenger").
  primary(AppColors.primaryTint, AppColors.primary),

  /// Green on light green ("+16", "Correct: B · $66.00", "Answered").
  success(AppColors.successSurface, AppColors.success),

  /// Red on light red ("timur.b: A · $60.00", "Wrong").
  danger(AppColors.dangerSurface, AppColors.danger),

  /// Amber on light amber ("Overtime · Ratios · Medium", "+1 TIE-BREAK").
  accent(AppColors.accentTint, AppColors.accentDeep),

  /// Ink on grey (rating range "984 – 1384").
  neutral(AppColors.surface, AppColors.ink);

  const AppTagTone(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

/// A small tinted label. Rounded rectangle by default, a pill with
/// [isPill].
final class AppTag extends StatelessWidget {
  const AppTag({
    required this.label,
    this.tone = AppTagTone.primary,
    this.isPill = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    this.style,
    this.leading,
    this.foregroundColor,
    this.isMarkdown = false,
    super.key,
  });

  final String label;
  final AppTagTone tone;
  final bool isPill;
  final EdgeInsetsGeometry padding;

  /// Text style; defaults to 13/16 semibold. The tone color is applied on
  /// top of it.
  final TextStyle? style;

  /// Optional icon before the label (6 px gap).
  final Widget? leading;

  /// Replaces the tone's text color ("You: B · $60.00 · incorrect").
  final Color? foregroundColor;

  /// Renders [label] as inline Markdown with LaTeX (a quoted answer option).
  final bool isMarkdown;

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle =
        (style ?? AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600))
            .copyWith(color: foregroundColor ?? tone.foreground);
    final Widget? icon = leading;
    // Without an icon the label is a bare Text, so a long label (an answer
    // quote in the round review) wraps inside the parent's width instead of
    // overflowing a min-size Row.
    final Widget text = isMarkdown
        ? AppMarkdownLine(label, style: textStyle)
        : Text(label, style: textStyle);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(isPill ? 99 : 6),
      ),
      child: Padding(
        padding: padding,
        child: icon == null
            ? text
            : Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: <Widget>[icon, text],
              ),
      ),
    );
  }
}
