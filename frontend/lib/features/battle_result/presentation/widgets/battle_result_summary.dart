import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/battle_mode.dart';
import 'package:skill_battles/core/domain/entity/battle_outcome.dart';
import 'package:skill_battles/core/domain/entity/battle_result_entity.dart';
import 'package:skill_battles/core/domain/entity/result_player_entity.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_notice.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tag.dart';
import 'package:skill_battles/core/presentation/widgets/battle_outcome_text.dart';
import 'package:skill_battles/core/presentation/widgets/pro_badge.dart';
import 'package:skill_battles/features/battle_result/presentation/widgets/rematch_panel.dart';

/// Left column of the result: outcome, score, saved rating change, actions.
final class BattleResultSummary extends StatelessWidget {
  const BattleResultSummary({
    required this.result,
    required this.disciplineName,
    super.key,
  });

  final BattleResultEntity result;
  final String disciplineName;

  @override
  Widget build(BuildContext context) {
    final ResultPlayerEntity me = result.me;
    final ResultPlayerEntity opponent = result.opponent;
    final bool wonOnFewerPoints =
        result.isForfeit &&
        result.myOutcome == BattleOutcome.win &&
        me.score < opponent.score;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 32,
      children: <Widget>[
        _Headline(result: result, disciplineName: disciplineName),
        if (wonOnFewerPoints)
          const AppNotice(
            message:
                'A forfeit decides the winner, so the points stay exactly as '
                'played.',
          ),
        _ScoreRow(me: me, opponent: opponent),
        _RatingRow(result: result, me: me, disciplineName: disciplineName),
        if (result.mode == BattleMode.private)
          RematchPanel(
            myUserId: result.myUserId,
            opponentNickname: opponent.nickname,
          ),
        _Actions(result: result),
      ],
    );
  }
}

final class _Headline extends StatelessWidget {
  const _Headline({required this.result, required this.disciplineName});

  final BattleResultEntity result;
  final String disciplineName;

  @override
  Widget build(BuildContext context) {
    final String title = switch (result.myOutcome) {
      BattleOutcome.win => 'Victory.',
      BattleOutcome.loss => 'Defeat.',
      BattleOutcome.draw => 'Draw.',
      BattleOutcome.cancelled => 'Cancelled.',
    };
    final Color color = switch (result.myOutcome) {
      BattleOutcome.win => AppColors.primary,
      BattleOutcome.loss => AppColors.ink,
      BattleOutcome.draw || BattleOutcome.cancelled => AppColors.muted,
    };
    final String reason = result.reason.describe(
      iWon: result.myOutcome == BattleOutcome.win,
      isDraw: result.myOutcome == BattleOutcome.draw,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: <Widget>[
        AppEyebrow('$disciplineName · ${result.mode.label} · $reason'),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: AppTextStyles.displayXl.copyWith(color: color),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            if (result.overtimePlayed)
              const AppTag(label: 'Overtime played', tone: AppTagTone.neutral),
            AppTag(
              label: DisplayFormatters.dateTime(result.finishedAt),
              tone: AppTagTone.neutral,
            ),
          ],
        ),
      ],
    );
  }
}

final class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.me, required this.opponent});

  final ResultPlayerEntity me;
  final ResultPlayerEntity opponent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.border),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 28,
          children: <Widget>[
            Flexible(
              child: _PlayerScore(
                player: me,
                label: '${me.nickname} (you)',
                color: AppColors.ink,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'vs',
                style: AppTextStyles.titleMd.copyWith(
                  fontWeight: FontWeight.w400,
                  color: AppColors.faint,
                ),
              ),
            ),
            Flexible(
              child: _PlayerScore(
                player: opponent,
                label: opponent.nickname,
                color: AppColors.faint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _PlayerScore extends StatelessWidget {
  const _PlayerScore({
    required this.player,
    required this.label,
    required this.color,
  });

  final ResultPlayerEntity player;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: <Widget>[
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.bodySm.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (player.isPro) const ProBadge(compact: true),
          ],
        ),
        Text(
          '${player.score}',
          style: AppTextStyles.monoXl.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          '${player.correctCount} correct',
          style: AppTextStyles.bodyXs.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

final class _RatingRow extends StatelessWidget {
  const _RatingRow({
    required this.result,
    required this.me,
    required this.disciplineName,
  });

  final BattleResultEntity result;
  final ResultPlayerEntity me;
  final String disciplineName;

  @override
  Widget build(BuildContext context) {
    final bool ranked = result.mode == BattleMode.ranked && me.kFactor > 0;
    final int delta = me.ratingDelta;
    final String? season = result.seasonId;
    final String kLine = !ranked
        ? 'Private duels never change your rating.'
        : <String>[
            'K ${me.kFactor}',
            if (me.calibrationMatchesRemaining > 0)
              'Calibration ×2 Elo · ${me.calibrationMatchesRemaining} '
                  '${me.calibrationMatchesRemaining == 1 ? 'match' : 'matches'} left',
            if (season != null) 'Season $season',
          ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: <Widget>[
        Row(
          spacing: 20,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: <Widget>[
                  Text(
                    '$disciplineName rating',
                    style: AppTextStyles.bodySm.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      spacing: 12,
                      children: <Widget>[
                        Text(
                          '${me.ratingBefore}',
                          style: AppTextStyles.monoMd.copyWith(
                            fontWeight: FontWeight.w500,
                            color: ranked ? AppColors.faint : AppColors.ink,
                          ),
                        ),
                        if (ranked) ...<Widget>[
                          const Text.rich(
                            WidgetSpan(
                              alignment: PlaceholderAlignment.aboveBaseline,
                              baseline: TextBaseline.alphabetic,
                              child: AppSvgIcon(
                                AppIcons.arrowLong,
                                width: 20,
                                height: 12,
                              ),
                            ),
                            style: AppTextStyles.monoMd,
                          ),
                          Text(
                            '${me.ratingAfter}',
                            style: AppTextStyles.monoMd,
                          ),
                          AppTag(
                            label: RatingDeltaText.format(delta),
                            tone: switch (delta) {
                              > 0 => AppTagTone.success,
                              < 0 => AppTagTone.danger,
                              _ => AppTagTone.neutral,
                            },
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            style: AppTextStyles.monoBodyLg,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AppTag(
              label: formatRankCode(me.rankAfter),
              isPill: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ],
        ),
        Text(
          kLine,
          style: AppTextStyles.bodyXs.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

final class _Actions extends StatelessWidget {
  const _Actions({required this.result});

  final BattleResultEntity result;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        AppButton(
          label: result.mode == BattleMode.ranked
              ? 'Play ranked again'
              : 'New private duel',
          onPressed: () => result.mode == BattleMode.ranked
              ? context.goRankedSearch(disciplineCode: result.disciplineCode)
              : context.goPrivateDuel(disciplineCode: result.disciplineCode),
        ),
        AppButton(
          label: 'Back to home',
          variant: AppButtonVariant.outline,
          onPressed: context.goHome,
        ),
      ],
    );
  }
}
