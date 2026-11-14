import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/question_option_entity.dart';
import 'package:skill_battles/core/domain/entity/round_answer_entity.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tag.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_link.dart';
import 'package:skill_battles/features/battle_result/domain/entity/battle_review_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/report_params_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/review_question_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/review_round_entity.dart';
import 'package:skill_battles/features/battle_result/presentation/bloc/battle_result_bloc/battle_result_bloc.dart';
import 'package:skill_battles/features/battle_result/presentation/widgets/report_round_dialog.dart';

/// "Round review": the started rounds with server-gated details. Free
/// readers get their own choice, correctness and points; the correct
/// option, explanations and the opponent's choice come only for Pro.
final class RoundReviewList extends StatefulWidget {
  const RoundReviewList({
    required this.review,
    required this.disciplineName,
    required this.opponentNickname,
    required this.opponentId,
    required this.mistakesOnly,
    required this.canFilterMistakes,
    required this.reportedRoundIds,
    super.key,
  });

  final BattleReviewEntity review;
  final String disciplineName;
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
      eyebrow: <String>[
        if (round.isOvertime) 'Overtime' else 'Round ${_roundNumber(round)}',
        if (widget.disciplineName.isNotEmpty) widget.disciplineName,
      ].join(' · '),
      prompt: round.question.question.prompt,
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
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            const Text('Round review', style: AppTextStyles.titleLg),
            const Spacer(),
            Text(
              'Base + speed + streak',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ColumnHeader(
          opponentNickname: widget.opponentNickname,
          mistakesToggle: widget.canFilterMistakes
              ? Skeleton.ignore(
                  child: _MistakesToggle(value: widget.mistakesOnly),
                )
              : null,
        ),
        const SizedBox(height: 6),
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
            padding: const EdgeInsets.only(bottom: 12),
            child: _RoundRow(
              round: round,
              myUserId: review.myUserId,
              opponentId: widget.opponentId,
              opponentNickname: widget.opponentNickname,
              isPro: isPro,
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

/// `03` — the round number as the review and the report show it.
String _roundNumber(ReviewRoundEntity round) =>
    round.number.toString().padLeft(2, '0');

/// `B · $60.00` — the letter and text of an option, `null` when unknown.
String? _optionLabel(ReviewQuestionEntity question, String? optionId) {
  if (optionId == null) return null;
  final List<QuestionOptionEntity> options = question.question.options;
  for (int i = 0; i < options.length; i++) {
    if (options[i].id == optionId) {
      return '${String.fromCharCode(65 + i)} · ${options[i].text}';
    }
  }
  return null;
}

final class _MistakesToggle extends StatelessWidget {
  const _MistakesToggle({required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: <Widget>[
        Text(
          'Mistakes only',
          style: AppTextStyles.bodyXs.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: value,
            onChanged: (bool next) => context.read<BattleResultBloc>().add(
              BattleResultMistakesOnlyChanged(next),
            ),
          ),
        ),
      ],
    );
  }
}

final class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader({
    required this.opponentNickname,
    required this.mistakesToggle,
  });

  final String opponentNickname;
  final Widget? mistakesToggle;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTextStyles.bodyXs.copyWith(
      fontWeight: FontWeight.w500,
      color: AppColors.muted,
    );
    final Widget? toggle = mistakesToggle;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        spacing: 16,
        children: <Widget>[
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: toggle),
          ),
          SizedBox(
            width: 84,
            child: Text('You', style: style, textAlign: TextAlign.right),
          ),
          SizedBox(
            width: 84,
            child: Text(
              opponentNickname,
              style: style,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
    required this.isPro,
    required this.isExpanded,
    required this.isReported,
    required this.onTap,
    required this.onReport,
  });

  final ReviewRoundEntity round;
  final String myUserId;
  final String opponentId;
  final String opponentNickname;
  final bool isPro;
  final bool isExpanded;
  final bool isReported;
  final VoidCallback onTap;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final RoundAnswerEntity? mine = round.answerOf(myUserId);
    final RoundAnswerEntity? theirs = round.answerOf(opponentId);
    final String? explanation = round.question.explanation;
    final bool overtime = round.isOvertime && !isExpanded;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: overtime ? AppColors.accentRowSurface : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isExpanded
              ? AppColors.ink
              : overtime
              ? AppColors.accentRowBorder
              : AppColors.border,
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
              padding: EdgeInsets.fromLTRB(20, isExpanded ? 20 : 18, 20, 18),
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 14,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 44),
                    child: _AnswerTags(
                      question: round.question,
                      mine: mine,
                      theirs: theirs,
                      opponentNickname: opponentNickname,
                      isPro: isPro,
                      completed: round.completed,
                    ),
                  ),
                  if (explanation != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 44),
                      child: Text(
                        explanation,
                        style: AppTextStyles.bodyLg.copyWith(
                          height: 24 / 15,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                  if (!isPro) const Skeleton.ignore(child: _ProLockBar()),
                  Padding(
                    padding: const EdgeInsets.only(left: 44),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: isReported
                          ? Text(
                              'Reported — thanks.',
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
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
    final RoundAnswerEntity? mine = this.mine;
    final RoundAnswerEntity? theirs = this.theirs;
    final bool overtime = round.isOvertime;
    return Row(
      spacing: 16,
      children: <Widget>[
        SizedBox(
          width: 28,
          child: Text(
            overtime ? 'OT' : _roundNumber(round),
            style: AppTextStyles.monoBodySm.copyWith(
              fontWeight: FontWeight.w600,
              color: overtime ? AppColors.accentDeep : AppColors.muted,
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
        _Points(
          answer: mine,
          isOvertime: overtime,
          earnedColor: AppColors.success,
        ),
        _Points(
          answer: theirs,
          isOvertime: overtime,
          earnedColor: AppColors.ink,
        ),
      ],
    );
  }
}

/// One 84 px points column: earned points in color, nothing earned faint.
final class _Points extends StatelessWidget {
  const _Points({
    required this.answer,
    required this.isOvertime,
    required this.earnedColor,
  });

  final RoundAnswerEntity? answer;
  final bool isOvertime;
  final Color earnedColor;

  @override
  Widget build(BuildContext context) {
    final RoundAnswerEntity? answer = this.answer;
    final int points = answer == null
        ? 0
        : isOvertime
        ? answer.tieBreakPoints
        : answer.points;
    final Color color = points <= 0
        ? AppColors.faint
        : isOvertime
        ? AppColors.accentDeep
        : earnedColor;
    return SizedBox(
      width: 84,
      child: Text(
        answer == null ? '—' : DisplayFormatters.points(points),
        style: AppTextStyles.monoBodyMd.copyWith(color: color),
        textAlign: TextAlign.right,
      ),
    );
  }
}

/// "Correct: B · $66.00", "You: B · $60.00 · incorrect", "timur.b: correct".
/// Free readers get only their own choice and both players' correctness.
final class _AnswerTags extends StatelessWidget {
  const _AnswerTags({
    required this.question,
    required this.mine,
    required this.theirs,
    required this.opponentNickname,
    required this.isPro,
    required this.completed,
  });

  final ReviewQuestionEntity question;
  final RoundAnswerEntity? mine;
  final RoundAnswerEntity? theirs;
  final String opponentNickname;
  final bool isPro;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final RoundAnswerEntity? mine = this.mine;
    final RoundAnswerEntity? theirs = this.theirs;
    final String? correct = isPro
        ? _optionLabel(question, question.correctOptionId)
        : null;
    final String? myPick = _optionLabel(question, mine?.selectedOptionId);
    final String? theirPick = _optionLabel(question, theirs?.selectedOptionId);
    final bool myCorrect = mine?.correct ?? false;
    final bool theirCorrect = theirs?.correct ?? false;
    final List<(String, bool)> tags = <(String, bool)>[
      if (correct != null) ('Correct: $correct', true),
      if (correct == null || !myCorrect)
        (
          myPick == null
              ? 'You: no answer'
              : correct != null
              ? 'You: $myPick'
              : 'You: $myPick · ${myCorrect ? 'correct' : 'incorrect'}',
          myCorrect,
        ),
      if (theirs != null)
        (
          theirCorrect || theirPick == null
              ? '$opponentNickname: '
                    '${theirs.timedOut
                        ? 'no answer'
                        : theirCorrect
                        ? 'correct'
                        : 'incorrect'}'
              : '$opponentNickname: $theirPick',
          theirCorrect,
        ),
      if (!completed) ('Not finished', false),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final (String label, bool good) in tags)
          AppTag(
            label: label,
            tone: good ? AppTagTone.success : AppTagTone.danger,
            foregroundColor: good ? null : AppColors.dangerText,
            style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w500),
          ),
      ],
    );
  }
}

/// Free: the grey bar that sells the correct answer and explanation.
final class _ProLockBar extends StatelessWidget {
  const _ProLockBar();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          spacing: 10,
          children: <Widget>[
            const AppSvgIcon(
              AppIcons.lock,
              width: 14,
              height: 14,
              color: AppColors.muted,
            ),
            Expanded(
              child: Text(
                'Correct answer, explanation and similar practice are in Pro.',
                style: AppTextStyles.bodySm.copyWith(
                  height: 18 / 13,
                  color: AppColors.inkSoft,
                ),
              ),
            ),
            AppTextLink(
              label: 'Unlock',
              style: AppTextStyles.bodySm.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.accentDeep,
              ),
              onPressed: context.goPro,
            ),
          ],
        ),
      ),
    );
  }
}
