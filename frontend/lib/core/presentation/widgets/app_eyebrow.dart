import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';

/// The spaced mono caption above titles ("STEP 1 — CHOOSE A SUBJECT",
/// "MATH · RANKED"). The text is shown upper case.
final class AppEyebrow extends StatelessComponent {
  const AppEyebrow(
    this.text, {
    this.color = AppColors.muted,
    this.textAlign,
    super.key,
  });

  final String text;
  final Color color;
  final TextAlign? textAlign;

  @override
  Component build(BuildContext context) {
    return p(
      classes: 'app-eyebrow',
      styles: Styles(color: color, textAlign: textAlign),
      <Component>[Component.text(text.toUpperCase())],
    );
  }
}

/// A small filled circle used as a status marker (online, info notes).
final class AppDot extends StatelessComponent {
  const AppDot({required this.color, this.size = 8, super.key});

  final Color color;
  final double size;

  @override
  Component build(BuildContext context) {
    return span(
      classes: 'app-dot',
      styles: Styles(width: Unit.pixels(size), height: Unit.pixels(size), backgroundColor: color),
      attributes: const <String, String>{'aria-hidden': 'true'},
      const <Component>[],
    );
  }
}

@css
List<StyleRule> get appEyebrowStyles => <StyleRule>[
  css('.app-eyebrow').combine(AppTextStyles.eyebrow),
  css('.app-dot').styles(
    display: Display.inlineBlock,
    radius: const BorderRadius.circular(Unit.percent(50)),
    flex: const Flex(shrink: 0),
  ),
];
