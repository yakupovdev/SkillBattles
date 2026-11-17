import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';

/// "Reconnecting…" pill shown while the realtime connection is down.
final class AppConnectionIndicator extends StatelessComponent {
  const AppConnectionIndicator({super.key});

  @override
  Component build(BuildContext context) {
    return const div(
      classes: 'app-connection-indicator',
      attributes: <String, String>{'role': 'status', 'aria-live': 'polite'},
      <Component>[
        span(
          classes: 'app-connection-indicator__spinner',
          attributes: <String, String>{'aria-hidden': 'true'},
          <Component>[],
        ),
        span(classes: 'app-connection-indicator__label', <Component>[Component.text('Reconnecting…')]),
      ],
    );
  }
}

@css
List<StyleRule> get appConnectionIndicatorStyles => <StyleRule>[
  css('.app-connection-indicator').styles(
    display: Display.inlineFlex,
    height: const Unit.pixels(32),
    padding: const Padding.symmetric(horizontal: Unit.pixels(12)),
    radius: const BorderRadius.circular(Unit.pixels(999)),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(8)),
    backgroundColor: AppColors.surface,
  ),
  css('.app-connection-indicator__spinner').styles(
    display: Display.inlineBlock,
    width: const Unit.pixels(14),
    height: const Unit.pixels(14),
    border: Border.all(color: AppColors.border, width: const Unit.pixels(2)),
    radius: const BorderRadius.circular(Unit.percent(50)),
    flex: const Flex(shrink: 0),
    raw: const <String, String>{
      'border-top-color': '#6B6F7A',
      'animation': 'app-spin 0.8s linear infinite',
    },
  ),
  css('.app-connection-indicator__label')
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.inkSoft, fontWeight: FontWeight.w500)),
];
