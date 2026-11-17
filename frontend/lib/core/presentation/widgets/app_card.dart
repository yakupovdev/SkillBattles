import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';

/// A bordered (or tinted) rounded block.
final class AppCard extends StatelessComponent {
  const AppCard({
    required this.child,
    this.padding = const Padding.all(Unit.pixels(24)),
    this.color,
    this.borderColor = AppColors.border,
    this.radius = 16,
    this.classes,
    this.styles,
    super.key,
  });

  final Component child;
  final Padding padding;
  final Color? color;

  /// `null` for a borderless tinted card.
  final Color? borderColor;
  final double radius;

  /// Extra classes / styles of the card box (width, flex, shadow).
  final String? classes;
  final Styles? styles;

  @override
  Component build(BuildContext context) {
    final Color? border = borderColor;
    return div(
      classes: classes == null ? 'app-card' : 'app-card $classes',
      styles: Styles.combine(<Styles>[
        Styles(
          padding: padding,
          border: border == null ? null : Border.all(color: border, width: const Unit.pixels(1)),
          radius: BorderRadius.circular(Unit.pixels(radius)),
          backgroundColor: color,
        ),
        ?styles,
      ]),
      <Component>[child],
    );
  }
}

@css
List<StyleRule> get appCardStyles => <StyleRule>[
  css('.app-card').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
  ),
];
