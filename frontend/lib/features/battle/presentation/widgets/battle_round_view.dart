import 'package:bloc_signals_jaspr/bloc_signals_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/question_entity.dart';
import 'package:skill_battles/core/domain/entity/question_option_entity.dart';
import 'package:skill_battles/core/domain/entity/round_answer_entity.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/markdown/markdown_spans.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_countdown_text.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_markdown_text.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tag.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_link.dart';
import 'package:skill_battles/core/presentation/widgets/question_illustration.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/core/utils/feature_flags.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_phase.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_round_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_snapshot_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/round_reveal_entity.dart';
import 'package:skill_battles/features/battle/presentation/bloc/battle_bloc/battle_bloc.dart';
import 'package:skill_battles/features/battle/presentation/widgets/battle_option_card.dart';

/// Centered column of at most 880 px shared by question, options, footer.
final class BattleColumn extends StatelessComponent {
  const BattleColumn({required this.child, super.key});

  final Component child;

  @override
  Component build(BuildContext context) {
    return div(classes: 'battle-column', <Component>[child]);
  }
}

/// `25.0s` — answer times inside the battle (Paper writes no space).
String _answerSeconds(Duration? value) => value == null ? '—' : '${(value.inMilliseconds / 1000).toStringAsFixed(1)}s';

/// QUESTION and REVEAL of the current round (regular or overtime)
/// (Paper: "05 Live Battle", "16 Battle — Overtime", "17 Battle — Reveal").
///
/// What the reveal shows comes only from the server payload: Free readers
/// get their own choice and correctness, never `correctOptionId` or the
/// opponent's choice; nothing hidden is rendered and then masked.
///
/// The round's text is not selectable: the prompt must not be copied out
/// of a live round.
final class BattleRoundView extends StatelessComponent {
  const BattleRoundView({required this.snapshot, required this.round, required this.state, super.key});

  final BattleSnapshotEntity snapshot;
  final BattleRoundEntity round;
  final BattleState state;

  @override
  Component build(BuildContext context) {
    final RoundRevealEntity? reveal = snapshot.phase == BattlePhase.reveal ? round.reveal : null;
    final double gap = round.isOvertime
        ? 32
        : reveal != null
        ? 28
        : 40;
    return div(
      classes: 'battle-round',
      styles: Styles(
        padding: Padding.only(top: Unit.pixels(round.isOvertime ? 40 : 56)),
        gap: Gap.row(Unit.pixels(gap)),
      ),
      <Component>[
        if (round.isOvertime) BattleColumn(child: _OvertimeCallout(rounds: snapshot.questionCount)),
        _Question(snapshot: snapshot, round: round, isReveal: reveal != null),
        _Options(snapshot: snapshot, round: round, state: state, reveal: reveal),
        if (reveal != null) ...<Component>[
          BattleColumn(
            child: _RevealSummary(snapshot: snapshot, round: round, reveal: reveal),
          ),
          if (FeatureFlags.billing && !reveal.answerAccess.canViewCorrectAnswer)
            const BattleColumn(child: _FreeRevealCallout()),
        ],
      ],
    );
  }
}

/// The line at the bottom of a round: status on the left, the actions
/// (submit, surrender) on the right.
final class BattleRoundFooter extends StatelessComponent {
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
  Component build(BuildContext context) {
    final RoundRevealEntity? reveal = snapshot.phase == BattlePhase.reveal ? round.reveal : null;
    final AnswerSubmission? submission = state.submission;
    final bool isRetry = submission?.status == SubmissionStatus.failed;
    return BattleColumn(
      child: div(classes: 'battle-footer', <Component>[
        div(
          classes: 'battle-footer__status',
          attributes: const <String, String>{'aria-live': 'polite'},
          <Component>[
            if (reveal != null)
              _RevealStatus(snapshot: snapshot, round: round, reveal: reveal)
            else
              _QuestionStatus(snapshot: snapshot, round: round, state: state),
          ],
        ),
        if (reveal == null && (submission == null || isRetry))
          AppButton(
            label: isRetry ? 'Retry' : 'Submit answer',
            size: AppButtonSize.small,
            onPressed: state.canSubmit ? () => context.read<BattleBloc>().add(const BattleAnswerSubmitted()) : null,
          ),
        AppTextLink(
          label: 'Surrender',
          style: AppTextStyles.bodyMd.combine(const Styles(color: AppColors.danger, fontWeight: FontWeight.w500)),
          onPressed: onSurrender,
        ),
      ]),
    );
  }
}

final class _OvertimeCallout extends StatelessComponent {
  const _OvertimeCallout({required this.rounds});

  final int rounds;

  @override
  Component build(BuildContext context) {
    return div(classes: 'battle-overtime-callout', <Component>[
      const AppSvgIcon(AppIcons.timer, width: 22, height: 22),
      p(classes: 'battle-overtime-callout__text', <Component>[
        span(classes: 'battle-overtime-callout__lead', <Component>[Component.text('Tied after $rounds rounds. ')]),
        const span(<Component>[
          Component.text(
            'One sudden-death question decides it. No points or '
            "streak bonus — only who's right, then who's "
            'faster.',
          ),
        ]),
      ]),
    ]);
  }
}

final class _Question extends StatelessComponent {
  const _Question({required this.snapshot, required this.round, required this.isReveal});

  final BattleSnapshotEntity snapshot;
  final BattleRoundEntity round;
  final bool isReveal;

  @override
  Component build(BuildContext context) {
    final QuestionEntity question = round.question;
    final DateTime? next = snapshot.nextRoundStartsAt;
    final bool isLast = round.isOvertime || round.number >= snapshot.questionCount;
    final String topic = '${question.topicName} · ${question.difficulty.label}';
    final String? imageUrl = question.imageUrl;
    return BattleColumn(
      child: div(classes: 'battle-question', <Component>[
        div(classes: 'battle-question__meta', <Component>[
          div(classes: 'battle-question__tag', <Component>[
            AppTag(
              label: round.isOvertime ? 'Overtime · $topic' : topic,
              tone: round.isOvertime ? AppTagTone.accent : AppTagTone.primary,
            ),
          ]),
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
              style: AppTextStyles.monoSm.combine(
                const Styles(color: AppColors.muted, fontSize: Unit.pixels(18), lineHeight: Unit.pixels(22)),
              ),
            )
          else
            const span(classes: 'battle-question__times-up', <Component>[Component.text("Time's up")]),
        ]),
        // Above the prompt; the URL comes only from the current round, so
        // nothing is fetched for rounds that are not revealed yet.
        if (imageUrl != null) QuestionIllustration(key: ValueKey<String>(imageUrl), imageUrl: imageUrl),
        AppMarkdownText(question.prompt, style: AppTextStyles.headlineMd),
      ]),
    );
  }
}

final class _Options extends StatelessComponent {
  const _Options({required this.snapshot, required this.round, required this.state, required this.reveal});

  final BattleSnapshotEntity snapshot;
  final BattleRoundEntity round;
  final BattleState state;
  final RoundRevealEntity? reveal;

  @override
  Component build(BuildContext context) {
    final List<QuestionOptionEntity> options = round.question.options;
    final RoundRevealEntity? reveal = this.reveal;
    // Two equal columns; the cards of one row share its height.
    return BattleColumn(
      child: div(classes: 'battle-options', <Component>[
        for (int i = 0; i < options.length; i++)
          if (reveal != null)
            _RevealOption(
              option: options[i],
              letter: BattleOptionCard.letterAt(i),
              snapshot: snapshot,
              round: round,
              reveal: reveal,
            )
          else
            _OpenOption(option: options[i], letter: BattleOptionCard.letterAt(i), state: state),
      ]),
    );
  }
}

final class _OpenOption extends StatelessComponent {
  const _OpenOption({required this.option, required this.letter, required this.state});

  final QuestionOptionEntity option;
  final String letter;
  final BattleState state;

  @override
  Component build(BuildContext context) {
    final AnswerSubmission? submission = state.submission;
    final bool isChosen = submission != null ? submission.optionId == option.id : state.selectedOptionId == option.id;
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
          ? () => context.read<BattleBloc>().add(BattleOptionSelected(option.id))
          : null,
    );
  }
}

final class _RevealOption extends StatelessComponent {
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
  Component build(BuildContext context) {
    final RoundAnswerEntity? mine = reveal.answerOf(snapshot.myUserId);
    final RoundAnswerEntity? theirs = reveal.answerOf(snapshot.opponent.id);
    final String? mySelection = mine?.selectedOptionId ?? round.mySelectedOptionId;
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
      if (isTheirs) '$opponent · ${DisplayFormatters.points(theirs?.points ?? 0)}',
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
final class _RevealSummary extends StatelessComponent {
  const _RevealSummary({required this.snapshot, required this.round, required this.reveal});

  final BattleSnapshotEntity snapshot;
  final BattleRoundEntity round;
  final RoundRevealEntity reveal;

  @override
  Component build(BuildContext context) {
    return div(classes: 'battle-reveal-summary', <Component>[
      _AnswerSummary(name: 'You', answer: reveal.answerOf(snapshot.myUserId), isOvertime: round.isOvertime),
      _AnswerSummary(
        name: snapshot.opponent.nickname,
        answer: reveal.answerOf(snapshot.opponent.id),
        isOvertime: round.isOvertime,
      ),
    ]);
  }
}

final class _AnswerSummary extends StatelessComponent {
  const _AnswerSummary({required this.name, required this.answer, required this.isOvertime});

  final String name;
  final RoundAnswerEntity? answer;
  final bool isOvertime;

  @override
  Component build(BuildContext context) {
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
      RoundAnswerEntity(correct: false) => 'Answered in ${_answerSeconds(answer.elapsed)}',
      _ when isOvertime =>
        'Answered in ${_answerSeconds(answer.elapsed)}'
            '${answer.tieBreakPoints > 0 ? ' · wins the tie-break' : ''}',
      _ =>
        '${<String>['${DisplayFormatters.grouped(answer.basePoints)} base', '${DisplayFormatters.grouped(answer.speedBonus)} speed', if (answer.streakBonus > 0) '${DisplayFormatters.grouped(answer.streakBonus)} streak'].join(' + ')} · ${_answerSeconds(answer.elapsed)}',
    };
    final int points = isOvertime ? answer?.tieBreakPoints ?? 0 : answer?.points ?? 0;
    final Color pointsColor = points <= 0
        ? AppColors.faint
        : isOvertime
        ? AppColors.accentDeep
        : AppColors.success;
    return div(classes: 'battle-answer-summary', <Component>[
      div(classes: 'battle-answer-summary__text', <Component>[
        p(classes: 'battle-answer-summary__verdict', <Component>[Component.text('$name · $verdict')]),
        p(classes: 'battle-answer-summary__detail', <Component>[Component.text(detail)]),
      ]),
      span(
        classes: 'battle-answer-summary__points',
        styles: Styles(color: pointsColor),
        <Component>[Component.text(DisplayFormatters.points(points))],
      ),
    ]);
  }
}

/// Dashed amber note on a Free reveal: the correct option stays hidden.
final class _FreeRevealCallout extends StatelessComponent {
  const _FreeRevealCallout();

  @override
  Component build(BuildContext context) {
    return div(classes: 'battle-free-callout', <Component>[
      const AppSvgIcon(AppIcons.lock, width: 16, height: 16),
      const p(classes: 'battle-free-callout__text', <Component>[
        span(<Component>[Component.text('The correct option stays hidden on Free. ')]),
        span(classes: 'battle-free-callout__muted', <Component>[
          Component.text('Pro shows it after each round and explains it after the match.'),
        ]),
      ]),
      AppTextLink(
        label: 'Go Pro',
        style: AppTextStyles.buttonMd.combine(const Styles(color: AppColors.accentDeep)),
        onPressed: context.goPro,
      ),
    ]);
  }
}

/// A dot and a message, the left side of the footer.
final class _Status extends StatelessComponent {
  const _Status({required this.dot, required this.message});

  final Color dot;
  final Component message;

  @override
  Component build(BuildContext context) {
    return div(classes: 'battle-status', <Component>[
      AppDot(color: dot),
      div(classes: 'battle-status__message', <Component>[message]),
    ]);
  }
}

/// A piece of the footer message; [isMuted] greys it.
final class _StatusText extends StatelessComponent {
  const _StatusText(this.text, {this.isMuted = false, this.isDanger = false});

  final String text;
  final bool isMuted;
  final bool isDanger;

  @override
  Component build(BuildContext context) {
    return span(
      classes: isDanger
          ? 'battle-status__danger'
          : isMuted
          ? 'battle-status__muted'
          : null,
      <Component>[Component.text(text)],
    );
  }
}

final class _QuestionStatus extends StatelessComponent {
  const _QuestionStatus({required this.snapshot, required this.round, required this.state});

  final BattleSnapshotEntity snapshot;
  final BattleRoundEntity round;
  final BattleState state;

  @override
  Component build(BuildContext context) {
    final AnswerSubmission? submission = state.submission;
    final bool opponentAnswered = snapshot.opponent.answeredCurrentRound;
    final (Color dot, List<Component> message) = switch (submission?.status) {
      null when round.isOvertime => (
        opponentAnswered ? AppColors.success : AppColors.borderStrong,
        <Component>[
          if (opponentAnswered) _StatusText('${snapshot.opponent.nickname} has answered. '),
          const _StatusText(
            'Correct beats wrong; if both are correct, the faster answer wins.',
            isMuted: true,
          ),
        ],
      ),
      null when state.selectedOptionId == null => (
        AppColors.borderStrong,
        const <Component>[_StatusText('Pick an answer, then submit. It is final.', isMuted: true)],
      ),
      null => (
        AppColors.primary,
        const <Component>[_StatusText('Submit to lock in your answer.', isMuted: true)],
      ),
      SubmissionStatus.sending => (
        AppColors.primary,
        const <Component>[_StatusText('Sending your answer…', isMuted: true)],
      ),
      SubmissionStatus.accepted => (
        AppColors.primary,
        const <Component>[
          _StatusText('Answer locked in. '),
          _StatusText('Waiting for the round to end…', isMuted: true),
        ],
      ),
      SubmissionStatus.failed => (
        AppColors.danger,
        <Component>[
          _StatusText(
            "Your answer wasn't confirmed: "
            '${submission?.failure?.userMessage ?? 'connection problem.'}',
            isDanger: true,
          ),
        ],
      ),
      SubmissionStatus.closed => (
        AppColors.accent,
        const <Component>[_StatusText('The round closed before your answer arrived.', isMuted: true)],
      ),
    };
    return _Status(
      dot: dot,
      message: p(classes: 'battle-status__text', message),
    );
  }
}

final class _RevealStatus extends StatelessComponent {
  const _RevealStatus({required this.snapshot, required this.round, required this.reveal});

  final BattleSnapshotEntity snapshot;
  final BattleRoundEntity round;
  final RoundRevealEntity reveal;

  @override
  Component build(BuildContext context) {
    const Styles base = AppTextStyles.bodyLg;
    final DateTime? next = snapshot.nextRoundStartsAt;
    final bool isLast = round.isOvertime || round.number >= snapshot.questionCount;
    final List<QuestionOptionEntity> options = round.question.options;
    final int correctIndex = options.indexWhere(
      (QuestionOptionEntity option) => option.id == reveal.correctOptionId,
    );
    if (correctIndex < 0) {
      // Free: the correct option is not in the payload.
      return _Status(
        dot: AppColors.faint,
        message: p(classes: 'battle-status__text', <Component>[
          if (next == null)
            const _StatusText('Round closed.')
          else
            AppCountdownText(
              target: next,
              clockOffset: snapshot.clockOffset,
              format: AppCountdownFormat.seconds,
              prefix: isLast ? 'Results in ' : 'Round ${round.number + 1} starts in ',
              suffix: ' seconds.',
              style: base,
            ),
        ]),
      );
    }
    const Styles answerStyle = Styles(fontWeight: FontWeight.w600);
    return _Status(
      dot: AppColors.accent,
      message: p(classes: 'battle-status__text', <Component>[
        const _StatusText('Correct answer: '),
        span(styles: answerStyle, <Component>[
          Component.text('${BattleOptionCard.letterAt(correctIndex)} · '),
        ]),
        MarkdownSpan(options[correctIndex].text, style: base.combine(answerStyle)),
        const _StatusText('. '),
        if (next != null)
          AppCountdownText(
            target: next,
            clockOffset: snapshot.clockOffset,
            format: AppCountdownFormat.seconds,
            prefix: isLast ? 'Results in ' : 'Next round in ',
            suffix: isLast ? 's — full explanations after the battle.' : 's.',
            style: base.combine(const Styles(color: AppColors.muted)),
          ),
      ]),
    );
  }
}

@css
List<StyleRule> get battleRoundViewStyles => <StyleRule>[
  css('.battle-column').styles(
    width: const Unit.percent(100),
    maxWidth: const Unit.pixels(880 + 64),
    padding: const Padding.symmetric(horizontal: Unit.pixels(32)),
    margin: const Margin.symmetric(horizontal: Unit.auto),
    boxSizing: BoxSizing.borderBox,
  ),
  css('.battle-round').styles(
    display: Display.flex,
    width: const Unit.percent(100),
    userSelect: UserSelect.none,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.center,
  ),
  css('.battle-overtime-callout').styles(
    display: Display.flex,
    padding: const Padding.symmetric(horizontal: Unit.pixels(18), vertical: Unit.pixels(14)),
    radius: const BorderRadius.circular(Unit.pixels(12)),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(16)),
    backgroundColor: AppColors.accentTint,
  ),
  css('.battle-overtime-callout__text')
      .styles(
        minWidth: Unit.zero,
        flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
      )
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(color: AppColors.accentCalloutText, lineHeight: Unit.pixels(20))),
  css('.battle-overtime-callout__lead').styles(fontWeight: FontWeight.w700),
  css('.battle-question').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.stretch,
    gap: const Gap.row(Unit.pixels(20)),
  ),
  css('.battle-question__meta').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(16)),
  ),
  css('.battle-question__tag').styles(
    minWidth: Unit.zero,
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.battle-question__times-up').combine(AppTextStyles.monoMd).combine(const Styles(color: AppColors.faint)),
  css('.battle-options').styles(
    display: Display.grid,
    gap: const Gap.all(Unit.pixels(16)),
    raw: const <String, String>{'grid-template-columns': 'repeat(2, minmax(0, 1fr))'},
  ),
  css('.battle-reveal-summary').styles(
    display: Display.grid,
    gap: const Gap.all(Unit.pixels(16)),
    raw: const <String, String>{'grid-template-columns': 'repeat(2, minmax(0, 1fr))'},
  ),
  css('.battle-answer-summary').styles(
    display: Display.flex,
    padding: const Padding.symmetric(horizontal: Unit.pixels(20), vertical: Unit.pixels(18)),
    radius: const BorderRadius.circular(Unit.pixels(14)),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(16)),
    backgroundColor: AppColors.surface,
  ),
  css('.battle-answer-summary__text').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(4)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.battle-answer-summary__verdict')
      .styles(overflow: Overflow.hidden, textOverflow: TextOverflow.ellipsis, whiteSpace: WhiteSpace.noWrap)
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(fontWeight: FontWeight.w600)),
  css('.battle-answer-summary__detail').combine(AppTextStyles.bodyXs).combine(const Styles(color: AppColors.muted)),
  css('.battle-answer-summary__points')
      .styles(flex: const Flex(shrink: 0))
      .combine(AppTextStyles.monoSm)
      .combine(const Styles(fontSize: Unit.pixels(24), fontWeight: FontWeight.w600, lineHeight: Unit.pixels(30))),
  // Flutter draws 4 px dashes with 3 px gaps; the browser's dashed border is
  // the closest match that keeps the 12 px radius.
  css('.battle-free-callout').styles(
    display: Display.flex,
    padding: const Padding.symmetric(horizontal: Unit.pixels(18), vertical: Unit.pixels(14)),
    radius: const BorderRadius.circular(Unit.pixels(12)),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(12)),
    raw: <String, String>{'border': '1px dashed ${AppColors.accent.value}'},
  ),
  css('.battle-free-callout__text')
      .styles(
        minWidth: Unit.zero,
        flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
      )
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(lineHeight: Unit.pixels(20))),
  css('.battle-free-callout__muted').styles(color: AppColors.muted),
  css('.battle-footer').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(24)),
  ),
  css('.battle-footer__status').styles(
    minWidth: Unit.zero,
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.battle-status').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(10)),
  ),
  css('.battle-status__message').styles(
    minWidth: Unit.zero,
    flex: const Flex(grow: 0, shrink: 1, basis: Unit.auto),
  ),
  css('.battle-status__text').combine(AppTextStyles.bodyLg),
  css('.battle-status__muted').styles(color: AppColors.muted),
  css('.battle-status__danger').styles(color: AppColors.danger),
];
