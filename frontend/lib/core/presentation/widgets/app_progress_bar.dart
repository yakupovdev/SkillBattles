import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';

/// A thin rounded progress track.
final class AppProgressBar extends StatelessComponent {
  const AppProgressBar({
    required this.fraction,
    this.color = AppColors.primary,
    this.trackColor = AppColors.surface,
    this.height = 6,
    super.key,
  });

  final double fraction;
  final Color color;
  final Color trackColor;
  final double height;

  @override
  Component build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(Unit.pixels(height / 2));
    return div(
      classes: 'app-progress-bar',
      styles: Styles(height: Unit.pixels(height), radius: radius, backgroundColor: trackColor),
      attributes: const <String, String>{'aria-hidden': 'true'},
      <Component>[
        div(
          classes: 'app-progress-bar__fill',
          styles: Styles(
            width: Unit.percent(fraction.clamp(0, 1).toDouble() * 100),
            radius: radius,
            backgroundColor: color,
          ),
          const <Component>[],
        ),
      ],
    );
  }
}

@css
List<StyleRule> get appProgressBarStyles => <StyleRule>[
  css('.app-progress-bar').styles(
    width: const Unit.percent(100),
    overflow: Overflow.hidden,
  ),
  css('.app-progress-bar__fill').styles(height: const Unit.percent(100)),
];
