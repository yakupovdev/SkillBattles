import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_avatar.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';

/// Picture of the top of a leaderboard and a win streak. The rows slide in
/// from the left one after another and the flame flickers. Fixed sample
/// data.
final class LeaderboardFragment extends StatelessComponent {
  const LeaderboardFragment({super.key});

  @override
  Component build(BuildContext context) {
    return const div(classes: 'leaderboard-fragment', <Component>[
      _Row(index: 0, rank: '01', nickname: 'mira.solves', elo: '2,048', tone: AppAvatarTone.ink, isFirst: true),
      _Row(index: 1, rank: '02', nickname: 'kairat99', elo: '1,962', tone: AppAvatarTone.primary),
      _Row(index: 2, rank: '03', nickname: 'dana_writes', elo: '1,874', tone: AppAvatarTone.accent),
      _StreakLine(),
    ]);
  }
}

final class _Row extends StatelessComponent {
  const _Row({
    required this.index,
    required this.rank,
    required this.nickname,
    required this.elo,
    required this.tone,
    this.isFirst = false,
  });

  final int index;
  final String rank;
  final String nickname;
  final String elo;
  final AppAvatarTone tone;
  final bool isFirst;

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'leaderboard-fragment__row',
      styles: Styles(raw: <String, String>{'--row': '$index'}),
      <Component>[
        span(
          classes: isFirst
              ? 'leaderboard-fragment__rank leaderboard-fragment__rank--first'
              : 'leaderboard-fragment__rank',
          <Component>[Component.text(rank)],
        ),
        AppAvatar(nickname: nickname, size: AppAvatarSize.compact, tone: tone),
        span(classes: 'leaderboard-fragment__name', <Component>[Component.text(nickname)]),
        span(classes: 'leaderboard-fragment__elo', <Component>[Component.text(elo)]),
      ],
    );
  }
}

final class _StreakLine extends StatelessComponent {
  const _StreakLine();

  @override
  Component build(BuildContext context) {
    return const div(classes: 'leaderboard-fragment__streak', <Component>[
      span(classes: 'leaderboard-fragment__flame', <Component>[
        AppSvgIcon(AppIcons.flame, width: 12, height: 14),
      ]),
      span(<Component>[
        span(classes: 'leaderboard-fragment__streak-strong', <Component>[Component.text('5 wins in a row')]),
        Component.text(' · best 7'),
      ]),
    ]);
  }
}

@css
List<StyleRule> get leaderboardFragmentStyles => <StyleRule>[
  css('.leaderboard-fragment').styles(display: Display.flex, flexDirection: FlexDirection.column),
  css('.leaderboard-fragment__row').styles(
    display: Display.flex,
    height: const Unit.pixels(48),
    border: const Border.only(
      bottom: BorderSide(color: AppColors.divider, width: Unit.pixels(1)),
    ),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(12)),
  ),
  css('.leaderboard-fragment__rank').combine(AppTextStyles.monoBodyMd).combine(const Styles(width: Unit.pixels(24))),
  css('.leaderboard-fragment__rank--first').styles(color: AppColors.accent),
  css('.leaderboard-fragment__name')
      .combine(AppTextStyles.bodyMd)
      .combine(
        const Styles(
          flex: Flex(grow: 1, shrink: 1, basis: Unit.zero),
          fontWeight: FontWeight.w500,
        ),
      ),
  css('.leaderboard-fragment__elo').combine(AppTextStyles.monoBodyMd),
  css('.leaderboard-fragment__streak')
      .combine(AppTextStyles.bodySm)
      .combine(
        const Styles(
          display: Display.flex,
          padding: Padding.only(top: Unit.pixels(14)),
          alignItems: AlignItems.center,
          gap: Gap.column(Unit.pixels(6)),
          color: AppColors.accentText,
        ),
      ),
  css('.leaderboard-fragment__streak-strong').styles(fontWeight: FontWeight.w600),
  css('.leaderboard-fragment__flame').styles(
    display: Display.flex,
    raw: const <String, String>{'animation': 'welcome-flicker 900ms ease-in-out infinite alternate'},
  ),
  css.keyframes('welcome-flicker', <String, Styles>{
    'from': const Styles(transform: Transform.scale(1)),
    'to': const Styles(transform: Transform.scale(1.12)),
  }),
  css('.app-reveal--armed:not(.app-reveal--in) .leaderboard-fragment__row').styles(
    opacity: 0,
    transform: const Transform.translate(x: Unit.pixels(-12)),
  ),
  css('.app-reveal--in .leaderboard-fragment__row').styles(
    raw: const <String, String>{
      'animation': 'welcome-slide-left 400ms cubic-bezier(0.2, 0.7, 0.2, 1) calc(200ms + var(--row) * 80ms) both',
    },
  ),
  css.keyframes('welcome-slide-left', <String, Styles>{
    'from': const Styles(opacity: 0, transform: Transform.translate(x: Unit.pixels(-12))),
    'to': const Styles(opacity: 1, transform: Transform.none),
  }),
  css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), <StyleRule>[
    css('.app-reveal--in .leaderboard-fragment__row').styles(raw: const <String, String>{'animation': 'none'}),
    css('.leaderboard-fragment__flame').styles(raw: const <String, String>{'animation': 'none'}),
  ]),
];
