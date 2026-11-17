import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/round_answer_entity.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/widgets/app_avatar.dart';
import 'package:skill_battles/core/presentation/widgets/app_countdown_text.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tag.dart';
import 'package:skill_battles/core/presentation/widgets/pro_badge.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_phase.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_player_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_round_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_snapshot_entity.dart';

/// 104-high header: you, round info, opponent. Scores include revealed
/// rounds only; the opponent's correctness appears only after the reveal.
final class BattleHeader extends StatelessComponent {
  const BattleHeader({required this.snapshot, this.youTrailing, this.opponentNameLeading, super.key});

  final BattleSnapshotEntity snapshot;

  /// Placed right after your name column (the sticker trigger).
  final Component? youTrailing;

  /// Placed before the opponent's nickname (the "stickers hidden" eye).
  final Component? opponentNameLeading;

  @override
  Component build(BuildContext context) {
    final BattlePlayerEntity me = snapshot.me;
    final BattlePlayerEntity opponent = snapshot.opponent;
    return header(classes: 'battle-header', <Component>[
      div(classes: 'battle-header__inner', <Component>[
        div(classes: 'battle-header__side battle-header__side--you', <Component>[
          _PlayerBlock(
            player: me,
            isYou: true,
            trailing: youTrailing,
            showCorrectCount: _showCorrectCount(snapshot),
          ),
        ]),
        _RoundInfo(snapshot: snapshot),
        div(classes: 'battle-header__side battle-header__side--opponent', <Component>[
          _PlayerBlock(
            player: opponent,
            isYou: false,
            nameLeading: opponentNameLeading,
            status: _opponentStatus(snapshot, opponent),
            statusPoints: _opponentPoints(snapshot, opponent),
            showCorrectCount: _showCorrectCount(snapshot),
            clockOffset: snapshot.clockOffset,
          ),
        ]),
      ]),
    ]);
  }

  /// Without a streak, the line under the name counts correct answers once
  /// a round has been revealed (Paper: "4 correct" in overtime).
  static bool _showCorrectCount(BattleSnapshotEntity snapshot) {
    final BattleRoundEntity? round = snapshot.round;
    if (round == null) return false;
    return round.isOvertime || round.number > 1 || snapshot.phase == BattlePhase.reveal;
  }

  static int? _opponentPoints(BattleSnapshotEntity snapshot, BattlePlayerEntity opponent) {
    final BattleRoundEntity? round = snapshot.round;
    if (snapshot.phase != BattlePhase.reveal || round?.isOvertime != false) {
      return null;
    }
    final RoundAnswerEntity? answer = round!.reveal?.answerOf(opponent.id);
    return (answer?.correct ?? false) ? answer!.points : null;
  }

  static _OpponentStatus? _opponentStatus(BattleSnapshotEntity snapshot, BattlePlayerEntity opponent) {
    if (!opponent.connected) return _OpponentStatus.reconnecting;
    final BattleRoundEntity? round = snapshot.round;
    if (snapshot.phase == BattlePhase.reveal && round?.reveal != null) {
      final RoundAnswerEntity? answer = round!.reveal!.answerOf(opponent.id);
      if (answer == null || answer.timedOut) return _OpponentStatus.timedOut;
      return answer.correct ? _OpponentStatus.correct : _OpponentStatus.wrong;
    }
    if (snapshot.phase == BattlePhase.question) {
      return opponent.answeredCurrentRound ? _OpponentStatus.answered : _OpponentStatus.thinking;
    }
    return null;
  }
}

enum _OpponentStatus { thinking, answered, correct, wrong, timedOut, reconnecting }

final class _PlayerBlock extends StatelessComponent {
  const _PlayerBlock({
    required this.player,
    required this.isYou,
    required this.showCorrectCount,
    this.trailing,
    this.nameLeading,
    this.status,
    this.statusPoints,
    this.clockOffset = Duration.zero,
  });

  final BattlePlayerEntity player;
  final bool isYou;
  final bool showCorrectCount;

  /// Your block only: the sticker trigger after the name column.
  final Component? trailing;

  /// Opponent block only: icon before the nickname.
  final Component? nameLeading;
  final _OpponentStatus? status;

  /// Points of a correct revealed answer ("Correct · +1,116").
  final int? statusPoints;
  final Duration clockOffset;

  @override
  Component build(BuildContext context) {
    final Component avatar = AppAvatar(
      nickname: player.nickname,
      size: AppAvatarSize.lg,
      tone: isYou ? AppAvatarTone.primary : AppAvatarTone.accent,
    );
    final Component score = span(classes: 'battle-player__score', <Component>[
      Component.text(DisplayFormatters.grouped(player.score)),
    ]);
    final _OpponentStatus? status = this.status;
    final Component? subline = status != null
        ? _StatusPill(
            status: status,
            points: statusPoints,
            reconnectDeadline: player.reconnectDeadline,
            clockOffset: clockOffset,
          )
        : player.streak > 0
        ? _Streak(streak: player.streak)
        : showCorrectCount
        ? p(classes: 'battle-player__correct', <Component>[Component.text('${player.correctCount} correct')])
        : null;
    final Component info = div(
      classes: isYou ? 'battle-player__info' : 'battle-player__info battle-player__info--end',
      <Component>[
        div(classes: 'battle-player__name-row', <Component>[
          div(classes: 'battle-player__name-wrap', <Component>[
            ?nameLeading,
            span(classes: 'battle-player__name', <Component>[Component.text(player.nickname)]),
          ]),
          if (player.isPro) const ProBadge(compact: true),
        ]),
        ?subline,
      ],
    );
    return div(
      classes: isYou ? 'battle-player' : 'battle-player battle-player--opponent',
      isYou
          ? <Component>[
              avatar,
              // Hugs its content, so the trigger sits right after the name;
              // the spacer keeps the score at the edge.
              info,
              ?trailing,
              const span(classes: 'battle-player__spacer', <Component>[]),
              score,
            ]
          : <Component>[score, info, avatar],
    );
  }
}

final class _Streak extends StatelessComponent {
  const _Streak({required this.streak});

  final int streak;

  @override
  Component build(BuildContext context) {
    return div(classes: 'battle-player__streak', <Component>[
      const AppSvgIcon(AppIcons.flame, width: 12, height: 14),
      span(<Component>[Component.text('$streak in a row')]),
    ]);
  }
}

final class _StatusPill extends StatelessComponent {
  const _StatusPill({
    required this.status,
    required this.points,
    required this.reconnectDeadline,
    required this.clockOffset,
  });

  final _OpponentStatus status;
  final int? points;
  final DateTime? reconnectDeadline;
  final Duration clockOffset;

  static const Styles _style = Styles(fontWeight: FontWeight.w600);

  static const Padding _padding = Padding.symmetric(horizontal: Unit.pixels(8), vertical: Unit.pixels(2));

  @override
  Component build(BuildContext context) {
    final Styles style = AppTextStyles.bodyXs.combine(_style);
    final DateTime? deadline = reconnectDeadline;
    if (status == _OpponentStatus.reconnecting && deadline != null) {
      return span(classes: 'battle-player__reconnecting', <Component>[
        AppCountdownText(
          target: deadline,
          clockOffset: clockOffset,
          prefix: 'Reconnecting · ',
          style: style.combine(const Styles(color: AppColors.accentText)),
        ),
      ]);
    }
    final int? points = this.points;
    final (String label, AppTagTone tone, Component? leading) = switch (status) {
      _OpponentStatus.thinking => ('Thinking…', AppTagTone.neutral, null),
      _OpponentStatus.answered => (
        'Answered',
        AppTagTone.success,
        const AppSvgIcon(AppIcons.checkSmall, width: 10, height: 10),
      ),
      _OpponentStatus.correct => (
        points == null ? 'Correct' : 'Correct · ${DisplayFormatters.points(points)}',
        AppTagTone.success,
        const AppSvgIcon(AppIcons.checkSmall, width: 10, height: 10),
      ),
      _OpponentStatus.wrong => ('Wrong', AppTagTone.danger, null),
      _OpponentStatus.timedOut => ("Time's up", AppTagTone.danger, null),
      _OpponentStatus.reconnecting => ('Reconnecting', AppTagTone.neutral, null),
    };
    return AppTag(label: label, tone: tone, isPill: true, padding: _padding, style: style, leading: leading);
  }
}

final class _RoundInfo extends StatelessComponent {
  const _RoundInfo({required this.snapshot});

  final BattleSnapshotEntity snapshot;

  @override
  Component build(BuildContext context) {
    final BattleRoundEntity? round = snapshot.round;
    final int count = snapshot.questionCount;
    final int current = round?.number ?? 0;
    final bool overtime = round?.isOvertime ?? false;
    final String discipline = formatDisciplineCode(snapshot.disciplineCode);
    final String phase = snapshot.phase == BattlePhase.reveal ? ' · Reveal' : '';
    return div(classes: 'battle-round-info', <Component>[
      p(classes: 'battle-round-info__title', <Component>[
        if (round == null)
          Component.text('$discipline · ${snapshot.mode.label}'.toUpperCase())
        else if (overtime) ...<Component>[
          Component.text('$discipline · '.toUpperCase()),
          span(classes: 'battle-round-info__overtime', <Component>[
            Component.text('Overtime$phase'.toUpperCase()),
          ]),
        ] else
          Component.text('$discipline · Round $current of $count$phase'.toUpperCase()),
      ]),
      div(
        classes: 'battle-round-info__pips',
        attributes: const <String, String>{'aria-hidden': 'true'},
        <Component>[
          for (int i = 1; i <= count; i++)
            _RoundPip(
              color: overtime || i < current
                  ? AppColors.ink
                  : i == current
                  ? AppColors.primary
                  : AppColors.border,
            ),
          if (overtime) const _RoundPip(color: AppColors.accent, width: 16),
        ],
      ),
    ]);
  }
}

final class _RoundPip extends StatelessComponent {
  const _RoundPip({required this.color, this.width = 36});

  final Color color;
  final double width;

  @override
  Component build(BuildContext context) {
    return span(
      classes: 'battle-round-info__pip',
      styles: Styles(width: Unit.pixels(width), backgroundColor: color),
      const <Component>[],
    );
  }
}

@css
List<StyleRule> get battleHeaderStyles => <StyleRule>[
  css('.battle-header').styles(
    display: Display.flex,
    height: const Unit.pixels(104),
    boxSizing: BoxSizing.borderBox,
    justifyContent: JustifyContent.center,
    flex: const Flex(shrink: 0),
    raw: <String, String>{'border-bottom': '1px solid ${AppColors.border.value}'},
  ),
  css('.battle-header__inner').styles(
    display: Display.flex,
    width: const Unit.percent(100),
    maxWidth: const Unit.pixels(1440),
    padding: const Padding.symmetric(horizontal: Unit.pixels(64)),
    boxSizing: BoxSizing.borderBox,
    alignItems: AlignItems.center,
  ),
  css('.battle-header__side').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    alignItems: AlignItems.center,
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.battle-header__side--you').styles(justifyContent: JustifyContent.start),
  css('.battle-header__side--opponent').styles(justifyContent: JustifyContent.end),
  css('.battle-player').styles(
    display: Display.flex,
    width: const Unit.percent(100),
    minWidth: Unit.zero,
    maxWidth: const Unit.pixels(420),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(14)),
  ),
  css('.battle-player__score').combine(AppTextStyles.monoLg).combine(const Styles(flex: Flex(shrink: 0))),
  css('.battle-player__spacer').styles(flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero)),
  css('.battle-player__info').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(2)),
    flex: const Flex(grow: 0, shrink: 1, basis: Unit.auto),
  ),
  css('.battle-player__info--end').styles(
    alignItems: AlignItems.end,
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.battle-player__name-row').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    maxWidth: const Unit.percent(100),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(6)),
  ),
  css('.battle-player__name-wrap').styles(display: Display.flex, minWidth: Unit.zero, alignItems: AlignItems.center),
  css('.battle-player__name')
      .styles(
        minWidth: Unit.zero,
        overflow: Overflow.hidden,
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.buttonLg),
  css('.battle-player__correct')
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.muted, fontWeight: FontWeight.w500)),
  css('.battle-player__streak').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(6)),
  ),
  css('.battle-player__streak span')
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.accentText, fontWeight: FontWeight.w500)),
  css('.battle-player__reconnecting').styles(
    display: Display.inlineBlock,
    padding: const Padding.symmetric(horizontal: Unit.pixels(8), vertical: Unit.pixels(2)),
    radius: const BorderRadius.circular(Unit.pixels(99)),
    backgroundColor: AppColors.accentSurface,
  ),
  css('.battle-round-info').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.center,
    gap: const Gap.row(Unit.pixels(10)),
    flex: const Flex(shrink: 0),
  ),
  css('.battle-round-info__title').combine(AppTextStyles.eyebrow),
  css('.battle-round-info__overtime').styles(color: AppColors.accentDeep, fontWeight: FontWeight.w700),
  css('.battle-round-info__pips').styles(display: Display.flex, gap: const Gap.column(Unit.pixels(6))),
  css('.battle-round-info__pip').styles(
    display: Display.block,
    height: const Unit.pixels(6),
    radius: const BorderRadius.circular(Unit.pixels(3)),
  ),
];
