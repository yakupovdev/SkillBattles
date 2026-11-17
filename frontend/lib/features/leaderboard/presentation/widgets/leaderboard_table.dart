import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/league/league_rank.dart';
import 'package:skill_battles/core/presentation/widgets/app_avatar.dart';
import 'package:skill_battles/core/presentation/widgets/league_emblem.dart';
import 'package:skill_battles/core/presentation/widgets/pro_badge.dart';
import 'package:skill_battles/features/leaderboard/domain/entity/leaderboard_entity.dart';
import 'package:skill_battles/features/leaderboard/domain/entity/leaderboard_entry_entity.dart';

/// Column widths of the leaderboard table (Paper: "20 Leaderboard").
abstract final class _Columns {
  static const double position = 48;
  static const double rank = 160;
  static const double elo = 80;
}

/// The season top with the own row: inside the top it is highlighted in
/// place, otherwise it follows the top after a "· · ·" gap.
final class LeaderboardTable extends StatelessComponent {
  const LeaderboardTable({required this.board, super.key});

  final LeaderboardEntity board;

  @override
  Component build(BuildContext context) {
    final LeaderboardEntryEntity? me = board.me;
    final bool meInTop = me != null && board.top.any((LeaderboardEntryEntity e) => e.player.id == me.player.id);
    return div(classes: 'leaderboard-table', <Component>[
      const _Header(),
      if (board.top.isEmpty) const _Empty(),
      for (final LeaderboardEntryEntity entry in board.top)
        _Row(key: ValueKey<String>(entry.player.id), entry: entry, isMe: entry.player.id == me?.player.id),
      if (me != null && !meInTop) ...<Component>[
        if (board.top.isNotEmpty) const _Gap(),
        _Row(entry: me, isMe: true),
      ],
    ]);
  }
}

final class _Header extends StatelessComponent {
  const _Header();

  @override
  Component build(BuildContext context) {
    return const div(classes: 'leaderboard-table__header', <Component>[
      span(classes: 'leaderboard-table__position', <Component>[Component.text('#')]),
      span(classes: 'leaderboard-table__player', <Component>[Component.text('Player')]),
      span(classes: 'leaderboard-table__rank', <Component>[Component.text('Rank')]),
      span(classes: 'leaderboard-table__elo', <Component>[Component.text('Elo')]),
    ]);
  }
}

final class _Empty extends StatelessComponent {
  const _Empty();

  @override
  Component build(BuildContext context) {
    return const p(classes: 'leaderboard-table__empty', <Component>[
      Component.text('No ratings yet. Play a ranked match to open the season.'),
    ]);
  }
}

final class _Gap extends StatelessComponent {
  const _Gap();

  @override
  Component build(BuildContext context) {
    return const p(classes: 'leaderboard-table__gap', <Component>[Component.text('· · ·')]);
  }
}

final class _Row extends StatelessComponent {
  const _Row({required this.entry, required this.isMe, super.key});

  final LeaderboardEntryEntity entry;
  final bool isMe;

  @override
  Component build(BuildContext context) {
    final int position = entry.position;
    final bool isPodium = position <= 3;
    final bool isStrong = isPodium || isMe;
    final Color positionColor = isMe
        ? AppColors.primary
        : position == 1
        ? AppColors.accent
        : isPodium
        ? AppColors.ink
        : AppColors.muted;
    final AppAvatarTone tone = isMe
        ? AppAvatarTone.primary
        : switch (position) {
            1 => AppAvatarTone.ink,
            2 => AppAvatarTone.primary,
            3 => AppAvatarTone.accent,
            _ => AppAvatarTone.neutral,
          };
    return div(classes: isMe ? 'leaderboard-row leaderboard-row--me' : 'leaderboard-row', <Component>[
      span(
        classes: 'leaderboard-table__position leaderboard-row__mono',
        styles: Styles(color: positionColor, fontWeight: isStrong ? FontWeight.w700 : FontWeight.w400),
        <Component>[Component.text(position.toString().padLeft(2, '0'))],
      ),
      div(classes: 'leaderboard-table__player leaderboard-row__player', <Component>[
        AppAvatar(nickname: entry.player.nickname, size: AppAvatarSize.row, tone: tone),
        p(
          classes: 'leaderboard-row__name',
          styles: Styles(fontWeight: isStrong ? FontWeight.w600 : FontWeight.w500),
          <Component>[
            span(<Component>[Component.text(entry.player.nickname)]),
            if (isMe) const span(classes: 'leaderboard-row__you', <Component>[Component.text(' · you')]),
          ],
        ),
        if (entry.player.isPro) const ProBadge(tone: ProBadgeTone.amber),
        if (entry.isCalibrating) _CalibratingTag(isMe: isMe),
      ]),
      div(classes: 'leaderboard-table__rank', <Component>[_RankCell(rankCode: entry.rankCode, isStrong: isMe)]),
      span(
        classes: 'leaderboard-table__elo leaderboard-row__mono',
        styles: Styles(
          color: isMe ? AppColors.primary : AppColors.ink,
          fontWeight: isStrong ? FontWeight.w600 : FontWeight.w400,
        ),
        <Component>[Component.text(DisplayFormatters.grouped(entry.rating))],
      ),
    ]);
  }
}

/// Rank column: the league emblem and the rank name. An unknown rank code
/// shows the name only.
final class _RankCell extends StatelessComponent {
  const _RankCell({required this.rankCode, required this.isStrong});

  final String rankCode;
  final bool isStrong;

  @override
  Component build(BuildContext context) {
    final LeagueRank? league = LeagueRank.tryParse(rankCode);
    return div(classes: 'leaderboard-rank', <Component>[
      if (league != null) LeagueEmblem(rank: league, size: 32),
      span(
        classes: 'leaderboard-rank__name',
        styles: isStrong ? const Styles(fontWeight: FontWeight.w600) : null,
        <Component>[Component.text(formatRankCode(rankCode))],
      ),
    ]);
  }
}

/// The outlined "CALIBRATING" chip; blue on the own row.
final class _CalibratingTag extends StatelessComponent {
  const _CalibratingTag({required this.isMe});

  final bool isMe;

  @override
  Component build(BuildContext context) {
    return span(
      classes: isMe ? 'leaderboard-calibrating leaderboard-calibrating--me' : 'leaderboard-calibrating',
      <Component>[const Component.text('CALIBRATING')],
    );
  }
}

@css
List<StyleRule> get leaderboardTableStyles => <StyleRule>[
  css('.leaderboard-table').styles(display: Display.flex, flexDirection: FlexDirection.column),
  css('.leaderboard-table__header')
      .styles(
        display: Display.flex,
        padding: const Padding.only(left: Unit.pixels(16), right: Unit.pixels(16), bottom: Unit.pixels(12)),
        border: const Border.only(
          bottom: BorderSide(color: AppColors.border, width: Unit.pixels(1)),
        ),
        alignItems: AlignItems.center,
        gap: const Gap.column(Unit.pixels(16)),
      )
      .combine(AppTextStyles.bodyXs)
      .combine(const Styles(color: AppColors.muted, fontWeight: FontWeight.w500)),
  css('.leaderboard-table__position').styles(
    width: const Unit.pixels(_Columns.position),
    flex: const Flex(shrink: 0),
  ),
  css('.leaderboard-table__player').styles(
    minWidth: Unit.zero,
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.leaderboard-table__rank').styles(width: const Unit.pixels(_Columns.rank), flex: const Flex(shrink: 0)),
  css('.leaderboard-table__elo').styles(
    width: const Unit.pixels(_Columns.elo),
    flex: const Flex(shrink: 0),
    textAlign: TextAlign.right,
  ),
  css('.leaderboard-table__empty')
      .styles(padding: const Padding.symmetric(vertical: Unit.pixels(40)))
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(color: AppColors.muted, textAlign: TextAlign.center)),
  css('.leaderboard-table__gap')
      .styles(padding: const Padding.symmetric(vertical: Unit.pixels(10)))
      .combine(AppTextStyles.monoBodyMd)
      .combine(
        const Styles(
          color: AppColors.faint,
          textAlign: TextAlign.center,
          fontWeight: FontWeight.w400,
          letterSpacing: Unit.em(0.3),
          lineHeight: Unit.pixels(16),
        ),
      ),
  css('.leaderboard-row').styles(
    display: Display.flex,
    padding: const Padding.symmetric(horizontal: Unit.pixels(16), vertical: Unit.pixels(14)),
    border: const Border.only(
      bottom: BorderSide(color: AppColors.divider, width: Unit.pixels(1)),
    ),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(16)),
  ),
  css('.leaderboard-row--me').styles(
    border: Border.all(color: AppColors.primary, width: const Unit.pixels(1.5)),
    radius: const BorderRadius.circular(Unit.pixels(12)),
    backgroundColor: AppColors.primarySurface,
  ),
  css('.leaderboard-row__mono')
      .combine(AppTextStyles.monoBodyMd)
      .combine(const Styles(fontSize: Unit.pixels(16), lineHeight: Unit.pixels(20))),
  css('.leaderboard-row__player').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(12)),
  ),
  css('.leaderboard-row__name')
      .styles(
        minWidth: Unit.zero,
        overflow: Overflow.hidden,
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.bodyLg),
  css('.leaderboard-row__you').styles(color: AppColors.muted, fontWeight: FontWeight.w400),
  css('.leaderboard-rank').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(10)),
  ),
  css('.leaderboard-rank__name')
      .styles(
        minWidth: Unit.zero,
        overflow: Overflow.hidden,
        flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.bodyMd),
  css('.leaderboard-calibrating')
      .styles(
        padding: const Padding.symmetric(horizontal: Unit.pixels(6), vertical: Unit.pixels(2)),
        border: Border.all(color: AppColors.borderStrong, width: const Unit.pixels(1)),
        radius: const BorderRadius.circular(Unit.pixels(4)),
        flex: const Flex(shrink: 0),
      )
      .combine(AppTextStyles.monoCaption)
      .combine(
        const Styles(
          color: AppColors.muted,
          fontSize: Unit.pixels(10),
          fontWeight: FontWeight.w600,
          letterSpacing: Unit.em(0.04),
          lineHeight: Unit.pixels(12),
        ),
      ),
  css('.leaderboard-calibrating--me').styles(
    border: Border.all(color: AppColors.primaryRing, width: const Unit.pixels(1)),
    color: AppColors.primary,
  ),
];
