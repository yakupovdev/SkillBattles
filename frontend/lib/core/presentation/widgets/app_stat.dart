import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';

/// A mono value over a small muted label.
final class AppStat extends StatelessComponent {
  const AppStat({
    required this.value,
    required this.label,
    this.valueColor = AppColors.ink,
    this.valueStyle = AppTextStyles.monoSm,
    super.key,
  });

  final String value;
  final String label;
  final Color valueColor;
  final Styles valueStyle;

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'app-stat',
      attributes: <String, String>{'role': 'group', 'aria-label': '$label: $value'},
      <Component>[
        span(
          classes: 'app-stat__value',
          styles: valueStyle.combine(Styles(color: valueColor)),
          attributes: const <String, String>{'aria-hidden': 'true'},
          <Component>[Component.text(value)],
        ),
        span(
          classes: 'app-stat__label',
          attributes: const <String, String>{'aria-hidden': 'true'},
          <Component>[Component.text(label)],
        ),
      ],
    );
  }
}

@css
List<StyleRule> get appStatStyles => <StyleRule>[
  css('.app-stat').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(2)),
  ),
  css('.app-stat__label').combine(AppTextStyles.bodyXs).combine(const Styles(color: AppColors.muted)),
];
