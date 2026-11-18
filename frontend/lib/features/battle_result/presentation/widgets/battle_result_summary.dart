import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

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
import 'package:skill_battles/core/presentation/markdown/math_fit_width.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_notice.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tag.dart';
import 'package:skill_battles/core/presentation/widgets/battle_outcome_text.dart';
import 'package:skill_battles/core/presentation/widgets/pro_badge.dart';
import 'package:skill_battles/features/battle_result/presentation/widgets/rematch_panel.dart';

/// Left column of the result: outcome, score, saved rating change, actions.
final class BattleResultSummary extends StatelessComponent {
  const BattleResultSummary({
    required this.result,
    required this.disciplineName,
    super.key,
  });

  final BattleResultEntity result;
  final String disciplineName;

  @override
  Component build(BuildContext context) {
    final ResultPlayerEntity me = result.me;
    final ResultPlayerEntity opponent = result.opponent;
    final bool wonOnFewerPoints =
        result.isForfeit && result.myOutcome == BattleOutcome.win && me.score < opponent.score;
    return div(classes: 'result-summary', <Component>[
      _Headline(result: result, disciplineName: disciplineName),
      if (wonOnFewerPoints)
        const AppNotice(
          message:
              'A forfeit decides the winner, so the points stay exactly as '
              'played.',
        ),
      _ScoreRow(me: me, opponent: opponent),
      if (result.mode == BattleMode.ranked)
        _RatingRow(result: result, me: me, disciplineName: disciplineName)
      else
        _PrivateNote(result: result),
      if (result.mode == BattleMode.private)
        RematchPanel(
          myUserId: result.myUserId,
          opponentNickname: opponent.nickname,
          disciplineCode: result.disciplineCode,
        )
      else
        _Actions(result: result),
    ]);
  }
}

final class _Headline extends StatelessComponent {
  const _Headline({required this.result, required this.disciplineName});

  final BattleResultEntity result;
  final String disciplineName;

  @override
  Component build(BuildContext context) {
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
    return div(classes: 'result-summary__headline', <Component>[
      AppEyebrow('$disciplineName · ${result.mode.label} · $reason'),
      // Scaled down, never wrapped, when the column is narrower than the
      // 104 px word.
      MathFitWidth(
        child: h1(
          classes: 'result-summary__title',
          styles: Styles(color: color),
          <Component>[Component.text(title)],
        ),
      ),
    ]);
  }
}

final class _ScoreRow extends StatelessComponent {
  const _ScoreRow({required this.me, required this.opponent});

  final ResultPlayerEntity me;
  final ResultPlayerEntity opponent;

  @override
  Component build(BuildContext context) {
    return div(classes: 'result-summary__scores', <Component>[
      _PlayerScore(player: me, label: '${me.nickname} (you)', color: AppColors.ink),
      const span(classes: 'result-summary__vs', <Component>[Component.text('vs')]),
      _PlayerScore(player: opponent, label: opponent.nickname, color: AppColors.faint),
    ]);
  }
}

final class _PlayerScore extends StatelessComponent {
  const _PlayerScore({
    required this.player,
    required this.label,
    required this.color,
  });

  final ResultPlayerEntity player;
  final String label;
  final Color color;

  @override
  Component build(BuildContext context) {
    return div(classes: 'result-summary__player', <Component>[
      div(classes: 'result-summary__player-name', <Component>[
        span(classes: 'result-summary__player-label', <Component>[Component.text(label)]),
        if (player.isPro) const ProBadge(compact: true),
      ]),
      span(
        classes: 'result-summary__score',
        styles: Styles(color: color),
        <Component>[Component.text(DisplayFormatters.grouped(player.score))],
      ),
    ]);
  }
}

final class _RatingRow extends StatelessComponent {
  const _RatingRow({
    required this.result,
    required this.me,
    required this.disciplineName,
  });

  final BattleResultEntity result;
  final ResultPlayerEntity me;
  final String disciplineName;

  @override
  Component build(BuildContext context) {
    final bool ranked = me.kFactor > 0;
    final int delta = me.ratingDelta;
    final int calibration = me.calibrationMatchesRemaining;
    final String? note = calibration > 0
        ? 'Calibration ×2 Elo · $calibration '
              '${calibration == 1 ? 'match' : 'matches'} left'
        : null;
    return div(classes: 'result-summary__rating', <Component>[
      div(classes: 'result-summary__rating-row', <Component>[
        div(classes: 'result-summary__rating-main', <Component>[
          span(classes: 'result-summary__muted-label', <Component>[Component.text('$disciplineName rating')]),
          MathFitWidth(
            child: span(classes: 'result-summary__rating-values', <Component>[
              span(
                classes: 'result-summary__rating-value',
                styles: Styles(
                  color: ranked ? AppColors.faint : AppColors.ink,
                  fontWeight: FontWeight.w500,
                ),
                <Component>[Component.text('${me.ratingBefore}')],
              ),
              if (ranked) ...<Component>[
                const AppSvgIcon(AppIcons.arrowLong, width: 20, height: 12),
                span(classes: 'result-summary__rating-value', <Component>[Component.text('${me.ratingAfter}')]),
                AppTag(
                  label: RatingDeltaText.format(delta),
                  tone: switch (delta) {
                    > 0 => AppTagTone.success,
                    < 0 => AppTagTone.danger,
                    _ => AppTagTone.neutral,
                  },
                  padding: const Padding.symmetric(horizontal: Unit.pixels(8), vertical: Unit.pixels(3)),
                  style: AppTextStyles.monoBodyLg,
                ),
              ],
            ]),
          ),
        ]),
        AppTag(
          label: formatRankCode(me.rankAfter),
          isPill: true,
          padding: const Padding.symmetric(horizontal: Unit.pixels(12), vertical: Unit.pixels(6)),
        ),
      ]),
      if (result.overtimePlayed) _TieBreakLine(result: result),
      if (note != null) p(classes: 'result-summary__calibration', <Component>[Component.text(note)]),
    ]);
  }
}

final class _Actions extends StatelessComponent {
  const _Actions({required this.result});

  final BattleResultEntity result;

  @override
  Component build(BuildContext context) {
    return div(classes: 'result-summary__actions', <Component>[
      AppButton(
        label: 'Play again',
        onPressed: () => context.goRankedSearch(disciplineCode: result.disciplineCode),
      ),
      AppButton(
        label: 'Back to home',
        variant: AppButtonVariant.outline,
        onPressed: context.goHome,
      ),
    ]);
  }
}

/// Private duel: the overtime outcome and that ratings stay as they were
/// (Paper: "18 Result — Private, Overtime, Rematch").
final class _PrivateNote extends StatelessComponent {
  const _PrivateNote({required this.result});

  final BattleResultEntity result;

  @override
  Component build(BuildContext context) {
    return div(classes: 'result-summary__private', <Component>[
      if (result.overtimePlayed) _TieBreakLine(result: result),
      const p(classes: 'result-summary__private-note', <Component>[
        Component.text("Private duel · ratings don't change"),
      ]),
    ]);
  }
}

/// "+1 TIE-BREAK  Won the sudden-death round in overtime."
final class _TieBreakLine extends StatelessComponent {
  const _TieBreakLine({required this.result});

  final BattleResultEntity result;

  @override
  Component build(BuildContext context) {
    final bool won = result.myOutcome == BattleOutcome.win;
    final String text = switch (result.myOutcome) {
      BattleOutcome.win => 'You won the sudden-death round in overtime.',
      BattleOutcome.loss => 'Your opponent won the sudden-death round.',
      _ => 'Overtime could not break the tie.',
    };
    return div(classes: 'result-summary__tie-break', <Component>[
      if (won)
        const AppTag(
          label: '+1 TIE-BREAK',
          tone: AppTagTone.accent,
          padding: Padding.symmetric(horizontal: Unit.pixels(8), vertical: Unit.pixels(3)),
          style: AppTextStyles.outcome,
        ),
      p(classes: 'result-summary__tie-break-text', <Component>[Component.text(text)]),
    ]);
  }
}

@css
List<StyleRule> get battleResultSummaryStyles => <StyleRule>[
  css('.result-summary').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(36)),
  ),
  css('.result-summary__headline').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(12)),
  ),
  css('.result-summary__headline > .math-fit-width').styles(width: const Unit.percent(100)),
  css('.result-summary__title').combine(AppTextStyles.displayXl),
  css('.result-summary__scores').styles(
    display: Display.flex,
    padding: const Padding.symmetric(vertical: Unit.pixels(24)),
    border: const Border.symmetric(
      horizontal: BorderSide(color: AppColors.border, width: Unit.pixels(1)),
    ),
    alignItems: AlignItems.end,
    gap: const Gap.column(Unit.pixels(28)),
  ),
  css('.result-summary__vs')
      .styles(
        padding: const Padding.only(bottom: Unit.pixels(10)),
        flex: const Flex(shrink: 0),
      )
      .combine(AppTextStyles.titleMd)
      .combine(const Styles(color: AppColors.faint, fontWeight: FontWeight.w400)),
  css('.result-summary__player').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(6)),
    flex: const Flex(grow: 0, shrink: 1, basis: Unit.auto),
  ),
  css('.result-summary__player-name').styles(
    display: Display.flex,
    maxWidth: const Unit.percent(100),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(6)),
  ),
  css('.result-summary__player-label')
      .styles(
        minWidth: Unit.zero,
        overflow: Overflow.hidden,
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.muted, fontWeight: FontWeight.w500)),
  css('.result-summary__score')
      .styles(whiteSpace: WhiteSpace.noWrap)
      .combine(AppTextStyles.monoXl)
      .combine(const Styles(fontWeight: FontWeight.w600)),
  css('.result-summary__rating').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(8)),
  ),
  css('.result-summary__rating-row').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(20)),
  ),
  css('.result-summary__rating-main').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(4)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.result-summary__rating-main > .math-fit-width').styles(width: const Unit.percent(100)),
  css('.result-summary__muted-label')
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.muted, fontWeight: FontWeight.w500)),
  css('.result-summary__rating-values').styles(
    display: Display.inlineFlex,
    alignItems: AlignItems.baseline,
    gap: const Gap.column(Unit.pixels(12)),
  ),
  css('.result-summary__rating-value').combine(AppTextStyles.monoMd),
  css('.result-summary__calibration').combine(AppTextStyles.bodyXs).combine(const Styles(color: AppColors.muted)),
  css('.result-summary__actions').styles(
    display: Display.flex,
    flexWrap: FlexWrap.wrap,
    gap: const Gap.all(Unit.pixels(12)),
  ),
  css('.result-summary__private').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(8)),
  ),
  css('.result-summary__private-note')
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.muted, lineHeight: Unit.pixels(18))),
  css('.result-summary__tie-break').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(10)),
  ),
  css('.result-summary__tie-break-text')
      .styles(
        minWidth: Unit.zero,
        flex: const Flex(grow: 0, shrink: 1, basis: Unit.auto),
      )
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(lineHeight: Unit.pixels(20))),
];
