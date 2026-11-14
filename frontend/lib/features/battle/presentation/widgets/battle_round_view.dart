import 'dart:ui' show PathMetric;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/question_entity.dart';
import 'package:skill_battles/core/domain/entity/question_option_entity.dart';
import 'package:skill_battles/core/domain/entity/round_answer_entity.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_countdown_text.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tag.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_link.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_phase.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_round_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_snapshot_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/round_reveal_entity.dart';
import 'package:skill_battles/features/battle/presentation/bloc/battle_bloc/battle_bloc.dart';
import 'package:skill_battles/features/battle/presentation/widgets/battle_option_card.dart';

/// Centered column of at most 880 px shared by question, options, footer.
final class BattleColumn extends StatelessWidget {
  const BattleColumn({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: child,
      ),
    );
  }
}

/// `25.0s` — answer times inside the battle (Paper writes no space).
String _answerSeconds(Duration? value) => value == null
    ? '—'
    : '${(value.inMilliseconds / 1000).toStringAsFixed(1)}s';

/// QUESTION and REVEAL of the current round (regular or overtime)
/// (Paper: "05 Live Battle", "16 Battle — Overtime", "17 Battle — Reveal").
///
/// What the reveal shows comes only from the server payload: Free readers
/// get their own choice and correctness, never `correctOptionId` or the
/// opponent's choice; nothing hidden is rendered and then masked.
final class BattleRoundView extends StatelessWidget {
  const BattleRoundView({
    required this.snapshot,
    required this.round,
    required this.state,
    super.key,
  });

  final BattleSnapshotEntity snapshot;
  final BattleRoundEntity round;
  final BattleState state;

  @override
  Widget build(BuildContext context) {
    final RoundRevealEntity? reveal = snapshot.phase == BattlePhase.reveal
        ? round.reveal
        : null;
    final double gap = round.isOvertime
        ? 32
        : reveal != null
        ? 28
        : 40;
    return Padding(
      padding: EdgeInsets.only(top: round.isOvertime ? 40 : 56),
      child: Column(
        spacing: gap,
        children: <Widget>[
          if (round.isOvertime)
            BattleColumn(
              child: _OvertimeCallout(rounds: snapshot.questionCount),
            ),
          _Question(snapshot: snapshot, round: round, isReveal: reveal != null),
          _Options(
            snapshot: snapshot,
            round: round,
            state: state,
            reveal: reveal,
          ),
          if (reveal != null) ...<Widget>[
            BattleColumn(
              child: _RevealSummary(
                snapshot: snapshot,
                round: round,
                reveal: reveal,
              ),
            ),
            if (!reveal.answerAccess.canViewCorrectAnswer)
              const BattleColumn(child: _FreeRevealCallout()),
          ],
        ],
      ),
    );
  }
}

/// The line at the bottom of a round: status on the left, the actions
/// (submit, surrender) on the right.
final class BattleRoundFooter extends StatelessWidget {
  const BattleRoundFooter({
    required this.snapshot,
    required this.round,
    required this.state,
    required this.onSurrender,
    super.key,
  });

  final BattleSnapshotEntity snapshot;
  final BattleRoundEntity round;
  final BattleState state;
  final VoidCallback? onSurrender;

  @override
  Widget build(BuildContext context) {
    final RoundRevealEntity? reveal = snapshot.phase == BattlePhase.reveal
        ? round.reveal
        : null;
    final AnswerSubmission? submission = state.submission;
    final bool isRetry = submission?.status == SubmissionStatus.failed;
    return BattleColumn(
      child: Row(
        spacing: 24,
        children: <Widget>[
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: reveal != null
                  ? _RevealStatus(
                      snapshot: snapshot,
                      round: round,
                      reveal: reveal,
                    )
                  : _QuestionStatus(
                      snapshot: snapshot,
                      round: round,
                      state: state,
                    ),
            ),
          ),
          if (reveal == null && (submission == null || isRetry))
            AppButton(
              label: isRetry ? 'Retry' : 'Submit answer',
              size: AppButtonSize.small,
              onPressed: state.canSubmit
                  ? () => context.read<BattleBloc>().add(
                      const BattleAnswerSubmitted(),
                    )
                  : null,
            ),
          AppTextLink(
            label: 'Surrender',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.danger,
              fontWeight: FontWeight.w500,
            ),
            onPressed: onSurrender,
          ),
        ],
      ),
    );
  }
}

final class _OvertimeCallout extends StatelessWidget {
  const _OvertimeCallout({required this.rounds});

  final int rounds;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTextStyles.bodyMd.copyWith(
      color: AppColors.accentCalloutText,
      height: 20 / 14,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accentTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          spacing: 16,
          children: <Widget>[
            const AppSvgIcon(AppIcons.timer, width: 22, height: 22),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    TextSpan(
                      text: 'Tied after $rounds rounds. ',
                      style: style.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(
                      text:
                          'One sudden-death question decides it. No points or '
                          "streak bonus — only who's right, then who's "
                          'faster.',
                    ),
                  ],
                ),
                style: style,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _Question extends StatelessWidget {
  const _Question({
    required this.snapshot,
    required this.round,
    required this.isReveal,
  });

  final BattleSnapshotEntity snapshot;
  final BattleRoundEntity round;
  final bool isReveal;

  @override
  Widget build(BuildContext context) {
    final QuestionEntity question = round.question;
    final DateTime? next = snapshot.nextRoundStartsAt;
    final bool isLast =
        round.isOvertime || round.number >= snapshot.questionCount;
    final String topic = '${question.topicName} · ${question.difficulty.label}';
    return BattleColumn(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 20,
        children: <Widget>[
          Row(
            spacing: 16,
            children: <Widget>[
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppTag(
                    label: round.isOvertime ? 'Overtime · $topic' : topic,
                    tone: round.isOvertime
                        ? AppTagTone.accent
                        : AppTagTone.primary,
                  ),
                ),
              ),
              if (!isReveal)
                AppCountdownText(
                  key: const ValueKey<String>('round-deadline'),
                  target: round.deadline,
                  clockOffset: snapshot.clockOffset,
                  style: AppTextStyles.monoMd,
                )
              else if (next != null)
                AppCountdownText(
                  key: const ValueKey<String>('next-round'),
                  target: next,
                  clockOffset: snapshot.clockOffset,
                  format: AppCountdownFormat.seconds,
                  prefix: isLast ? 'Results in ' : 'Next in ',
                  style: AppTextStyles.monoSm.copyWith(
                    fontSize: 18,
                    height: 22 / 18,
                    color: AppColors.muted,
                  ),
                )
              else
                Text(
                  "Time's up",
                  style: AppTextStyles.monoMd.copyWith(color: AppColors.faint),
                ),
            ],
          ),
          SelectionArea(
            child: Text(question.prompt, style: AppTextStyles.headlineMd),
          ),
        ],
      ),
    );
  }
}

final class _Options extends StatelessWidget {
  const _Options({
    required this.snapshot,
    required this.round,
    required this.state,
    required this.reveal,
  });

  final BattleSnapshotEntity snapshot;
  final BattleRoundEntity round;
  final BattleState state;
  final RoundRevealEntity? reveal;

  @override
  Widget build(BuildContext context) {
    final List<QuestionOptionEntity> options = round.question.options;
    final RoundRevealEntity? reveal = this.reveal;
    return BattleColumn(
      child: Column(
        spacing: 16,
        children: <Widget>[
          for (int row = 0; row < options.length; row += 2)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: <Widget>[
                  for (int i = row; i < row + 2; i++)
                    Expanded(
                      child: i >= options.length
                          ? const SizedBox.shrink()
                          : reveal != null
                          ? _RevealOption(
                              option: options[i],
                              letter: BattleOptionCard.letterAt(i),
                              snapshot: snapshot,
                              round: round,
                              reveal: reveal,
                            )
                          : _OpenOption(
                              option: options[i],
                              letter: BattleOptionCard.letterAt(i),
                              state: state,
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

final class _OpenOption extends StatelessWidget {
  const _OpenOption({
    required this.option,
    required this.letter,
    required this.state,
  });

  final QuestionOptionEntity option;
  final String letter;
  final BattleState state;

  @override
  Widget build(BuildContext context) {
    final AnswerSubmission? submission = state.submission;
    final bool isChosen = submission != null
        ? submission.optionId == option.id
        : state.selectedOptionId == option.id;
    final String? label = !isChosen
        ? null
        : switch (submission?.status) {
            null => 'Your choice',
            SubmissionStatus.sending => 'Sending…',
            SubmissionStatus.accepted => 'Your answer',
            SubmissionStatus.failed => 'Not sent yet',
            SubmissionStatus.closed => 'Too late',
          };
    return BattleOptionCard(
      option: option,
      letter: letter,
      state: isChosen ? BattleOptionState.selected : BattleOptionState.idle,
      trailingLabel: label,
      onPressed: state.canChangeSelection
          ? () =>
                context.read<BattleBloc>().add(BattleOptionSelected(option.id))
          : null,
    );
  }
}

final class _RevealOption extends StatelessWidget {
  const _RevealOption({
    required this.option,
    required this.letter,
    required this.snapshot,
    required this.round,
    required this.reveal,
  });

  final QuestionOptionEntity option;
  final String letter;
  final BattleSnapshotEntity snapshot;
  final BattleRoundEntity round;
  final RoundRevealEntity reveal;

  @override
  Widget build(BuildContext context) {
    final RoundAnswerEntity? mine = reveal.answerOf(snapshot.myUserId);
    final RoundAnswerEntity? theirs = reveal.answerOf(snapshot.opponent.id);
    final String? mySelection =
        mine?.selectedOptionId ?? round.mySelectedOptionId;
    final bool isMine = mySelection == option.id;
    final bool myCorrect = mine?.correct ?? false;
    // Present only for Pro readers.
    final bool isCorrect = reveal.correctOptionId == option.id;
    final bool isTheirs = theirs?.selectedOptionId == option.id;
    final bool isPro = reveal.answerAccess.canViewCorrectAnswer;
    final String opponent = snapshot.opponent.nickname;

    final BattleOptionState visual = isCorrect || (isMine && myCorrect)
        ? BattleOptionState.correct
        : isMine || isTheirs
        ? BattleOptionState.wrong
        : BattleOptionState.idle;
    final List<String> who = <String>[
      if (isMine && isPro)
        'You · ${DisplayFormatters.points(mine?.points ?? 0)}'
      else if (isMine)
        'Your answer · ${myCorrect ? 'Correct' : 'Incorrect'}',
      if (isTheirs)
        '$opponent · ${DisplayFormatters.points(theirs?.points ?? 0)}',
    ];
    final String? label = who.isNotEmpty
        ? who.join(', ')
        : isCorrect
        ? 'Correct answer'
        : null;
    return BattleOptionCard(
      option: option,
      letter: letter,
      state: visual,
      trailingLabel: label,
      trailingAvatarNickname: isTheirs ? opponent : null,
      onPressed: null,
    );
  }
}

/// The two "You · Correct / +1,116" cards under the revealed options.
final class _RevealSummary extends StatelessWidget {
  const _RevealSummary({
    required this.snapshot,
    required this.round,
    required this.reveal,
  });

  final BattleSnapshotEntity snapshot;
  final BattleRoundEntity round;
  final RoundRevealEntity reveal;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: <Widget>[
          Expanded(
            child: _AnswerSummary(
              name: 'You',
              answer: reveal.answerOf(snapshot.myUserId),
              isOvertime: round.isOvertime,
            ),
          ),
          Expanded(
            child: _AnswerSummary(
              name: snapshot.opponent.nickname,
              answer: reveal.answerOf(snapshot.opponent.id),
              isOvertime: round.isOvertime,
            ),
          ),
        ],
      ),
    );
  }
}

final class _AnswerSummary extends StatelessWidget {
  const _AnswerSummary({
    required this.name,
    required this.answer,
    required this.isOvertime,
  });

  final String name;
  final RoundAnswerEntity? answer;
  final bool isOvertime;

  @override
  Widget build(BuildContext context) {
    final RoundAnswerEntity? answer = this.answer;
    final bool answered = answer != null && !answer.timedOut;
    final bool correct = answer?.correct ?? false;
    final String verdict = !answered
        ? "Time's up"
        : correct
        ? 'Correct'
        : 'Incorrect';
    final String detail = switch (answer) {
      null || RoundAnswerEntity(timedOut: true) => 'No answer in time',
      RoundAnswerEntity(correct: false) =>
        'Answered in ${_answerSeconds(answer.elapsed)}',
      _ when isOvertime =>
        'Answered in ${_answerSeconds(answer.elapsed)}'
            '${answer.tieBreakPoints > 0 ? ' · wins the tie-break' : ''}',
      _ =>
        '${<String>['${DisplayFormatters.grouped(answer.basePoints)} base', '${DisplayFormatters.grouped(answer.speedBonus)} speed', if (answer.streakBonus > 0) '${DisplayFormatters.grouped(answer.streakBonus)} streak'].join(' + ')} · ${_answerSeconds(answer.elapsed)}',
    };
    final int points = isOvertime
        ? answer?.tieBreakPoints ?? 0
        : answer?.points ?? 0;
    final Color pointsColor = points <= 0
        ? AppColors.faint
        : isOvertime
        ? AppColors.accentDeep
        : AppColors.success;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          spacing: 16,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: <Widget>[
                  Text(
                    '$name · $verdict',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    detail,
                    style: AppTextStyles.bodyXs.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              DisplayFormatters.points(points),
              style: AppTextStyles.monoSm.copyWith(
                fontSize: 24,
                height: 30 / 24,
                fontWeight: FontWeight.w600,
                color: pointsColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dashed amber note on a Free reveal: the correct option stays hidden.
final class _FreeRevealCallout extends StatelessWidget {
  const _FreeRevealCallout();

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTextStyles.bodyMd.copyWith(height: 20 / 14);
    return CustomPaint(
      painter: const _DashedOutline(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          spacing: 12,
          children: <Widget>[
            const AppSvgIcon(AppIcons.lock, width: 16, height: 16),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    const TextSpan(
                      text: 'The correct option stays hidden on Free. ',
                    ),
                    TextSpan(
                      text:
                          'Pro shows it after each round and explains it '
                          'after the match.',
                      style: style.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
                style: style,
              ),
            ),
            AppTextLink(
              label: 'Go Pro',
              style: AppTextStyles.buttonMd.copyWith(
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

final class _DashedOutline extends CustomPainter {
  const _DashedOutline();

  static const double _dash = 4;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final RRect box = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.5),
      const Radius.circular(12),
    );
    final Path outline = Path()..addRRect(box);
    for (final PathMetric metric in outline.computeMetrics()) {
      for (double d = 0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedOutline oldDelegate) => false;
}

/// A dot and a message, the left side of the footer.
final class _Status extends StatelessWidget {
  const _Status({required this.dot, required this.message});

  final Color dot;
  final Widget message;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10,
      children: <Widget>[
        AppDot(color: dot),
        Flexible(child: message),
      ],
    );
  }
}

final class _QuestionStatus extends StatelessWidget {
  const _QuestionStatus({
    required this.snapshot,
    required this.round,
    required this.state,
  });

  final BattleSnapshotEntity snapshot;
  final BattleRoundEntity round;
  final BattleState state;

  @override
  Widget build(BuildContext context) {
    final AnswerSubmission? submission = state.submission;
    const TextStyle base = AppTextStyles.bodyLg;
    final TextStyle muted = base.copyWith(color: AppColors.muted);
    final bool opponentAnswered = snapshot.opponent.answeredCurrentRound;
    final (Color dot, TextSpan message) = switch (submission?.status) {
      null when round.isOvertime => (
        opponentAnswered ? AppColors.success : AppColors.borderStrong,
        TextSpan(
          children: <InlineSpan>[
            if (opponentAnswered)
              TextSpan(text: '${snapshot.opponent.nickname} has answered. '),
            TextSpan(
              text:
                  'Correct beats wrong; if both are correct, the faster '
                  'answer wins.',
              style: muted,
            ),
          ],
        ),
      ),
      null when state.selectedOptionId == null => (
        AppColors.borderStrong,
        TextSpan(
          text: 'Pick an answer, then submit. It is final.',
          style: muted,
        ),
      ),
      null => (
        AppColors.primary,
        TextSpan(text: 'Submit to lock in your answer.', style: muted),
      ),
      SubmissionStatus.sending => (
        AppColors.primary,
        TextSpan(text: 'Sending your answer…', style: muted),
      ),
      SubmissionStatus.accepted => (
        AppColors.primary,
        TextSpan(
          children: <InlineSpan>[
            const TextSpan(text: 'Answer locked in. '),
            TextSpan(text: 'Waiting for the round to end…', style: muted),
          ],
        ),
      ),
      SubmissionStatus.failed => (
        AppColors.danger,
        TextSpan(
          text:
              "Your answer wasn't confirmed: "
              '${submission?.failure?.userMessage ?? 'connection problem.'}',
          style: base.copyWith(color: AppColors.danger),
        ),
      ),
      SubmissionStatus.closed => (
        AppColors.accent,
        TextSpan(
          text: 'The round closed before your answer arrived.',
          style: muted,
        ),
      ),
    };
    return _Status(
      dot: dot,
      message: Text.rich(message, style: base),
    );
  }
}

final class _RevealStatus extends StatelessWidget {
  const _RevealStatus({
    required this.snapshot,
    required this.round,
    required this.reveal,
  });

  final BattleSnapshotEntity snapshot;
  final BattleRoundEntity round;
  final RoundRevealEntity reveal;

  @override
  Widget build(BuildContext context) {
    const TextStyle base = AppTextStyles.bodyLg;
    final TextStyle muted = base.copyWith(color: AppColors.muted);
    final DateTime? next = snapshot.nextRoundStartsAt;
    final bool isLast =
        round.isOvertime || round.number >= snapshot.questionCount;
    final List<QuestionOptionEntity> options = round.question.options;
    final int correctIndex = options.indexWhere(
      (QuestionOptionEntity option) => option.id == reveal.correctOptionId,
    );
    if (correctIndex < 0) {
      // Free: the correct option is not in the payload.
      return _Status(
        dot: AppColors.faint,
        message: next == null
            ? Text('Round closed.', style: base)
            : AppCountdownText(
                target: next,
                clockOffset: snapshot.clockOffset,
                format: AppCountdownFormat.seconds,
                prefix: isLast
                    ? 'Results in '
                    : 'Round ${round.number + 1} starts in ',
                suffix: ' seconds.',
                style: base,
              ),
      );
    }
    final String answer =
        '${BattleOptionCard.letterAt(correctIndex)} · '
        '${options[correctIndex].text}';
    return _Status(
      dot: AppColors.accent,
      message: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Text.rich(
            TextSpan(
              children: <InlineSpan>[
                const TextSpan(text: 'Correct answer: '),
                TextSpan(
                  text: answer,
                  style: base.copyWith(fontWeight: FontWeight.w600),
                ),
                const TextSpan(text: '. '),
              ],
            ),
            style: base,
          ),
          if (next != null)
            AppCountdownText(
              target: next,
              clockOffset: snapshot.clockOffset,
              format: AppCountdownFormat.seconds,
              prefix: isLast ? 'Results in ' : 'Next round in ',
              suffix: isLast ? 's — full explanations after the battle.' : 's.',
              style: muted,
            ),
        ],
      ),
    );
  }
}
