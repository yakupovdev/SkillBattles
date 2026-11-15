import 'package:material_ui/material_ui.dart';

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
final class LeaderboardTable extends StatelessWidget {
  const LeaderboardTable({required this.board, super.key});

  final LeaderboardEntity board;

  @override
  Widget build(BuildContext context) {
    final LeaderboardEntryEntity? me = board.me;
    final bool meInTop =
        me != null &&
        board.top.any(
          (LeaderboardEntryEntity e) => e.player.id == me.player.id,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _Header(),
        if (board.top.isEmpty) const _Empty(),
        for (final LeaderboardEntryEntity entry in board.top)
          _Row(
            key: ValueKey<String>(entry.player.id),
            entry: entry,
            isMe: entry.player.id == me?.player.id,
          ),
        if (me != null && !meInTop) ...<Widget>[
          if (board.top.isNotEmpty) const _Gap(),
          _Row(entry: me, isMe: true),
        ],
      ],
    );
  }
}

final class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTextStyles.bodyXs.copyWith(
      fontWeight: FontWeight.w500,
      color: AppColors.muted,
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          spacing: 16,
          children: <Widget>[
            SizedBox(
              width: _Columns.position,
              child: Text('#', style: style),
            ),
            Expanded(child: Text('Player', style: style)),
            SizedBox(
              width: _Columns.rank,
              child: Text('Rank', style: style),
            ),
            SizedBox(
              width: _Columns.elo,
              child: Text('Elo', style: style, textAlign: TextAlign.right),
            ),
          ],
        ),
      ),
    );
  }
}

final class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Text(
        'No ratings yet. Play a ranked match to open the season.',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyMd.copyWith(color: AppColors.muted),
      ),
    );
  }
}

final class _Gap extends StatelessWidget {
  const _Gap();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        '· · ·',
        textAlign: TextAlign.center,
        style: AppTextStyles.monoBodyMd.copyWith(
          fontWeight: FontWeight.w400,
          height: 16 / 14,
          letterSpacing: 0.3 * 14,
          color: AppColors.faint,
        ),
      ),
    );
  }
}

final class _Row extends StatelessWidget {
  const _Row({required this.entry, required this.isMe, super.key});

  final LeaderboardEntryEntity entry;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
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
    final TextStyle mono = AppTextStyles.monoBodyMd.copyWith(
      fontSize: 16,
      height: 20 / 16,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: isMe
          ? BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary, width: 1.5),
            )
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
      child: Row(
        spacing: 16,
        children: <Widget>[
          SizedBox(
            width: _Columns.position,
            child: Text(
              position.toString().padLeft(2, '0'),
              style: mono.copyWith(
                fontWeight: isStrong ? FontWeight.w700 : FontWeight.w400,
                color: positionColor,
              ),
            ),
          ),
          Expanded(
            child: Row(
              spacing: 12,
              children: <Widget>[
                AppAvatar(
                  nickname: entry.player.nickname,
                  size: AppAvatarSize.row,
                  tone: tone,
                ),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      text: entry.player.nickname,
                      children: <InlineSpan>[
                        if (isMe)
                          const TextSpan(
                            text: ' · you',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                    style: AppTextStyles.bodyLg.copyWith(
                      fontWeight: isStrong ? FontWeight.w600 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (entry.player.isPro)
                  const ProBadge(tone: ProBadgeTone.amber),
                if (entry.isCalibrating) _CalibratingTag(isMe: isMe),
              ],
            ),
          ),
          SizedBox(
            width: _Columns.rank,
            child: _RankCell(rankCode: entry.rankCode, isStrong: isMe),
          ),
          SizedBox(
            width: _Columns.elo,
            child: Text(
              DisplayFormatters.grouped(entry.rating),
              style: mono.copyWith(
                fontWeight: isStrong ? FontWeight.w600 : FontWeight.w400,
                color: isMe ? AppColors.primary : AppColors.ink,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rank column: the league emblem and the rank name. An unknown rank code
/// shows the name only.
final class _RankCell extends StatelessWidget {
  const _RankCell({required this.rankCode, required this.isStrong});

  final String rankCode;
  final bool isStrong;

  @override
  Widget build(BuildContext context) {
    final LeagueRank? league = LeagueRank.tryParse(rankCode);
    return Row(
      spacing: 10,
      children: <Widget>[
        if (league != null) LeagueEmblem(rank: league, size: 32),
        Expanded(
          child: Text(
            formatRankCode(rankCode),
            style: AppTextStyles.bodyMd.copyWith(
              fontWeight: isStrong ? FontWeight.w600 : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// The outlined "CALIBRATING" chip; blue on the own row.
final class _CalibratingTag extends StatelessWidget {
  const _CalibratingTag({required this.isMe});

  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isMe ? AppColors.primaryRing : AppColors.borderStrong,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          'CALIBRATING',
          style: AppTextStyles.monoCaption.copyWith(
            fontSize: 10,
            height: 12 / 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.04 * 10,
            color: isMe ? AppColors.primary : AppColors.muted,
          ),
        ),
      ),
    );
  }
}
