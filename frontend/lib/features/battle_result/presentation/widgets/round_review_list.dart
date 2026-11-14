import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/question_option_entity.dart';
import 'package:skill_battles/core/domain/entity/round_answer_entity.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/widgets/app_locked_panel.dart';
import 'package:skill_battles/core/presentation/widgets/app_tag.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_link.dart';
import 'package:skill_battles/core/presentation/widgets/pro_badge.dart';
import 'package:skill_battles/features/battle_result/domain/entity/battle_review_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/report_params_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/review_round_entity.dart';
import 'package:skill_battles/features/battle_result/presentation/bloc/battle_result_bloc/battle_result_bloc.dart';
import 'package:skill_battles/features/battle_result/presentation/widgets/report_round_dialog.dart';

/// "Round review": the started rounds with server-gated details. Free
/// readers get their own choice, correctness and points; the correct
/// option, explanations and the opponent's choice come only for Pro.
final class RoundReviewList extends StatefulWidget {
  const RoundReviewList({
    required this.review,
    required this.opponentNickname,
    required this.opponentId,
    required this.mistakesOnly,
    required this.canFilterMistakes,
    required this.reportedRoundIds,
    super.key,
  });

  final BattleReviewEntity review;
  final String opponentNickname;
  final String opponentId;
  final bool mistakesOnly;
  final bool canFilterMistakes;
  final Set<String> reportedRoundIds;

  @override
  State<RoundReviewList> createState() => _RoundReviewListState();
}

final class _RoundReviewListState extends State<RoundReviewList> {
  late Set<String> _expanded;

  @override
  void initState() {
    super.initState();
    final List<ReviewRoundEntity> rounds = widget.review.rounds;
    _expanded = <String>{if (rounds.isNotEmpty) rounds.last.roundId};
  }

  void _toggle(String roundId) {
    setState(() {
      _expanded = _expanded.contains(roundId)
          ? (<String>{..._expanded}..remove(roundId))
          : <String>{..._expanded, roundId};
    });
  }

  Future<void> _report(ReviewRoundEntity round) async {
    final BattleResultBloc bloc = context.read<BattleResultBloc>();
    final ReportParamsEntity? params = await showReportRoundDialog(
      context,
      battleId: widget.review.battleId,
      roundId: round.roundId,
    );
    if (params != null) bloc.add(BattleResultReportSubmitted(params));
  }

  @override
  Widget build(BuildContext context) {
    final BattleReviewEntity review = widget.review;
    final bool isPro = review.answerAccess.canViewCorrectAnswer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 16,
          children: <Widget>[
            const Text('Round review', style: AppTextStyles.titleLg),
            const Spacer(),
            Skeleton.ignore(
              child: _MistakesToggle(
                value: widget.mistakesOnly,
                isEnabled: widget.canFilterMistakes,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Correct = base points by difficulty + speed bonus + streak bonus. '
          'Overtime only breaks a tie.',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        if (!isPro)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Skeleton.ignore(
              child: AppLockedPanel(
                title: 'Correct answers and explanations',
                message:
                    "You see your choice and whether it was right. Pro adds "
                    "the correct option, your opponent's choice and a short "
                    'explanation for every round — also for older matches.',
                onUpgrade: context.goPro,
              ),
            ),
          ),
        const _ColumnHeader(),
        const SizedBox(height: 10),
        if (review.rounds.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              widget.mistakesOnly
                  ? 'No mistakes in this match.'
                  : 'No rounds were played.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.muted),
            ),
          ),
        for (final ReviewRoundEntity round in review.rounds)
          Padding(
            key: ValueKey<String>(round.roundId),
            padding: const EdgeInsets.only(bottom: 16),
            child: _RoundRow(
              round: round,
              myUserId: review.myUserId,
              opponentId: widget.opponentId,
              opponentNickname: widget.opponentNickname,
              isExpanded: _expanded.contains(round.roundId),
              isReported: widget.reportedRoundIds.contains(round.roundId),
              onTap: () => _toggle(round.roundId),
              onReport: () => _report(round),
            ),
          ),
      ],
    );
  }
}

final class _MistakesToggle extends StatelessWidget {
  const _MistakesToggle({required this.value, required this.isEnabled});

  final bool value;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: <Widget>[
        if (!isEnabled) const ProBadge(compact: true),
        Text(
          'Mistakes only',
          style: AppTextStyles.bodySm.copyWith(
            color: isEnabled ? AppColors.ink : AppColors.faint,
            fontWeight: FontWeight.w500,
          ),
        ),
        Switch(
          value: value,
          onChanged: isEnabled
              ? (bool next) => context.read<BattleResultBloc>().add(
                  BattleResultMistakesOnlyChanged(next),
                )
              : null,
        ),
      ],
    );
  }
}

final class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader();

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTextStyles.bodyXs.copyWith(
      fontWeight: FontWeight.w500,
      color: AppColors.muted,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        spacing: 16,
        children: <Widget>[
          const SizedBox(width: 28),
          const Spacer(),
          SizedBox(
            width: 84,
            child: Text('You', style: style, textAlign: TextAlign.right),
          ),
          SizedBox(
            width: 84,
            child: Text('Opponent', style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

final class _RoundRow extends StatelessWidget {
  const _RoundRow({
    required this.round,
    required this.myUserId,
    required this.opponentId,
    required this.opponentNickname,
    required this.isExpanded,
    required this.isReported,
    required this.onTap,
    required this.onReport,
  });

  final ReviewRoundEntity round;
  final String myUserId;
  final String opponentId;
  final String opponentNickname;
  final bool isExpanded;
  final bool isReported;
  final VoidCallback onTap;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final RoundAnswerEntity? mine = round.answerOf(myUserId);
    final RoundAnswerEntity? theirs = round.answerOf(opponentId);
    final String? explanation = round.question.explanation;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded ? AppColors.ink : AppColors.border,
          width: isExpanded ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppTappable(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            semanticValue: isExpanded ? 'Expanded' : 'Collapsed',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: _RoundSummary(
                round: round,
                mine: mine,
                theirs: theirs,
                isExpanded: isExpanded,
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(64, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 14,
                children: <Widget>[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      AppTag(
                        label: round.question.question.topicName,
                        style: AppTextStyles.bodyXs.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppTag(
                        label: round.question.question.difficulty.label,
                        tone: AppTagTone.neutral,
                        style: AppTextStyles.bodyXs.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!round.completed)
                        AppTag(
                          label: 'Not finished',
                          tone: AppTagTone.danger,
                          style: AppTextStyles.bodyXs.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  for (
                    int i = 0;
                    i < round.question.question.options.length;
                    i++
                  )
                    _ReviewOption(
                      option: round.question.question.options[i],
                      letter: String.fromCharCode(65 + i),
                      mine: mine,
                      theirs: theirs,
                      correctOptionId: round.question.correctOptionId,
                      opponentNickname: opponentNickname,
                    ),
                  _Breakdown(answer: mine, overtime: round.isOvertime),
                  if (explanation != null)
                    Text(
                      explanation,
                      style: AppTextStyles.bodyLg.copyWith(
                        height: 24 / 15,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: isReported
                        ? Text(
                            'Reported — thanks.',
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.success,
                            ),
                          )
                        : AppTextLink(
                            label: 'Report a problem with this question',
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                            onPressed: onReport,
                          ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

final class _RoundSummary extends StatelessWidget {
  const _RoundSummary({
    required this.round,
    required this.mine,
    required this.theirs,
    required this.isExpanded,
  });

  final ReviewRoundEntity round;
  final RoundAnswerEntity? mine;
  final RoundAnswerEntity? theirs;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final TextStyle points = AppTextStyles.monoBodyMd;
    final RoundAnswerEntity? mine = this.mine;
    final RoundAnswerEntity? theirs = this.theirs;
    return Row(
      spacing: 16,
      children: <Widget>[
        SizedBox(
          width: 28,
          child: Text(
            round.isOvertime ? 'OT' : round.number.toString().padLeft(2, '0'),
            style: AppTextStyles.monoBodySm.copyWith(
              fontWeight: FontWeight.w600,
              color: round.isOvertime ? AppColors.accentText : AppColors.muted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            round.question.question.prompt,
            style: AppTextStyles.bodyLg.copyWith(
              fontWeight: isExpanded ? FontWeight.w600 : FontWeight.w500,
            ),
            maxLines: isExpanded ? 6 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(
          width: 84,
          child: Text(
            mine == null ? '—' : '+${mine.points}',
            style: points.copyWith(
              color: (mine?.correct ?? false)
                  ? AppColors.success
                  : AppColors.faint,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        SizedBox(
          width: 84,
          child: Text(
            theirs == null ? '—' : '+${theirs.points}',
            style: points.copyWith(
              color: (theirs?.correct ?? false)
                  ? AppColors.ink
                  : AppColors.faint,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

final class _ReviewOption extends StatelessWidget {
  const _ReviewOption({
    required this.option,
    required this.letter,
    required this.mine,
    required this.theirs,
    required this.correctOptionId,
    required this.opponentNickname,
  });

  final QuestionOptionEntity option;
  final String letter;
  final RoundAnswerEntity? mine;
  final RoundAnswerEntity? theirs;
  final String? correctOptionId;
  final String opponentNickname;

  @override
  Widget build(BuildContext context) {
    final bool isMine = mine?.selectedOptionId == option.id;
    final bool isTheirs = theirs?.selectedOptionId == option.id;
    final bool isCorrect =
        correctOptionId == option.id || (isMine && (mine?.correct ?? false));
    final Color tone = isCorrect
        ? AppColors.success
        : isMine
        ? AppColors.danger
        : AppColors.ink;
    final List<String> notes = <String>[
      if (isCorrect && correctOptionId == option.id) 'Correct',
      if (isMine) 'Your answer',
      if (isTheirs) opponentNickname,
    ];
    return Row(
      spacing: 12,
      children: <Widget>[
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isCorrect
                ? AppColors.successSurface
                : isMine
                ? AppColors.dangerSurface
                : AppColors.surface,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            letter,
            style: AppTextStyles.monoBodySm.copyWith(
              color: tone,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            option.text,
            style: AppTextStyles.bodyMd.copyWith(
              color: tone,
              fontWeight: isMine || isCorrect
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
        ),
        if (notes.isNotEmpty)
          Text(
            notes.join(' · '),
            style: AppTextStyles.bodyXs.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

final class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.answer, required this.overtime});

  final RoundAnswerEntity? answer;
  final bool overtime;

  @override
  Widget build(BuildContext context) {
    final RoundAnswerEntity? answer = this.answer;
    final String text = switch (answer) {
      null => 'Not answered.',
      RoundAnswerEntity(timedOut: true) => "Time's up — no answer.",
      RoundAnswerEntity(correct: false) =>
        'Wrong · answered in ${DisplayFormatters.seconds(answer.elapsed)}',
      _ when overtime =>
        'Correct in ${DisplayFormatters.seconds(answer.elapsed)}'
            '${answer.tieBreakPoints > 0 ? ' · won the tie-break (+1)' : ''}',
      _ =>
        '+${answer.points} = ${answer.basePoints} base + ${answer.speedBonus} '
            'speed + ${answer.streakBonus} streak · '
            '${DisplayFormatters.seconds(answer.elapsed)}',
    };
    return Text(
      text,
      style: AppTextStyles.monoBodySm.copyWith(color: AppColors.muted),
    );
  }
}
