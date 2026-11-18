import 'package:bloc_signals_jaspr/bloc_signals_jaspr.dart' hide Transition;
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/question_option_entity.dart';
import 'package:skill_battles/core/domain/entity/round_answer_entity.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/markdown/markdown_spans.dart';
import 'package:skill_battles/core/presentation/skeleton/skeletonizer.dart';
import 'package:skill_battles/core/presentation/widgets/app_markdown_text.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tag.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_link.dart';
import 'package:skill_battles/core/presentation/widgets/question_illustration.dart';
import 'package:skill_battles/core/utils/feature_flags.dart';
import 'package:skill_battles/features/battle_result/domain/entity/battle_review_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/report_params_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/review_question_entity.dart';
import 'package:skill_battles/features/battle_result/domain/entity/review_round_entity.dart';
import 'package:skill_battles/features/battle_result/presentation/bloc/battle_result_bloc/battle_result_bloc.dart';
import 'package:skill_battles/features/battle_result/presentation/widgets/report_round_dialog.dart';

/// "Round review": the started rounds with server-gated details. Free
/// readers get their own choice, correctness and points; the correct
/// option, explanations and the opponent's choice come only for Pro.
final class RoundReviewList extends StatefulComponent {
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
    final List<ReviewRoundEntity> rounds = component.review.rounds;
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
      battleId: component.review.battleId,
      roundId: round.roundId,
      eyebrow: <String>[
        if (round.isOvertime) 'Overtime' else 'Round ${_roundNumber(round)}',
        if (component.disciplineName.isNotEmpty) component.disciplineName,
      ].join(' · '),
      prompt: round.question.question.prompt,
    );
    if (params != null) bloc.add(BattleResultReportSubmitted(params));
  }

  @override
  Component build(BuildContext context) {
    final BattleReviewEntity review = component.review;
    final bool isPro = review.answerAccess.canViewCorrectAnswer;
    return div(classes: 'round-review', <Component>[
      div(classes: 'round-review__header', <Component>[
        const h2(classes: 'round-review__title', <Component>[Component.text('Round review')]),
        const span(classes: 'round-review__legend', <Component>[Component.text('Base + speed + streak')]),
      ]),
      _ColumnHeader(
        opponentNickname: component.opponentNickname,
        mistakesToggle: component.canFilterMistakes
            ? Skeleton.ignore(child: _MistakesToggle(value: component.mistakesOnly))
            : null,
      ),
      if (review.rounds.isEmpty)
        p(classes: 'round-review__empty', <Component>[
          Component.text(component.mistakesOnly ? 'No mistakes in this match.' : 'No rounds were played.'),
        ]),
      for (final ReviewRoundEntity round in review.rounds)
        _RoundRow(
          key: ValueKey<String>(round.roundId),
          round: round,
          myUserId: review.myUserId,
          opponentId: component.opponentId,
          opponentNickname: component.opponentNickname,
          isPro: isPro,
          isExpanded: _expanded.contains(round.roundId),
          isReported: component.reportedRoundIds.contains(round.roundId),
          onTap: () => _toggle(round.roundId),
          onReport: () => _report(round),
        ),
    ]);
  }
}

/// `03` — the round number as the review and the report show it.
String _roundNumber(ReviewRoundEntity round) => round.number.toString().padLeft(2, '0');

/// `B · $60.00` — the letter and text (Markdown) of an option, `null` when
/// unknown.
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

final class _MistakesToggle extends StatelessComponent {
  const _MistakesToggle({required this.value});

  final bool value;

  @override
  Component build(BuildContext context) {
    return div(classes: 'round-review__toggle', <Component>[
      const span(
        classes: 'round-review__toggle-label',
        attributes: <String, String>{'aria-hidden': 'true'},
        <Component>[Component.text('Mistakes only')],
      ),
      button(
        classes: value ? 'review-switch review-switch--on' : 'review-switch',
        attributes: <String, String>{
          'role': 'switch',
          'aria-checked': '$value',
          'aria-label': 'Mistakes only',
        },
        onClick: () => context.read<BattleResultBloc>().add(BattleResultMistakesOnlyChanged(!value)),
        const <Component>[
          span(classes: 'review-switch__track', <Component>[
            span(classes: 'review-switch__thumb', <Component>[]),
          ]),
        ],
      ),
    ]);
  }
}

final class _ColumnHeader extends StatelessComponent {
  const _ColumnHeader({
    required this.opponentNickname,
    required this.mistakesToggle,
  });

  final String opponentNickname;
  final Component? mistakesToggle;

  @override
  Component build(BuildContext context) {
    final Component? toggle = mistakesToggle;
    return div(classes: 'round-review__columns', <Component>[
      div(classes: 'round-review__columns-start', <Component>[?toggle]),
      const span(classes: 'round-review__column', <Component>[Component.text('You')]),
      span(classes: 'round-review__column', <Component>[Component.text(opponentNickname)]),
    ]);
  }
}

final class _RoundRow extends StatelessComponent {
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
    super.key,
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
  Component build(BuildContext context) {
    final RoundAnswerEntity? mine = round.answerOf(myUserId);
    final RoundAnswerEntity? theirs = round.answerOf(opponentId);
    final String? explanation = round.question.explanation;
    final bool overtime = round.isOvertime && !isExpanded;
    return div(
      classes: <String>[
        'review-round',
        if (overtime) 'review-round--overtime',
        if (isExpanded) 'review-round--expanded',
      ].join(' '),
      <Component>[
        // `aria-expanded` goes on the button itself, so its name stays the
        // text of the row (number, prompt, points).
        Component.wrapElement(
          attributes: <String, String>{'aria-expanded': '$isExpanded'},
          child: AppTappable(
            onTap: onTap,
            radius: 14,
            classes: 'review-round__summary',
            child: _RoundSummary(round: round, mine: mine, theirs: theirs, isExpanded: isExpanded),
          ),
        ),
        if (isExpanded)
          div(classes: 'review-round__details', <Component>[
            div(classes: 'review-round__indented', <Component>[
              _AnswerTags(
                question: round.question,
                mine: mine,
                theirs: theirs,
                opponentNickname: opponentNickname,
                isPro: isPro,
                completed: round.completed,
              ),
            ]),
            if (explanation != null)
              div(classes: 'review-round__indented', <Component>[
                AppMarkdownText(
                  explanation,
                  style: AppTextStyles.bodyLg.combine(
                    const Styles(color: AppColors.inkSoft, lineHeight: Unit.pixels(24)),
                  ),
                ),
              ]),
            if (FeatureFlags.billing && !isPro) Skeleton.ignore(child: const _ProLockBar()),
            div(classes: 'review-round__indented', <Component>[
              if (isReported)
                const p(classes: 'review-round__reported', <Component>[Component.text('Reported — thanks.')])
              else
                AppTextLink(
                  label: 'Report a problem with this question',
                  style: AppTextStyles.bodySm.combine(
                    const Styles(color: AppColors.muted, fontWeight: FontWeight.w500),
                  ),
                  onPressed: onReport,
                ),
            ]),
          ]),
      ],
    );
  }
}

final class _RoundSummary extends StatelessComponent {
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
  Component build(BuildContext context) {
    final bool overtime = round.isOvertime;
    // The illustration belongs to the full question, so it is shown only in
    // the expanded row, above the prompt (the collapsed row is one line).
    final String? imageUrl = isExpanded ? round.question.question.imageUrl : null;
    final Component prompt = AppMarkdownLine(
      round.question.question.prompt,
      style: AppTextStyles.bodyLg.combine(
        Styles(fontWeight: isExpanded ? FontWeight.w600 : FontWeight.w500),
      ),
      maxLines: isExpanded ? 6 : 1,
      overflow: TextOverflow.ellipsis,
    );
    return div(
      classes: imageUrl == null ? 'review-round__line' : 'review-round__line review-round__line--top',
      <Component>[
        span(
          classes: 'review-round__number',
          styles: Styles(color: overtime ? AppColors.accentDeep : AppColors.muted),
          <Component>[Component.text(overtime ? 'OT' : _roundNumber(round))],
        ),
        div(classes: 'review-round__prompt', <Component>[
          if (imageUrl != null)
            QuestionIllustration(key: ValueKey<String>(imageUrl), imageUrl: imageUrl, maxHeight: 360),
          prompt,
        ]),
        _Points(answer: mine, isOvertime: overtime, earnedColor: AppColors.success),
        _Points(answer: theirs, isOvertime: overtime, earnedColor: AppColors.ink),
      ],
    );
  }
}

/// One 84 px points column: earned points in color, nothing earned faint.
final class _Points extends StatelessComponent {
  const _Points({
    required this.answer,
    required this.isOvertime,
    required this.earnedColor,
  });

  final RoundAnswerEntity? answer;
  final bool isOvertime;
  final Color earnedColor;

  @override
  Component build(BuildContext context) {
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
    return span(
      classes: 'review-round__points',
      styles: Styles(color: color),
      <Component>[Component.text(answer == null ? '—' : DisplayFormatters.points(points))],
    );
  }
}

/// "Correct: B · $66.00", "You: B · $60.00 · incorrect", "timur.b: correct".
/// Free readers get only their own choice and both players' correctness.
final class _AnswerTags extends StatelessComponent {
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
  Component build(BuildContext context) {
    final RoundAnswerEntity? theirs = this.theirs;
    final String? correct = isPro ? _optionLabel(question, question.correctOptionId) : null;
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
              ? '${MarkdownSpans.escape(opponentNickname)}: '
                    '${theirs.timedOut
                        ? 'no answer'
                        : theirCorrect
                        ? 'correct'
                        : 'incorrect'}'
              : '${MarkdownSpans.escape(opponentNickname)}: $theirPick',
          theirCorrect,
        ),
      if (!completed) ('Not finished', false),
    ];
    return div(classes: 'review-round__tags', <Component>[
      for (final (String label, bool good) in tags)
        AppTag(
          label: label,
          tone: good ? AppTagTone.success : AppTagTone.danger,
          foregroundColor: good ? null : AppColors.dangerText,
          style: AppTextStyles.bodySm.combine(const Styles(fontWeight: FontWeight.w500)),
          isMarkdown: true,
        ),
    ]);
  }
}

/// Free: the grey bar that sells the correct answer and explanation.
final class _ProLockBar extends StatelessComponent {
  const _ProLockBar();

  @override
  Component build(BuildContext context) {
    return div(classes: 'review-round__lock', <Component>[
      const AppSvgIcon(AppIcons.lock, width: 14, height: 14, color: AppColors.muted),
      const p(classes: 'review-round__lock-text', <Component>[
        Component.text('Correct answer, explanation and similar practice are in Pro.'),
      ]),
      AppTextLink(
        label: 'Unlock',
        style: AppTextStyles.bodySm.combine(
          const Styles(color: AppColors.accentDeep, fontWeight: FontWeight.w600),
        ),
        onPressed: context.goPro,
      ),
    ]);
  }
}

@css
List<StyleRule> get roundReviewListStyles => <StyleRule>[
  css('.round-review').styles(display: Display.flex, flexDirection: FlexDirection.column),
  css('.round-review__header').styles(
    display: Display.flex,
    margin: const Margin.only(bottom: Unit.pixels(12)),
    justifyContent: JustifyContent.spaceBetween,
    alignItems: AlignItems.baseline,
    gap: const Gap.column(Unit.pixels(16)),
  ),
  css('.round-review__title').combine(AppTextStyles.titleLg),
  css('.round-review__legend').combine(AppTextStyles.bodySm).combine(const Styles(color: AppColors.muted)),
  css('.round-review__columns').styles(
    display: Display.flex,
    margin: const Margin.only(bottom: Unit.pixels(6)),
    padding: const Padding.symmetric(horizontal: Unit.pixels(20)),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(16)),
  ),
  css('.round-review__columns-start').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    alignItems: AlignItems.center,
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.round-review__column')
      .styles(
        width: const Unit.pixels(84),
        overflow: Overflow.hidden,
        flex: const Flex(shrink: 0),
        textAlign: TextAlign.right,
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.bodyXs)
      .combine(const Styles(color: AppColors.muted, fontWeight: FontWeight.w500)),
  css('.round-review__empty')
      .styles(
        padding: const Padding.symmetric(vertical: Unit.pixels(32)),
        textAlign: TextAlign.center,
      )
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(color: AppColors.muted)),
  css('.round-review__toggle').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(8)),
  ),
  css('.round-review__toggle-label')
      .combine(AppTextStyles.bodyXs)
      .combine(const Styles(color: AppColors.muted, fontWeight: FontWeight.w500)),
  // Material 3 switch (52 × 32 track in a 60 × 48 target) drawn at 80 %;
  // like Flutter's `Transform.scale`, the scale does not change the layout.
  css('.review-switch').styles(
    display: Display.flex,
    width: const Unit.pixels(60),
    height: const Unit.pixels(48),
    padding: Padding.zero,
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
    cursor: Cursor.pointer,
    backgroundColor: Colors.transparent,
    raw: const <String, String>{'border': 'none'},
  ),
  css('.review-switch:focus-visible').styles(raw: const <String, String>{'outline': 'none'}),
  css('.review-switch__track').styles(
    display: Display.block,
    position: const Position.relative(),
    width: const Unit.pixels(52),
    height: const Unit.pixels(32),
    boxSizing: BoxSizing.borderBox,
    border: Border.all(color: AppColors.border, width: const Unit.pixels(2)),
    radius: const BorderRadius.circular(Unit.pixels(16)),
    transition: const Transition('background-color', duration: Duration(milliseconds: 200)),
    transform: const Transform.scale(0.8),
    backgroundColor: AppColors.white,
  ),
  css('.review-switch:focus-visible .review-switch__track').styles(
    raw: const <String, String>{'outline': '2px solid #2B4BF2', 'outline-offset': '3px'},
  ),
  css('.review-switch--on .review-switch__track').styles(
    border: Border.all(color: AppColors.primary, width: const Unit.pixels(2)),
    backgroundColor: AppColors.primary,
  ),
  css('.review-switch__thumb').styles(
    display: Display.block,
    position: const Position.absolute(top: Unit.pixels(6), left: Unit.pixels(6)),
    width: const Unit.pixels(16),
    height: const Unit.pixels(16),
    radius: const BorderRadius.circular(Unit.percent(50)),
    transition: const Transition('all', duration: Duration(milliseconds: 200)),
    backgroundColor: AppColors.border,
  ),
  css('.review-switch--on .review-switch__thumb').styles(
    position: const Position.absolute(top: Unit.pixels(2), left: Unit.pixels(22)),
    width: const Unit.pixels(24),
    height: const Unit.pixels(24),
    backgroundColor: AppColors.white,
  ),
  css('.review-round').styles(
    display: Display.flex,
    margin: const Margin.only(bottom: Unit.pixels(12)),
    border: Border.all(color: AppColors.border, width: const Unit.pixels(1)),
    radius: const BorderRadius.circular(Unit.pixels(14)),
    flexDirection: FlexDirection.column,
    backgroundColor: AppColors.white,
  ),
  css('.review-round--overtime').styles(
    border: Border.all(color: AppColors.accentRowBorder, width: const Unit.pixels(1)),
    backgroundColor: AppColors.accentRowSurface,
  ),
  // 1.5 px ink outline without moving the content.
  css('.review-round--expanded').styles(
    border: Border.all(color: AppColors.ink, width: const Unit.pixels(1)),
    raw: const <String, String>{'box-shadow': 'inset 0 0 0 0.5px #0E0F12'},
  ),
  css('.review-round__summary').styles(
    padding: const Padding.fromLTRB(Unit.pixels(19), Unit.pixels(17), Unit.pixels(19), Unit.pixels(17)),
  ),
  css('.review-round--expanded .review-round__summary').styles(
    padding: const Padding.fromLTRB(Unit.pixels(19), Unit.pixels(19), Unit.pixels(19), Unit.pixels(17)),
  ),
  css('.review-round__line').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(16)),
  ),
  css('.review-round__line--top').styles(alignItems: AlignItems.start),
  css('.review-round__number')
      .styles(width: const Unit.pixels(28), flex: const Flex(shrink: 0))
      .combine(AppTextStyles.monoBodySm)
      .combine(const Styles(fontWeight: FontWeight.w600)),
  css('.review-round__prompt').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.stretch,
    gap: const Gap.row(Unit.pixels(14)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.review-round__points')
      .styles(
        width: const Unit.pixels(84),
        flex: const Flex(shrink: 0),
        textAlign: TextAlign.right,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.monoBodyMd),
  css('.review-round__details').styles(
    display: Display.flex,
    padding: const Padding.fromLTRB(Unit.pixels(19), Unit.zero, Unit.pixels(19), Unit.pixels(19)),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(14)),
  ),
  css('.review-round__indented').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    padding: const Padding.only(left: Unit.pixels(44)),
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
  ),
  css('.review-round__indented > .md-text').styles(alignSelf: AlignSelf.stretch),
  css('.review-round__tags').styles(
    display: Display.flex,
    flexWrap: FlexWrap.wrap,
    gap: const Gap.all(Unit.pixels(8)),
  ),
  css('.review-round__reported')
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.success, fontWeight: FontWeight.w500)),
  css('.review-round__lock').styles(
    display: Display.flex,
    padding: const Padding.symmetric(horizontal: Unit.pixels(14), vertical: Unit.pixels(12)),
    radius: const BorderRadius.circular(Unit.pixels(10)),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(10)),
    backgroundColor: AppColors.surface,
  ),
  css('.review-round__lock-text')
      .styles(
        minWidth: Unit.zero,
        flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
      )
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.inkSoft, lineHeight: Unit.pixels(18))),
];
