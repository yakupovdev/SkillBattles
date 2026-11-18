import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/skeleton/skeletonizer.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';
import 'package:skill_battles/core/utils/feature_flags.dart';
import 'package:skill_battles/features/account/domain/entity/streaks_entity.dart';

/// Right column: the daily streak with this week's days, and the Pro offer
/// for Free players.
final class HomeSidebar extends StatelessComponent {
  const HomeSidebar({required this.streaks, required this.today, required this.isPro, super.key});

  /// Width on the artboard, divider included.
  static const double width = 340;

  final StreaksEntity streaks;

  /// Today's ET date (the date of the ranked counter).
  final DateTime today;
  final bool isPro;

  @override
  Component build(BuildContext context) {
    return div(classes: 'home-sidebar', <Component>[
      _StreakSection(streaks: streaks, today: today),
      if (FeatureFlags.billing && !isPro) Skeleton.ignore(child: const _ProOffer()),
    ]);
  }
}

/// How one weekday cell of the streak strip looks.
enum _DayState { active, pending, idle }

final class _StreakSection extends StatelessComponent {
  const _StreakSection({required this.streaks, required this.today});

  final StreaksEntity streaks;
  final DateTime today;

  static const List<String> _letters = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  static int _dayNumber(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

  /// Days of the current ET week. The server gives the streak run (ending
  /// on the last qualified day) and the number of active days this week,
  /// not each day: the run is placed exactly, the rest of the active days
  /// fill the earliest free days before it.
  List<_DayState> _week() {
    final int start = _dayNumber(streaks.currentWeekStart);
    final int todayIndex = _dayNumber(today) - start;
    final Set<int> active = <int>{};
    final DateTime? last = streaks.lastQualifiedDate;
    int runStart = 7;
    if (last != null && streaks.dailyCurrent > 0) {
      final int lastIndex = _dayNumber(last) - start;
      runStart = lastIndex - streaks.dailyCurrent + 1;
      for (int i = runStart; i <= lastIndex; i++) {
        if (i >= 0 && i < 7) active.add(i);
      }
    }
    int rest = streaks.currentWeekActiveDays - active.length;
    // The day just before the run cannot be active, or the run would be
    // longer.
    for (int i = 0; i < 7 && rest > 0; i++) {
      if (i >= runStart - 1 || i > todayIndex) break;
      if (active.add(i)) rest--;
    }
    return <_DayState>[
      for (int i = 0; i < 7; i++)
        if (active.contains(i)) _DayState.active else if (i == todayIndex) _DayState.pending else _DayState.idle,
    ];
  }

  @override
  Component build(BuildContext context) {
    final int days = streaks.currentWeekActiveDays;
    final int target = streaks.currentWeekTarget;
    final DateTime? last = streaks.lastQualifiedDate;
    final bool playedToday = last != null && _dayNumber(last) == _dayNumber(today);
    final int todayIndex = _dayNumber(today) - _dayNumber(streaks.currentWeekStart);
    final List<_DayState> week = _week();
    final String weekly = days >= target
        ? ' this week — weekly streak secured.'
        : ' this week — ${target - days} more for the weekly streak.';
    final String daily = playedToday
        ? ''
        : streaks.dailyCurrent > 0
        ? ' Finish one match today to keep the daily streak.'
        : ' Finish one match today to start a daily streak.';

    return div(classes: 'home-streak', <Component>[
      div(classes: 'home-streak__head', <Component>[
        const h2(classes: 'home-streak__title', <Component>[Component.text('Your streak')]),
        p(classes: 'home-streak__best', <Component>[
          Component.text('Best ${streaks.dailyBest} ${streaks.dailyBest == 1 ? 'day' : 'days'}'),
        ]),
      ]),
      div(classes: 'home-streak__count', <Component>[
        p(classes: 'home-streak__number', <Component>[Component.text('${streaks.dailyCurrent}')]),
        p(classes: 'home-streak__unit', <Component>[
          Component.text(streaks.dailyCurrent == 1 ? 'day in a row' : 'days in a row'),
        ]),
      ]),
      div(
        classes: 'home-streak__week',
        attributes: const <String, String>{'aria-hidden': 'true'},
        <Component>[
          for (int i = 0; i < 7; i++) _DayCell(letter: _letters[i], state: week[i], isToday: i == todayIndex),
        ],
      ),
      p(classes: 'home-streak__summary', <Component>[
        span(classes: 'home-streak__days', <Component>[Component.text('$days of $target days')]),
        span(<Component>[Component.text('$weekly$daily')]),
      ]),
    ]);
  }
}

final class _DayCell extends StatelessComponent {
  const _DayCell({required this.letter, required this.state, required this.isToday});

  final String letter;
  final _DayState state;
  final bool isToday;

  @override
  Component build(BuildContext context) {
    return div(classes: 'home-day', <Component>[
      span(
        classes: switch (state) {
          _DayState.active => 'home-day__box home-day__box--active',
          _DayState.idle => 'home-day__box home-day__box--idle',
          // Today, not played yet: a dashed amber outline.
          _DayState.pending => 'home-day__box home-day__box--pending',
        },
        const <Component>[],
      ),
      span(
        classes: isToday ? 'home-day__letter home-day__letter--today' : 'home-day__letter',
        <Component>[Component.text(letter)],
      ),
    ]);
  }
}

/// The ink card that sells Pro to Free players.
final class _ProOffer extends StatelessComponent {
  const _ProOffer();

  @override
  Component build(BuildContext context) {
    return div(classes: 'home-pro-offer', <Component>[
      const span(classes: 'home-pro-offer__badge', <Component>[Component.text('PRO')]),
      const p(classes: 'home-pro-offer__title', <Component>[
        Component.text('See why you missed it — not just that you did.'),
      ]),
      const p(classes: 'home-pro-offer__body', <Component>[
        Component.text(
          'Correct answers, explanations, topic analytics and unlimited '
          'ranked. Your Elo works the same either way.',
        ),
      ]),
      AppTappable(
        onTap: context.goPro,
        radius: 4,
        semanticLabel: 'See plans',
        classes: 'home-pro-offer__link',
        child: Component.fragment(<Component>[
          const span(classes: 'home-pro-offer__link-label', <Component>[Component.text('See plans')]),
          const AppSvgIcon(AppIcons.arrowLink, width: 14, height: 14),
        ]),
      ),
    ]);
  }
}

@css
List<StyleRule> get homeSidebarStyles => <StyleRule>[
  css('.home-sidebar').styles(
    display: Display.flex,
    width: const Unit.pixels(HomeSidebar.width),
    padding: const Padding.only(left: Unit.pixels(41)),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(28)),
    flex: const Flex(shrink: 0),
  ),
  css('.home-streak').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(16)),
  ),
  css('.home-streak__head').styles(
    display: Display.flex,
    justifyContent: JustifyContent.spaceBetween,
    alignItems: AlignItems.baseline,
  ),
  css('.home-streak__title').combine(AppTextStyles.titleMd),
  css('.home-streak__best').combine(AppTextStyles.bodyXs).combine(const Styles(color: AppColors.muted)),
  css('.home-streak__count').styles(
    display: Display.flex,
    alignItems: AlignItems.end,
    gap: const Gap.column(Unit.pixels(10)),
  ),
  css('.home-streak__number').combine(AppTextStyles.monoStreak).combine(const Styles(color: AppColors.accent)),
  css('.home-streak__unit')
      .styles(padding: const Padding.only(bottom: Unit.pixels(4)))
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(fontWeight: FontWeight.w500, lineHeight: Unit.pixels(20))),
  css('.home-streak__week').styles(display: Display.flex, gap: const Gap.column(Unit.pixels(6))),
  css('.home-streak__summary')
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.muted, lineHeight: Unit.pixels(19))),
  css('.home-streak__days').styles(color: AppColors.ink, fontWeight: FontWeight.w600),
  css('.home-day').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.center,
    gap: const Gap.row(Unit.pixels(6)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.home-day__box').styles(
    display: Display.block,
    width: const Unit.percent(100),
    height: const Unit.pixels(28),
    radius: const BorderRadius.circular(Unit.pixels(8)),
  ),
  css('.home-day__box--active').styles(backgroundColor: AppColors.accent),
  css('.home-day__box--idle').styles(backgroundColor: AppColors.surface),
  css('.home-day__box--pending').styles(
    border: Border.all(style: BorderStyle.dashed, color: AppColors.accent, width: const Unit.pixels(1.5)),
  ),
  css('.home-day__letter').combine(AppTextStyles.monoCaption).combine(const Styles(color: AppColors.muted)),
  css('.home-day__letter--today').styles(color: AppColors.ink, fontWeight: FontWeight.w700),
  css('.home-pro-offer').styles(
    display: Display.flex,
    padding: const Padding.all(Unit.pixels(22)),
    radius: const BorderRadius.circular(Unit.pixels(14)),
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(14)),
    backgroundColor: AppColors.ink,
  ),
  css('.home-pro-offer__badge')
      .styles(
        padding: const Padding.symmetric(horizontal: Unit.pixels(8), vertical: Unit.pixels(3)),
        radius: const BorderRadius.circular(Unit.pixels(6)),
        backgroundColor: AppColors.accent,
      )
      .combine(AppTextStyles.monoCaption)
      .combine(const Styles(fontWeight: FontWeight.w700, letterSpacing: Unit.em(0.06))),
  css('.home-pro-offer__title')
      .combine(AppTextStyles.titleMd)
      .combine(const Styles(color: AppColors.white, letterSpacing: Unit.em(-0.01), lineHeight: Unit.pixels(25))),
  css('.home-pro-offer__body')
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.onPrimaryMuted, lineHeight: Unit.pixels(19))),
  css('.home-pro-offer__link').styles(
    display: Display.inlineFlex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(6)),
  ),
  css('.home-pro-offer__link-label').combine(AppTextStyles.buttonMd).combine(const Styles(color: AppColors.accent)),
];
