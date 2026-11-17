import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

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
/// [isPill]. It hugs its content and wraps a long label inside the width of
/// its parent.
final class AppTag extends StatelessComponent {
  const AppTag({
    required this.label,
    this.tone = AppTagTone.primary,
    this.isPill = false,
    this.padding = const Padding.symmetric(horizontal: Unit.pixels(10), vertical: Unit.pixels(5)),
    this.style,
    this.leading,
    this.foregroundColor,
    this.isMarkdown = false,
    super.key,
  });

  final String label;
  final AppTagTone tone;
  final bool isPill;
  final Padding padding;

  /// Text style; defaults to 13/16 semibold. The tone color is applied on
  /// top of it.
  final Styles? style;

  /// Optional icon before the label (6 px gap).
  final Component? leading;

  /// Replaces the tone's text color ("You: B · $60.00 · incorrect").
  final Color? foregroundColor;

  /// Renders [label] as inline Markdown with LaTeX (a quoted answer option).
  final bool isMarkdown;

  static const Styles _defaultStyle = Styles(
    fontFamily: AppFonts.body,
    fontSize: Unit.pixels(13),
    fontWeight: FontWeight.w600,
    lineHeight: Unit.pixels(16),
  );

  static const Styles _box = Styles(display: Display.block, width: Unit.fitContent, maxWidth: Unit.percent(100));

  static const Styles _iconBox = Styles(
    display: Display.flex,
    width: Unit.fitContent,
    maxWidth: Unit.percent(100),
    alignItems: AlignItems.center,
    gap: Gap.column(Unit.pixels(6)),
  );

  static const Styles _label = Styles(display: Display.block, minWidth: Unit.zero);

  @override
  Component build(BuildContext context) {
    final Styles textStyle = (style ?? _defaultStyle).combine(Styles(color: foregroundColor ?? tone.foreground));
    final Component? icon = leading;
    final Component text = isMarkdown
        ? AppMarkdownLine(label, style: textStyle)
        : span(styles: textStyle.combine(_label), <Component>[Component.text(label)]);

    // Inline styles only: this file imports the Markdown renderer, which
    // the `@css` collector cannot compile (see `MarkdownStyles`).
    return div(
      classes: 'app-tag',
      styles: Styles.combine(<Styles>[
        icon == null ? _box : _iconBox,
        Styles(
          padding: padding,
          radius: BorderRadius.circular(Unit.pixels(isPill ? 99 : 6)),
          backgroundColor: tone.background,
        ),
      ]),
      <Component>[?icon, text],
    );
  }
}
