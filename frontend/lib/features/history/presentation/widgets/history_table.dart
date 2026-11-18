import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/battle_mode.dart';
import 'package:skill_battles/core/domain/entity/battle_outcome.dart';
import 'package:skill_battles/core/domain/entity/battle_reason.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_link.dart';
import 'package:skill_battles/core/presentation/widgets/battle_outcome_text.dart';
import 'package:skill_battles/core/presentation/widgets/pro_badge.dart';
import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';
import 'package:skill_battles/features/catalog/presentation/extensions/discipline_short_name.dart';
import 'package:skill_battles/features/history/domain/entity/history_item_entity.dart';
import 'package:skill_battles/features/history/domain/entity/history_page_entity.dart';

/// Column widths of the history table (Paper: "23 History").
abstract final class _Columns {
  static const double result = 72;
  static const double discipline = 150;
  static const double mode = 90;
  static const double score = 150;
  static const double elo = 70;
  static const double date = 110;
  static const double review = 60;
}

/// The history table with its pager. [onPageSelected] receives a page
/// index; `null` disables paging (e.g. while the page is a mock).
final class HistoryTable extends StatelessComponent {
  const HistoryTable({required this.page, required this.disciplines, required this.onPageSelected, super.key});

  final HistoryPageEntity page;
  final List<DisciplineEntity> disciplines;
  final ValueChanged<int>? onPageSelected;

  @override
  Component build(BuildContext context) {
    final DateTime now = DateTime.now();
    return div(classes: 'history-table', <Component>[
      div(classes: 'history-table__rows', <Component>[
        const _Header(),
        if (page.items.isEmpty)
          const _Empty()
        else
          for (final HistoryItemEntity match in page.items)
            _Row(
              key: ValueKey<String>(match.battleId),
              match: match,
              disciplineName: disciplines.shortNameOf(match.disciplineCode),
              now: now,
            ),
      ]),
      _Pager(page: page, onPageSelected: onPageSelected),
    ]);
  }
}

final class _Header extends StatelessComponent {
  const _Header();

  @override
  Component build(BuildContext context) {
    return const div(classes: 'history-table__header', <Component>[
      span(classes: 'history-col--result', <Component>[Component.text('Result')]),
      span(classes: 'history-col--opponent', <Component>[Component.text('Opponent')]),
      span(classes: 'history-col--discipline', <Component>[Component.text('Discipline')]),
      span(classes: 'history-col--mode', <Component>[Component.text('Mode')]),
      span(classes: 'history-col--score history-col--end', <Component>[Component.text('Score')]),
      span(classes: 'history-col--elo history-col--end', <Component>[Component.text('Elo')]),
      span(classes: 'history-col--date history-col--end', <Component>[Component.text('Date')]),
      span(classes: 'history-col--review', <Component>[]),
    ]);
  }
}

final class _Empty extends StatelessComponent {
  const _Empty();

  @override
  Component build(BuildContext context) {
    return const p(classes: 'history-table__empty', <Component>[Component.text('No matches here yet.')]);
  }
}

final class _Row extends StatelessComponent {
  const _Row({required this.match, required this.disciplineName, required this.now, super.key});

  final HistoryItemEntity match;
  final String disciplineName;
  final DateTime now;

  bool get _isCancelled => match.outcome == BattleOutcome.cancelled;

  /// Why the match ended, after the opponent's name; `null` for a plain
  /// finish (overtime is already marked in the result column).
  String? get _note {
    final bool iWon = match.outcome == BattleOutcome.win;
    final bool isDraw = match.outcome == BattleOutcome.draw;
    return switch (match.reason) {
      BattleReason.normal when !isDraw => null,
      BattleReason.normal when match.overtimePlayed => 'both missed overtime',
      BattleReason.overtimeWin => null,
      BattleReason.quotaExhausted => 'daily limit reached before start',
      _ => match.reason.describe(iWon: iWon, isDraw: isDraw).toLowerCase(),
    };
  }

  @override
  Component build(BuildContext context) {
    final bool cancelled = _isCancelled;
    final String? note = _note;
    final bool isRanked = match.mode == BattleMode.ranked;
    return div(classes: 'history-row', <Component>[
      div(classes: 'history-col--result', <Component>[_ResultLabel(match: match)]),
      div(classes: 'history-col--opponent history-row__opponent', <Component>[
        p(
          classes: 'history-row__name',
          styles: Styles(
            color: cancelled ? AppColors.muted : AppColors.ink,
            fontWeight: cancelled ? FontWeight.w500 : FontWeight.w600,
          ),
          <Component>[
            span(<Component>[Component.text(match.opponent.nickname)]),
            if (note != null)
              span(
                classes: 'history-row__note',
                styles: Styles(fontWeight: cancelled ? FontWeight.w500 : FontWeight.w400),
                <Component>[Component.text(' · $note')],
              ),
          ],
        ),
        if (match.opponent.isPro) const ProBadge(tone: ProBadgeTone.amber),
      ]),
      span(
        classes: 'history-col--discipline history-row__cell history-row__ellipsis',
        styles: Styles(color: cancelled ? AppColors.muted : AppColors.ink),
        <Component>[Component.text(disciplineName)],
      ),
      span(classes: 'history-col--mode history-row__cell history-row__muted', <Component>[
        Component.text(match.mode.label),
      ]),
      span(
        classes: 'history-col--score history-col--end history-row__mono',
        styles: Styles(color: cancelled ? AppColors.faint : AppColors.ink),
        <Component>[
          Component.text(
            cancelled
                ? '—'
                : '${DisplayFormatters.grouped(match.myScore)} : '
                      '${DisplayFormatters.grouped(match.opponentScore)}',
          ),
        ],
      ),
      div(classes: 'history-col--elo', <Component>[
        RatingDeltaText(
          delta: isRanked && !cancelled ? match.ratingDelta : null,
          style: AppTextStyles.monoBodyMd.combine(const Styles(fontWeight: FontWeight.w400)),
        ),
      ]),
      span(
        classes: 'history-col--date history-col--end history-row__cell history-row__muted history-row__nowrap',
        <Component>[
          Component.text(DisplayFormatters.matchDate(match.finishedAt, now)),
        ],
      ),
      div(classes: 'history-col--review history-row__review', <Component>[
        if (!cancelled)
          AppTextLink(
            label: 'Review',
            style: AppTextStyles.buttonMd.combine(const Styles(color: AppColors.primary)),
            onPressed: () => context.goBattleResult(match.battleId),
          ),
      ]),
    ]);
  }
}

/// "WIN · OT", "LOSS", "DRAW", "CANCEL" in mono caps.
final class _ResultLabel extends StatelessComponent {
  const _ResultLabel({required this.match});

  final HistoryItemEntity match;

  @override
  Component build(BuildContext context) {
    final (String label, Color color) = switch (match.outcome) {
      BattleOutcome.win => ('WIN', AppColors.success),
      BattleOutcome.loss => ('LOSS', AppColors.danger),
      BattleOutcome.draw => ('DRAW', AppColors.muted),
      BattleOutcome.cancelled => ('CANCEL', AppColors.faint),
    };
    // A drawn overtime is told by the note after the opponent's name.
    final bool overtime =
        match.overtimePlayed && (match.outcome == BattleOutcome.win || match.outcome == BattleOutcome.loss);
    return span(classes: 'history-result', styles: Styles(color: color), <Component>[
      Component.text(overtime ? '$label · OT' : label),
    ]);
  }
}

final class _Pager extends StatelessComponent {
  const _Pager({required this.page, required this.onPageSelected});

  final HistoryPageEntity page;
  final ValueChanged<int>? onPageSelected;

  @override
  Component build(BuildContext context) {
    final int total = page.page.totalElements;
    final int start = page.page.page * page.page.size;
    final int end = start + page.items.length;
    final ValueChanged<int>? onSelected = onPageSelected;
    final int current = page.page.page;
    return div(classes: 'history-pager', <Component>[
      p(classes: 'history-pager__summary', <Component>[
        Component.text(total == 0 ? 'Showing 0 of 0' : 'Showing ${start + 1}–$end of $total'),
      ]),
      div(classes: 'history-pager__buttons', <Component>[
        AppButton(
          label: 'Previous',
          variant: AppButtonVariant.outline,
          size: AppButtonSize.compact,
          onPressed: onSelected != null && page.page.hasPrevious ? () => onSelected(current - 1) : null,
        ),
        AppButton(
          label: 'Next',
          variant: AppButtonVariant.outline,
          size: AppButtonSize.compact,
          onPressed: onSelected != null && page.page.hasNext ? () => onSelected(current + 1) : null,
        ),
      ]),
    ]);
  }
}

@css
List<StyleRule> get historyTableStyles => <StyleRule>[
  css('.history-table').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(24)),
  ),
  css('.history-table__rows').styles(display: Display.flex, flexDirection: FlexDirection.column),
  css('.history-table__header')
      .styles(
        display: Display.flex,
        padding: const Padding.only(bottom: Unit.pixels(12)),
        border: const Border.only(
          bottom: BorderSide(color: AppColors.border, width: Unit.pixels(1)),
        ),
        alignItems: AlignItems.center,
        gap: const Gap.column(Unit.pixels(16)),
      )
      .combine(AppTextStyles.bodyXs)
      .combine(const Styles(color: AppColors.muted, fontWeight: FontWeight.w500)),
  css('.history-col--result').styles(width: const Unit.pixels(_Columns.result), flex: const Flex(shrink: 0)),
  css('.history-col--opponent').styles(
    minWidth: Unit.zero,
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.history-col--discipline').styles(
    width: const Unit.pixels(_Columns.discipline),
    flex: const Flex(shrink: 0),
  ),
  css('.history-col--mode').styles(width: const Unit.pixels(_Columns.mode), flex: const Flex(shrink: 0)),
  css('.history-col--score').styles(width: const Unit.pixels(_Columns.score), flex: const Flex(shrink: 0)),
  css('.history-col--elo').styles(width: const Unit.pixels(_Columns.elo), flex: const Flex(shrink: 0)),
  css('.history-col--date').styles(width: const Unit.pixels(_Columns.date), flex: const Flex(shrink: 0)),
  css('.history-col--review').styles(width: const Unit.pixels(_Columns.review), flex: const Flex(shrink: 0)),
  css('.history-col--end').styles(textAlign: TextAlign.right),
  css('.history-table__empty')
      .styles(padding: const Padding.symmetric(vertical: Unit.pixels(40)))
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(color: AppColors.muted, textAlign: TextAlign.center)),
  css('.history-row').styles(
    display: Display.flex,
    padding: const Padding.symmetric(vertical: Unit.pixels(15)),
    border: const Border.only(
      bottom: BorderSide(color: AppColors.divider, width: Unit.pixels(1)),
    ),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(16)),
  ),
  css('.history-row__opponent').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(8)),
  ),
  css('.history-row__name')
      .styles(
        minWidth: Unit.zero,
        overflow: Overflow.hidden,
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.bodyLg),
  css('.history-row__note').styles(color: AppColors.muted),
  css('.history-row__cell').combine(AppTextStyles.bodyMd),
  css('.history-row__muted').styles(color: AppColors.muted),
  css('.history-row__ellipsis').styles(
    overflow: Overflow.hidden,
    textOverflow: TextOverflow.ellipsis,
    whiteSpace: WhiteSpace.noWrap,
  ),
  css('.history-row__nowrap').styles(overflow: Overflow.hidden, whiteSpace: WhiteSpace.noWrap),
  css('.history-row__mono').combine(AppTextStyles.monoBodyMd).combine(const Styles(fontWeight: FontWeight.w400)),
  css('.history-row__review').styles(display: Display.flex, justifyContent: JustifyContent.end),
  css('.history-result').styles(display: Display.block, whiteSpace: WhiteSpace.noWrap).combine(AppTextStyles.outcome),
  css('.history-pager').styles(
    display: Display.flex,
    justifyContent: JustifyContent.spaceBetween,
    alignItems: AlignItems.center,
  ),
  css('.history-pager__summary').combine(AppTextStyles.bodySm).combine(const Styles(color: AppColors.muted)),
  css('.history-pager__buttons').styles(display: Display.flex, gap: const Gap.column(Unit.pixels(8))),
];
