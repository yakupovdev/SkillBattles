import 'package:material_ui/material_ui.dart';

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
final class HistoryTable extends StatelessWidget {
  const HistoryTable({
    required this.page,
    required this.disciplines,
    required this.onPageSelected,
    super.key,
  });

  final HistoryPageEntity page;
  final List<DisciplineEntity> disciplines;
  final ValueChanged<int>? onPageSelected;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 24,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
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
          ],
        ),
        _Pager(page: page, onPageSelected: onPageSelected),
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
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          spacing: 16,
          children: <Widget>[
            SizedBox(
              width: _Columns.result,
              child: Text('Result', style: style),
            ),
            Expanded(child: Text('Opponent', style: style)),
            SizedBox(
              width: _Columns.discipline,
              child: Text('Discipline', style: style),
            ),
            SizedBox(
              width: _Columns.mode,
              child: Text('Mode', style: style),
            ),
            SizedBox(
              width: _Columns.score,
              child: Text('Score', style: style, textAlign: TextAlign.right),
            ),
            SizedBox(
              width: _Columns.elo,
              child: Text('Elo', style: style, textAlign: TextAlign.right),
            ),
            SizedBox(
              width: _Columns.date,
              child: Text('Date', style: style, textAlign: TextAlign.right),
            ),
            const SizedBox(width: _Columns.review),
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
        'No matches here yet.',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyMd.copyWith(color: AppColors.muted),
      ),
    );
  }
}

final class _Row extends StatelessWidget {
  const _Row({
    required this.match,
    required this.disciplineName,
    required this.now,
    super.key,
  });

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
  Widget build(BuildContext context) {
    final bool cancelled = _isCancelled;
    final String? note = _note;
    final TextStyle cell = AppTextStyles.bodyMd;
    final TextStyle mono = AppTextStyles.monoBodyMd.copyWith(
      fontWeight: FontWeight.w400,
    );
    final bool isRanked = match.mode == BattleMode.ranked;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          spacing: 16,
          children: <Widget>[
            SizedBox(
              width: _Columns.result,
              child: _ResultLabel(match: match),
            ),
            Expanded(
              child: Row(
                spacing: 8,
                children: <Widget>[
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        text: match.opponent.nickname,
                        children: <InlineSpan>[
                          if (note != null)
                            TextSpan(
                              text: ' · $note',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontWeight: cancelled
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                      style: AppTextStyles.bodyLg.copyWith(
                        fontWeight: cancelled
                            ? FontWeight.w500
                            : FontWeight.w600,
                        color: cancelled ? AppColors.muted : AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (match.opponent.isPro)
                    const ProBadge(tone: ProBadgeTone.amber),
                ],
              ),
            ),
            SizedBox(
              width: _Columns.discipline,
              child: Text(
                disciplineName,
                style: cell.copyWith(
                  color: cancelled ? AppColors.muted : AppColors.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: _Columns.mode,
              child: Text(
                match.mode.label,
                style: cell.copyWith(color: AppColors.muted),
              ),
            ),
            SizedBox(
              width: _Columns.score,
              child: Text(
                cancelled
                    ? '—'
                    : '${DisplayFormatters.grouped(match.myScore)} : '
                          '${DisplayFormatters.grouped(match.opponentScore)}',
                style: mono.copyWith(
                  color: cancelled ? AppColors.faint : AppColors.ink,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            SizedBox(
              width: _Columns.elo,
              child: RatingDeltaText(
                delta: isRanked && !cancelled ? match.ratingDelta : null,
                style: mono,
              ),
            ),
            SizedBox(
              width: _Columns.date,
              child: Text(
                DisplayFormatters.matchDate(match.finishedAt, now),
                style: cell.copyWith(color: AppColors.muted),
                textAlign: TextAlign.right,
                maxLines: 1,
              ),
            ),
            SizedBox(
              width: _Columns.review,
              child: cancelled
                  ? null
                  : Align(
                      alignment: Alignment.centerRight,
                      child: AppTextLink(
                        label: 'Review',
                        style: AppTextStyles.buttonMd.copyWith(
                          color: AppColors.primary,
                        ),
                        onPressed: () => context.goBattleResult(match.battleId),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "WIN · OT", "LOSS", "DRAW", "CANCEL" in mono caps.
final class _ResultLabel extends StatelessWidget {
  const _ResultLabel({required this.match});

  final HistoryItemEntity match;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (match.outcome) {
      BattleOutcome.win => ('WIN', AppColors.success),
      BattleOutcome.loss => ('LOSS', AppColors.danger),
      BattleOutcome.draw => ('DRAW', AppColors.muted),
      BattleOutcome.cancelled => ('CANCEL', AppColors.faint),
    };
    // A drawn overtime is told by the note after the opponent's name.
    final bool overtime =
        match.overtimePlayed &&
        (match.outcome == BattleOutcome.win ||
            match.outcome == BattleOutcome.loss);
    return Text(
      overtime ? '$label · OT' : label,
      style: AppTextStyles.outcome.copyWith(color: color),
      maxLines: 1,
    );
  }
}

final class _Pager extends StatelessWidget {
  const _Pager({required this.page, required this.onPageSelected});

  final HistoryPageEntity page;
  final ValueChanged<int>? onPageSelected;

  @override
  Widget build(BuildContext context) {
    final int total = page.page.totalElements;
    final int start = page.page.page * page.page.size;
    final int end = start + page.items.length;
    final ValueChanged<int>? onSelected = onPageSelected;
    final int current = page.page.page;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          total == 0 ? 'Showing 0 of 0' : 'Showing ${start + 1}–$end of $total',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
        ),
        Row(
          spacing: 8,
          children: <Widget>[
            AppButton(
              label: 'Previous',
              variant: AppButtonVariant.outline,
              size: AppButtonSize.compact,
              onPressed: onSelected != null && page.page.hasPrevious
                  ? () => onSelected(current - 1)
                  : null,
            ),
            AppButton(
              label: 'Next',
              variant: AppButtonVariant.outline,
              size: AppButtonSize.compact,
              onPressed: onSelected != null && page.page.hasNext
                  ? () => onSelected(current + 1)
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}
