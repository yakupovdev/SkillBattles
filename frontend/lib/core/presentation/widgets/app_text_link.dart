import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';

/// A tappable piece of text without a box ("See all", "Cancel duel",
/// "Surrender", "Review"). The caller passes the exact Paper style.
///
/// Without [textAlign] the link hugs its text (also inside a stretching
/// flex column); with it the link takes the width its parent gives.
final class AppTextLink extends StatelessComponent {
  const AppTextLink({
    required this.label,
    required this.style,
    required this.onPressed,
    this.textAlign,
    super.key,
  });

  final String label;
  final Styles style;
  final VoidCallback? onPressed;
  final TextAlign? textAlign;

  @override
  Component build(BuildContext context) {
    final TextAlign? align = textAlign;
    return AppTappable(
      onTap: onPressed,
      radius: 4,
      classes: align == null ? 'app-text-link app-text-link--hug' : 'app-text-link',
      styles: align == null ? style : style.combine(Styles(textAlign: align)),
      child: span(<Component>[Component.text(label)]),
    );
  }
}

@css
List<StyleRule> get appTextLinkStyles => <StyleRule>[
  css('.app-text-link').styles(display: Display.block),
  css('.app-text-link--hug').styles(width: Unit.fitContent, maxWidth: const Unit.percent(100)),
];
