import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';

/// Picture of one expanded row of the round review. The chips appear
/// first, then the explanation slides down. Fixed sample data.
final class ReviewRowFragment extends StatelessComponent {
  const ReviewRowFragment({super.key});

  @override
  Component build(BuildContext context) {
    return const div(classes: 'review-fragment', <Component>[
      div(classes: 'review-fragment__head', <Component>[
        span(classes: 'review-fragment__number', <Component>[Component.text('03')]),
        span(classes: 'review-fragment__title', <Component>[Component.text('Jacket \$80, −25%, then +10% tax…')]),
      ]),
      div(classes: 'review-fragment__chips', <Component>[
        span(classes: 'review-fragment__chip review-fragment__chip--correct', <Component>[
          Component.text('Correct: B · \$66.00'),
        ]),
        span(classes: 'review-fragment__chip review-fragment__chip--wrong', <Component>[
          Component.text('You: A · \$60.00'),
        ]),
      ]),
      p(classes: 'review-fragment__explanation', <Component>[
        Component.text('25% off leaves \$60. Tax is added to the discounted price: \$60 × 1.10 = \$66.'),
      ]),
    ]);
  }
}

@css
List<StyleRule> get reviewRowFragmentStyles => <StyleRule>[
  css('.review-fragment').styles(
    display: Display.flex,
    padding: const Padding.all(Unit.pixels(18)),
    border: Border.all(color: AppColors.ink, width: const Unit.pixels(1.5)),
    radius: const BorderRadius.circular(Unit.pixels(12)),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(12)),
    backgroundColor: AppColors.white,
  ),
  css('.review-fragment__head').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(12)),
  ),
  css('.review-fragment__number')
      .combine(AppTextStyles.monoBodySm)
      .combine(
        const Styles(
          width: Unit.pixels(18),
          color: AppColors.muted,
          fontSize: Unit.pixels(13),
          lineHeight: Unit.pixels(18),
        ),
      ),
  css('.review-fragment__title').combine(AppTextStyles.bodyMd).combine(const Styles(fontWeight: FontWeight.w600)),
  css('.review-fragment__chips').styles(
    display: Display.flex,
    padding: const Padding.only(left: Unit.pixels(30)),
    flexWrap: FlexWrap.wrap,
    gap: const Gap(row: Unit.pixels(8), column: Unit.pixels(8)),
  ),
  css('.review-fragment__chip')
      .combine(AppTextStyles.bodyXs)
      .combine(
        const Styles(
          padding: Padding.symmetric(horizontal: Unit.pixels(8), vertical: Unit.pixels(3)),
          radius: BorderRadius.circular(Unit.pixels(6)),
          fontWeight: FontWeight.w500,
        ),
      ),
  css('.review-fragment__chip--correct').styles(color: AppColors.success, backgroundColor: AppColors.successSurface),
  css('.review-fragment__chip--wrong').styles(color: AppColors.dangerText, backgroundColor: AppColors.dangerSurface),
  css('.review-fragment__explanation')
      .combine(AppTextStyles.bodySm)
      .combine(
        const Styles(
          padding: Padding.only(left: Unit.pixels(30)),
          color: AppColors.inkSoft,
          lineHeight: Unit.pixels(19),
        ),
      ),
  css('.app-reveal--armed:not(.app-reveal--in) .review-fragment__chips').styles(opacity: 0),
  css('.app-reveal--armed:not(.app-reveal--in) .review-fragment__explanation').styles(
    opacity: 0,
    transform: const Transform.translate(y: Unit.pixels(-8)),
  ),
  css('.app-reveal--in .review-fragment__chips').styles(
    raw: <String, String>{'animation': 'welcome-fade 400ms $_ease 300ms both'},
  ),
  css('.app-reveal--in .review-fragment__explanation').styles(
    raw: <String, String>{'animation': 'welcome-drop 400ms $_ease 800ms both'},
  ),
  css.keyframes('welcome-fade', <String, Styles>{
    'from': const Styles(opacity: 0),
    'to': const Styles(opacity: 1),
  }),
  css.keyframes('welcome-drop', <String, Styles>{
    'from': const Styles(opacity: 0, transform: Transform.translate(y: Unit.pixels(-8))),
    'to': const Styles(opacity: 1, transform: Transform.none),
  }),
  css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), <StyleRule>[
    css('.app-reveal--in .review-fragment__chips').styles(raw: const <String, String>{'animation': 'none'}),
    css('.app-reveal--in .review-fragment__explanation').styles(raw: const <String, String>{'animation': 'none'}),
  ]),
];

const String _ease = 'cubic-bezier(0.2, 0.7, 0.2, 1)';
