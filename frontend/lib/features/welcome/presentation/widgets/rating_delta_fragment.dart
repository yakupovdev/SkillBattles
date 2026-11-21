import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_count_up.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';

/// Picture of two rating changes after a battle (win and loss). The new
/// numbers count from the old ones when the card is revealed, then the
/// delta tags pop in. Fixed sample data.
final class RatingDeltaFragment extends StatelessComponent {
  const RatingDeltaFragment({super.key});

  @override
  Component build(BuildContext context) {
    return const div(classes: 'rating-fragment', <Component>[
      _RatingRow(
        title: 'SAT Math',
        subtitle: 'Win vs timur.b',
        oldRating: 1032,
        newRating: 1050,
        delta: '+18',
        isGain: true,
      ),
      _RatingRow(
        title: 'SAT Reading & Writing',
        subtitle: 'Loss vs dana_writes',
        oldRating: 1004,
        newRating: 992,
        delta: '−12',
        isGain: false,
      ),
    ]);
  }
}

final class _RatingRow extends StatelessComponent {
  const _RatingRow({
    required this.title,
    required this.subtitle,
    required this.oldRating,
    required this.newRating,
    required this.delta,
    required this.isGain,
  });

  final String title;
  final String subtitle;
  final int oldRating;
  final int newRating;
  final String delta;
  final bool isGain;

  @override
  Component build(BuildContext context) {
    return div(classes: 'rating-fragment__row', <Component>[
      div(classes: 'rating-fragment__text', <Component>[
        span(classes: 'rating-fragment__title', <Component>[Component.text(title)]),
        span(classes: 'rating-fragment__subtitle', <Component>[Component.text(subtitle)]),
      ]),
      div(classes: 'rating-fragment__numbers', <Component>[
        span(classes: 'rating-fragment__old', <Component>[Component.text('$oldRating')]),
        const AppSvgIcon(AppIcons.arrowSmall, width: 16, height: 16, color: AppColors.ink),
        span(classes: 'rating-fragment__new', <Component>[AppCountUp(from: oldRating, to: newRating)]),
        span(classes: 'rating-fragment__lane', <Component>[
          span(
            classes: isGain
                ? 'welcome-delta-tag rating-fragment__tag rating-fragment__tag--gain'
                : 'welcome-delta-tag rating-fragment__tag rating-fragment__tag--loss',
            <Component>[Component.text(delta)],
          ),
        ]),
      ]),
    ]);
  }
}

@css
List<StyleRule> get ratingDeltaFragmentStyles => <StyleRule>[
  css('.rating-fragment').styles(
    padding: const Padding.symmetric(horizontal: Unit.pixels(20), vertical: Unit.pixels(8)),
    radius: const BorderRadius.circular(Unit.pixels(12)),
    backgroundColor: AppColors.surface,
  ),
  css('.rating-fragment__row').styles(
    display: Display.flex,
    height: const Unit.pixels(56),
    justifyContent: JustifyContent.spaceBetween,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(16)),
  ),
  css('.rating-fragment__row + .rating-fragment__row').styles(
    border: const Border.only(
      top: BorderSide(color: AppColors.border, width: Unit.pixels(1)),
    ),
  ),
  css('.rating-fragment__text').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(2)),
  ),
  css('.rating-fragment__title').combine(AppTextStyles.bodyMd).combine(const Styles(fontWeight: FontWeight.w600)),
  css('.rating-fragment__subtitle').combine(AppTextStyles.bodyXs).combine(const Styles(color: AppColors.muted)),
  css('.rating-fragment__numbers').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(10)),
  ),
  css('.rating-fragment__old')
      .combine(AppTextStyles.monoSm)
      .combine(const Styles(color: AppColors.faint, fontSize: Unit.pixels(18), lineHeight: Unit.pixels(22))),
  css('.rating-fragment__new')
      .combine(AppTextStyles.monoSm)
      .combine(const Styles(fontSize: Unit.pixels(18), lineHeight: Unit.pixels(22))),
  css('.rating-fragment__lane').styles(
    display: Display.flex,
    width: const Unit.pixels(52),
    justifyContent: JustifyContent.center,
  ),
  css('.rating-fragment__tag')
      .combine(AppTextStyles.monoBodySm)
      .combine(
        const Styles(
          padding: Padding.symmetric(horizontal: Unit.pixels(7), vertical: Unit.pixels(2)),
          radius: BorderRadius.circular(Unit.pixels(6)),
          fontSize: Unit.pixels(13),
          fontWeight: FontWeight.w600,
          lineHeight: Unit.pixels(18),
        ),
      ),
  css('.rating-fragment__tag--gain').styles(color: AppColors.success, backgroundColor: AppColors.successSurface),
  css('.rating-fragment__tag--loss').styles(color: AppColors.dangerText, backgroundColor: AppColors.dangerSurface),
  // The tags pop in after the numbers have counted.
  css('.app-reveal--armed:not(.app-reveal--in) .welcome-delta-tag').styles(opacity: 0),
  css('.app-reveal--in .welcome-delta-tag').styles(
    raw: const <String, String>{'animation': 'welcome-pop 300ms cubic-bezier(0.34, 1.56, 0.64, 1) 650ms both'},
  ),
  css.keyframes('welcome-pop', <String, Styles>{
    'from': const Styles(opacity: 0, transform: Transform.scale(0.8)),
    'to': const Styles(opacity: 1, transform: Transform.scale(1)),
  }),
  css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), <StyleRule>[
    css('.app-reveal--in .welcome-delta-tag').styles(raw: const <String, String>{'animation': 'none'}),
  ]),
];
