import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/router/app_routes.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/user_entity.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/widgets/app_avatar.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_card.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_locked_panel.dart';
import 'package:skill_battles/core/presentation/widgets/app_progress_bar.dart';
import 'package:skill_battles/core/presentation/widgets/app_stat.dart';
import 'package:skill_battles/core/presentation/widgets/app_tag.dart';
import 'package:skill_battles/core/presentation/widgets/pro_badge.dart';
import 'package:skill_battles/features/account/domain/entity/discipline_stats_entity.dart';
import 'package:skill_battles/features/account/domain/entity/match_stats_entity.dart';
import 'package:skill_battles/features/account/domain/entity/season_peak_entity.dart';
import 'package:skill_battles/features/account/domain/entity/streaks_entity.dart';
import 'package:skill_battles/features/account/domain/entity/topic_stats_entity.dart';
import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';
import 'package:skill_battles/features/catalog/domain/entity/rank_ladder_entity.dart';
import 'package:skill_battles/features/catalog/presentation/extensions/catalog_labels.dart';
import 'package:skill_battles/features/profile/presentation/widgets/rating_history_chart.dart';

/// Avatar, nickname, badge and the edit action.
final class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.user,
    required this.matchCount,
    super.key,
  });

  final UserEntity? user;
  final int matchCount;

  @override
  Widget build(BuildContext context) {
    final UserEntity? user = this.user;
    final String nickname = user?.nickname ?? BoneMock.name;
    return Row(
      spacing: 20,
      children: <Widget>[
        AppAvatar(nickname: nickname, size: AppAvatarSize.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: <Widget>[
              Row(
                spacing: 10,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      nickname,
                      style: AppTextStyles.displaySm,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (user?.isPro ?? false) const ProBadge(),
                ],
              ),
              Text(
                user == null
                    ? BoneMock.words(5)
                    : 'Playing since ${DisplayFormatters.monthYear(user.createdAt)} '
                          '· $matchCount matches',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
        Skeleton.ignore(
          child: AppButton(
            label: 'Edit profile',
            variant: AppButtonVariant.outline,
            size: AppButtonSize.small,
            onPressed: () => context.goNamed(AppRoutes.editProfile.name),
          ),
        ),
      ],
    );
  }
}

/// Rating, rank, peaks and calibration of the selected discipline.
final class ProfileRatingPanel extends StatelessWidget {
  const ProfileRatingPanel({
    required this.stats,
    required this.ranks,
    super.key,
  });

  final DisciplineStatsEntity stats;
  final RankLadderEntity? ranks;

  @override
  Widget build(BuildContext context) {
    final double? fraction = stats.rank.fraction;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 40,
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: <Widget>[
                const AppEyebrow('Current rating'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: 14,
                  children: <Widget>[
                    Text('${stats.rating}', style: AppTextStyles.monoXl),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        stats.rank.rankName,
                        style: AppTextStyles.titleMd,
                      ),
                    ),
                  ],
                ),
                AppProgressBar(fraction: fraction ?? 1),
                Text(
                  stats.rank.divisionRpTarget == null
                      ? '${stats.rank.divisionRpCurrent} RP above ${stats.rank.rankName}'
                      : '${stats.rank.divisionRpCurrent} / '
                            '${stats.rank.divisionRpTarget} RP in this division',
                  style: AppTextStyles.monoBodySm.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    AppTag(
                      label: stats.calibration.isCalibrating
                          ? 'Calibration ×2 Elo · '
                                '${stats.calibration.matchesRemaining} left'
                          : 'Calibrated · K ${stats.calibration.nextKFactor}',
                      tone: AppTagTone.neutral,
                    ),
                    if (stats.seasonRolloverPending)
                      const AppTag(
                        label: 'Season reset pending',
                        tone: AppTagTone.danger,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 18,
              children: <Widget>[
                AppStat(
                  value: '${stats.seasonPeakRating}',
                  label:
                      'Season peak · ${ranks.nameOf(stats.seasonPeakRankCode)} · '
                      '${stats.seasonId}',
                ),
                AppStat(
                  value: '${stats.allTimePeakRating}',
                  label:
                      'All-time peak · ${ranks.nameOf(stats.allTimePeakRankCode)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Basic statistics over the whole history — available on every plan.
final class ProfileMatchStats extends StatelessWidget {
  const ProfileMatchStats({
    required this.stats,
    required this.streaks,
    super.key,
  });

  final DisciplineStatsEntity stats;
  final StreaksEntity streaks;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 20,
      children: <Widget>[
        Expanded(
          child: _StatsCard(title: 'Ranked', stats: stats.ranked),
        ),
        Expanded(
          child: _StatsCard(
            title: 'Private duels',
            stats: stats.privateMatches,
          ),
        ),
        Expanded(child: _StreaksCard(streaks: streaks)),
      ],
    );
  }
}

final class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.title, required this.stats});

  final String title;
  final MatchStatsEntity stats;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: <Widget>[
          Text(title, style: AppTextStyles.buttonLg),
          Text(
            '${stats.wins}W · ${stats.losses}L · ${stats.draws}D · '
            '${stats.played} played',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
          ),
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: <Widget>[
              AppStat(
                value: DisplayFormatters.percent(stats.winRatePercent),
                label: 'Win rate',
              ),
              AppStat(
                value: DisplayFormatters.percent(stats.accuracyPercent),
                label: 'Accuracy · ${stats.questionCount} q',
              ),
              AppStat(
                value: DisplayFormatters.seconds(stats.avgAnswerTime),
                label: 'Avg answer',
              ),
              AppStat(
                value: '${stats.currentWinStreak} / ${stats.bestWinStreak}',
                label: 'Win streak / best',
                valueColor: AppColors.accentText,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _StreaksCard extends StatelessWidget {
  const _StreaksCard({required this.streaks});

  final StreaksEntity streaks;

  @override
  Widget build(BuildContext context) {
    final DateTime? last = streaks.lastQualifiedDate;
    return AppCard(
      padding: const EdgeInsets.all(20),
      color: AppColors.accentSurface,
      borderColor: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: <Widget>[
          Text(
            'Daily & weekly streaks',
            style: AppTextStyles.buttonLg.copyWith(color: AppColors.accentInk),
          ),
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: <Widget>[
              AppStat(
                value: '${streaks.dailyCurrent} / ${streaks.dailyBest}',
                label: 'Days / best',
                valueColor: AppColors.accentText,
              ),
              AppStat(
                value: '${streaks.weeklyCurrent} / ${streaks.weeklyBest}',
                label: 'Weeks / best',
                valueColor: AppColors.accentText,
              ),
              AppStat(
                value:
                    '${streaks.currentWeekActiveDays}/${streaks.currentWeekTarget}',
                label: 'Days this week',
                valueColor: AppColors.accentText,
              ),
            ],
          ),
          Text(
            last == null
                ? 'Finish a match to start a streak. Days follow US Eastern time.'
                : 'Last counted day: ${DisplayFormatters.date(last)} (ET).',
            style: AppTextStyles.bodyXs.copyWith(color: AppColors.accentInk),
          ),
        ],
      ),
    );
  }
}

/// Pro topic analytics and rating graph. `null` values mean the plan does
/// not include them — not that there is no progress.
final class ProfileAnalyticsSection extends StatelessWidget {
  const ProfileAnalyticsSection({required this.stats, super.key});

  final DisciplineStatsEntity stats;

  @override
  Widget build(BuildContext context) {
    final List<TopicStatsEntity>? topics = stats.topicStats;
    final List<dynamic>? history = stats.ratingHistory;
    if (topics == null || history == null) {
      return AppLockedPanel(
        title: 'Topic analytics and rating graph',
        message:
            'See accuracy and speed per topic, your weak spots and a graph of '
            'your last 30 ranked results. Your basic statistics above count '
            'every match.',
        onUpgrade: context.goPro,
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 20,
      children: <Widget>[
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: <Widget>[
                const Row(
                  spacing: 8,
                  children: <Widget>[
                    Text('Topics', style: AppTextStyles.buttonLg),
                    ProBadge(compact: true),
                  ],
                ),
                if (topics.isEmpty)
                  Text(
                    'No topics yet.',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                for (final TopicStatsEntity topic in topics)
                  _TopicRow(
                    key: ValueKey<String>(topic.topicCode),
                    topic: topic,
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: <Widget>[
                const Row(
                  spacing: 8,
                  children: <Widget>[
                    Text(
                      'Rating, last ranked matches',
                      style: AppTextStyles.buttonLg,
                    ),
                    ProBadge(compact: true),
                  ],
                ),
                RatingHistoryChart(points: stats.ratingHistory!),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

final class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.topic, super.key});

  final TopicStatsEntity topic;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: <Widget>[
        Row(
          spacing: 8,
          children: <Widget>[
            Expanded(
              child: Text(
                topic.topicName,
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (topic.isWeakTopic)
              AppTag(
                label: 'Weak spot',
                tone: AppTagTone.danger,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                style: AppTextStyles.bodyXs.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            Text(
              '${DisplayFormatters.percent(topic.accuracyPercent)} · '
              '${topic.correctCount}/${topic.questionCount} · '
              '${DisplayFormatters.seconds(topic.avgAnswerTime)}',
              style: AppTextStyles.monoBodySm.copyWith(color: AppColors.muted),
            ),
          ],
        ),
        AppProgressBar(
          fraction: topic.accuracyPercent / 100,
          color: topic.isWeakTopic ? AppColors.danger : AppColors.success,
          height: 4,
        ),
      ],
    );
  }
}

/// Final and peak ratings of completed seasons (every plan).
final class ProfileSeasonsSection extends StatelessWidget {
  const ProfileSeasonsSection({
    required this.seasons,
    required this.disciplines,
    required this.ranks,
    super.key,
  });

  final List<SeasonPeakEntity> seasons;
  final List<DisciplineEntity> disciplines;
  final RankLadderEntity? ranks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: <Widget>[
        const Text('Past seasons', style: AppTextStyles.titleLg),
        if (seasons.isEmpty)
          Text(
            'No completed seasons yet. Seasons run Sep–Dec, Dec–Mar, Mar–Jun '
            'and Jun–Sep (US Eastern); each starts with a soft reset toward '
            '1000.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
          )
        else
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              for (final SeasonPeakEntity peak in seasons)
                SizedBox(
                  width: 260,
                  child: AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: <Widget>[
                        Text(peak.season.name, style: AppTextStyles.buttonLg),
                        Text(
                          disciplines.nameOf(peak.disciplineCode),
                          style: AppTextStyles.bodyXs.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                        Row(
                          spacing: 24,
                          children: <Widget>[
                            AppStat(
                              value: '${peak.peakRating}',
                              label:
                                  'Peak · ${ranks.nameOf(peak.peakRankCode)}',
                            ),
                            AppStat(
                              value: '${peak.finalRating}',
                              label: 'Final',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
