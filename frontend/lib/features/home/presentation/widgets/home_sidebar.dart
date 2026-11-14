import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';
import 'package:skill_battles/features/account/domain/entity/streaks_entity.dart';

/// Right column: the daily streak with this week's days, and the Pro offer
/// for Free players.
final class HomeSidebar extends StatelessWidget {
  const HomeSidebar({
    required this.streaks,
    required this.today,
    required this.isPro,
    super.key,
  });

  /// Width on the artboard, divider included.
  static const double width = 340;

  final StreaksEntity streaks;

  /// Today's ET date (the date of the ranked counter).
  final DateTime today;
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.only(left: 41),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 28,
          children: <Widget>[
            _StreakSection(streaks: streaks, today: today),
            if (!isPro) const Skeleton.ignore(child: _ProOffer()),
          ],
        ),
      ),
    );
  }
}

/// How one weekday cell of the streak strip looks.
enum _DayState { active, pending, idle }

final class _StreakSection extends StatelessWidget {
  const _StreakSection({required this.streaks, required this.today});

  final StreaksEntity streaks;
  final DateTime today;

  static const List<String> _letters = <String>[
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
    'S',
  ];

  static int _dayNumber(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

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
        if (active.contains(i))
          _DayState.active
        else if (i == todayIndex)
          _DayState.pending
        else
          _DayState.idle,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final int days = streaks.currentWeekActiveDays;
    final int target = streaks.currentWeekTarget;
    final DateTime? last = streaks.lastQualifiedDate;
    final bool playedToday =
        last != null && _dayNumber(last) == _dayNumber(today);
    final int todayIndex =
        _dayNumber(today) - _dayNumber(streaks.currentWeekStart);
    final List<_DayState> week = _week();
    final String weekly = days >= target
        ? ' this week — weekly streak secured.'
        : ' this week — ${target - days} more for the weekly streak.';
    final String daily = playedToday
        ? ''
        : streaks.dailyCurrent > 0
        ? ' Finish one match today to keep the daily streak.'
        : ' Finish one match today to start a daily streak.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            const Text('Your streak', style: AppTextStyles.titleMd),
            Text(
              'Best ${streaks.dailyBest} '
              '${streaks.dailyBest == 1 ? 'day' : 'days'}',
              style: AppTextStyles.bodyXs.copyWith(color: AppColors.muted),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 10,
          children: <Widget>[
            Text(
              '${streaks.dailyCurrent}',
              style: AppTextStyles.monoStreak.copyWith(color: AppColors.accent),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                streaks.dailyCurrent == 1 ? 'day in a row' : 'days in a row',
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 20 / 14,
                ),
              ),
            ),
          ],
        ),
        ExcludeSemantics(
          child: Row(
            spacing: 6,
            children: <Widget>[
              for (int i = 0; i < 7; i++)
                Expanded(
                  child: _DayCell(
                    letter: _letters[i],
                    state: week[i],
                    isToday: i == todayIndex,
                  ),
                ),
            ],
          ),
        ),
        Text.rich(
          TextSpan(
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.muted,
              height: 19 / 13,
            ),
            children: <InlineSpan>[
              TextSpan(
                text: '$days of $target days',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(text: '$weekly$daily'),
            ],
          ),
        ),
      ],
    );
  }
}

final class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.letter,
    required this.state,
    required this.isToday,
  });

  final String letter;
  final _DayState state;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 6,
      children: <Widget>[
        SizedBox(
          height: 28,
          width: double.infinity,
          child: switch (state) {
            _DayState.active => const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
            _DayState.idle => const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
            _DayState.pending => const CustomPaint(painter: _DashedBox()),
          },
        ),
        Text(
          letter,
          style: AppTextStyles.monoCaption.copyWith(
            color: isToday ? AppColors.ink : AppColors.muted,
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

/// Today, not played yet: a dashed amber outline.
final class _DashedBox extends CustomPainter {
  const _DashedBox();

  static const double _dash = 4;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final RRect box = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.75),
      const Radius.circular(8),
    );
    final Path outline = Path()..addRRect(box);
    for (final PathMetric metric in outline.computeMetrics()) {
      for (double d = 0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBox oldDelegate) => false;
}

/// The ink card that sells Pro to Free players.
final class _ProOffer extends StatelessWidget {
  const _ProOffer();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 14,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Text(
                  'PRO',
                  style: AppTextStyles.monoCaption.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.06 * 11,
                  ),
                ),
              ),
            ),
            Text(
              'See why you missed it — not just that you did.',
              style: AppTextStyles.titleMd.copyWith(
                color: AppColors.white,
                height: 25 / 20,
                letterSpacing: -0.01 * 20,
              ),
            ),
            Text(
              'Correct answers, explanations, topic analytics and unlimited '
              'ranked. Your Elo works the same either way.',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.onPrimaryMuted,
                height: 19 / 13,
              ),
            ),
            AppTappable(
              onTap: context.goPro,
              borderRadius: BorderRadius.circular(4),
              semanticLabel: 'See plans',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: <Widget>[
                  Text(
                    'See plans',
                    style: AppTextStyles.buttonMd.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                  const AppSvgIcon(AppIcons.arrowLink, width: 14, height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
