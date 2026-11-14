import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/battle_mode.dart';
import 'package:skill_battles/core/domain/entity/battle_reason.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_notice.dart';
import 'package:skill_battles/core/presentation/widgets/app_segmented_control.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_link.dart';
import 'package:skill_battles/core/presentation/widgets/battle_outcome_text.dart';
import 'package:skill_battles/core/presentation/widgets/pro_badge.dart';
import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';
import 'package:skill_battles/features/catalog/presentation/extensions/catalog_labels.dart';
import 'package:skill_battles/features/history/domain/entity/history_item_entity.dart';
import 'package:skill_battles/features/history/domain/entity/history_page_entity.dart';
import 'package:skill_battles/features/history/domain/entity/history_params_entity.dart';
import 'package:skill_battles/features/profile/presentation/bloc/profile_bloc/profile_bloc.dart';

/// "Match history": server-side filter and pages. For Free the server keeps
/// only the latest 10 matches before filtering.
final class MatchHistorySection extends StatelessWidget {
  const MatchHistorySection({
    required this.page,
    required this.params,
    required this.disciplines,
    super.key,
  });

  final HistoryPageEntity page;
  final HistoryParamsEntity params;
  final List<DisciplineEntity> disciplines;

  void _change(BuildContext context, {required int page, BattleMode? mode}) {
    context.read<ProfileBloc>().add(
      ProfileHistoryChanged(
        page: page,
        mode: mode,
        disciplineCode: params.disciplineCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int total = page.page.totalElements;
    final int start = page.page.page * page.page.size;
    final int end = start + page.items.length;
    final int? limit = page.historyLimit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Text('Match history', style: AppTextStyles.titleLg),
            AppSegmentedControl<BattleMode?>(
              size: AppSegmentedControlSize.small,
              selected: params.mode,
              onSelected: (BattleMode? mode) =>
                  _change(context, page: 0, mode: mode),
              segments: <AppSegment<BattleMode?>>[
                const AppSegment<BattleMode?>(value: null, label: 'All'),
                for (final BattleMode mode in BattleMode.values)
                  AppSegment<BattleMode?>(value: mode, label: mode.label),
              ],
            ),
          ],
        ),
        if (limit != null)
          Skeleton.ignore(
            child: AppNotice(
              message:
                  'Free shows your latest $limit matches. Your statistics '
                  'still count every match.',
              actionLabel: 'See Pro',
              onAction: context.goPro,
            ),
          ),
        const _TableHeader(),
        if (page.items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'No matches yet.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.muted),
            ),
          )
        else
          Column(
            children: <Widget>[
              for (final HistoryItemEntity match in page.items)
                _MatchRow(
                  key: ValueKey<String>(match.battleId),
                  match: match,
                  disciplineName: disciplines.nameOf(match.disciplineCode),
                ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                total == 0
                    ? 'Showing 0 of 0'
                    : 'Showing ${start + 1}–$end of $total',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
              ),
              Row(
                spacing: 8,
                children: <Widget>[
                  AppButton(
                    label: 'Previous',
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.compact,
                    onPressed: page.page.hasPrevious
                        ? () => _change(
                            context,
                            page: page.page.page - 1,
                            mode: params.mode,
                          )
                        : null,
                  ),
                  AppButton(
                    label: 'Next',
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.compact,
                    onPressed: page.page.hasNext
                        ? () => _change(
                            context,
                            page: page.page.page + 1,
                            mode: params.mode,
                          )
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _TableHeader extends StatelessWidget {
  const _TableHeader();

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
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          spacing: 16,
          children: <Widget>[
            SizedBox(width: 90, child: Text('Result', style: style)),
            Expanded(child: Text('Opponent', style: style)),
            SizedBox(width: 150, child: Text('Discipline', style: style)),
            SizedBox(width: 90, child: Text('Mode', style: style)),
            SizedBox(
              width: 140,
              child: Text('Score', style: style, textAlign: TextAlign.right),
            ),
            SizedBox(
              width: 80,
              child: Text('Rating', style: style, textAlign: TextAlign.right),
            ),
            SizedBox(
              width: 120,
              child: Text('Date', style: style, textAlign: TextAlign.right),
            ),
            const SizedBox(width: 80),
          ],
        ),
      ),
    );
  }
}

final class _MatchRow extends StatelessWidget {
  const _MatchRow({
    required this.match,
    required this.disciplineName,
    super.key,
  });

  final HistoryItemEntity match;
  final String disciplineName;

  @override
  Widget build(BuildContext context) {
    final String? note = switch (match.reason) {
      BattleReason.surrender => 'surrender',
      BattleReason.disconnect => 'disconnect',
      BattleReason.overtimeWin => 'overtime',
      BattleReason.normal => null,
      _ => match.reason.describe(iWon: false, isDraw: false).toLowerCase(),
    };
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          spacing: 16,
          children: <Widget>[
            SizedBox(
              width: 90,
              child: Align(
                alignment: Alignment.centerLeft,
                child: BattleOutcomeText(outcome: match.outcome),
              ),
            ),
            Expanded(
              child: Row(
                spacing: 6,
                children: <Widget>[
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        text: match.opponent.nickname,
                        children: <InlineSpan>[
                          if (note != null)
                            TextSpan(
                              text: ' · $note',
                              style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                        ],
                      ),
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (match.opponent.isPro) const ProBadge(compact: true),
                ],
              ),
            ),
            SizedBox(
              width: 150,
              child: Text(
                disciplineName,
                style: AppTextStyles.bodyMd,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 90,
              child: Text(
                match.mode.label,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.muted),
              ),
            ),
            SizedBox(
              width: 140,
              child: Text(
                '${match.myScore} : ${match.opponentScore}',
                style: AppTextStyles.monoBodyMd.copyWith(
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            SizedBox(
              width: 80,
              child: RatingDeltaText(
                delta: match.mode == BattleMode.ranked
                    ? match.ratingDelta
                    : null,
              ),
            ),
            SizedBox(
              width: 120,
              child: Text(
                DisplayFormatters.date(match.finishedAt),
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.muted),
                textAlign: TextAlign.right,
              ),
            ),
            SizedBox(
              width: 80,
              child: Align(
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
