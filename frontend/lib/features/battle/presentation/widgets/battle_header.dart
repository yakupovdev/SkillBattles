import 'package:material_ui/material_ui.dart';

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
final class BattleHeader extends StatelessWidget {
  const BattleHeader({
    required this.snapshot,
    this.youTrailing,
    this.opponentNameLeading,
    super.key,
  });

  final BattleSnapshotEntity snapshot;

  /// Placed right after your name column (the sticker trigger).
  final Widget? youTrailing;

  /// Placed before the opponent's nickname (the "stickers hidden" eye).
  final Widget? opponentNameLeading;

  static const double _sideMaxWidth = 420;

  @override
  Widget build(BuildContext context) {
    final BattlePlayerEntity me = snapshot.me;
    final BattlePlayerEntity opponent = snapshot.opponent;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        height: 104,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 64),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _sideMaxWidth,
                        ),
                        child: _PlayerBlock(
                          player: me,
                          isYou: true,
                          trailing: youTrailing,
                          showCorrectCount: _showCorrectCount(snapshot),
                        ),
                      ),
                    ),
                  ),
                  _RoundInfo(snapshot: snapshot),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _sideMaxWidth,
                        ),
                        child: _PlayerBlock(
                          player: opponent,
                          isYou: false,
                          nameLeading: opponentNameLeading,
                          status: _opponentStatus(snapshot, opponent),
                          statusPoints: _opponentPoints(snapshot, opponent),
                          showCorrectCount: _showCorrectCount(snapshot),
                          clockOffset: snapshot.clockOffset,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Without a streak, the line under the name counts correct answers once
  /// a round has been revealed (Paper: "4 correct" in overtime).
  static bool _showCorrectCount(BattleSnapshotEntity snapshot) {
    final BattleRoundEntity? round = snapshot.round;
    if (round == null) return false;
    return round.isOvertime ||
        round.number > 1 ||
        snapshot.phase == BattlePhase.reveal;
  }

  static int? _opponentPoints(
    BattleSnapshotEntity snapshot,
    BattlePlayerEntity opponent,
  ) {
    final BattleRoundEntity? round = snapshot.round;
    if (snapshot.phase != BattlePhase.reveal || round?.isOvertime != false) {
      return null;
    }
    final RoundAnswerEntity? answer = round!.reveal?.answerOf(opponent.id);
    return (answer?.correct ?? false) ? answer!.points : null;
  }

  static _OpponentStatus? _opponentStatus(
    BattleSnapshotEntity snapshot,
    BattlePlayerEntity opponent,
  ) {
    if (!opponent.connected) return _OpponentStatus.reconnecting;
    final BattleRoundEntity? round = snapshot.round;
    if (snapshot.phase == BattlePhase.reveal && round?.reveal != null) {
      final RoundAnswerEntity? answer = round!.reveal!.answerOf(opponent.id);
      if (answer == null || answer.timedOut) return _OpponentStatus.timedOut;
      return answer.correct ? _OpponentStatus.correct : _OpponentStatus.wrong;
    }
    if (snapshot.phase == BattlePhase.question) {
      return opponent.answeredCurrentRound
          ? _OpponentStatus.answered
          : _OpponentStatus.thinking;
    }
    return null;
  }
}

enum _OpponentStatus {
  thinking,
  answered,
  correct,
  wrong,
  timedOut,
  reconnecting,
}

final class _PlayerBlock extends StatelessWidget {
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
  final Widget? trailing;

  /// Opponent block only: icon before the nickname.
  final Widget? nameLeading;
  final _OpponentStatus? status;

  /// Points of a correct revealed answer ("Correct · +1,116").
  final int? statusPoints;
  final Duration clockOffset;

  @override
  Widget build(BuildContext context) {
    final Widget avatar = AppAvatar(
      nickname: player.nickname,
      size: AppAvatarSize.lg,
      tone: isYou ? AppAvatarTone.primary : AppAvatarTone.accent,
    );
    final Widget score = Text(
      DisplayFormatters.grouped(player.score),
      style: AppTextStyles.monoLg,
    );
    final _OpponentStatus? status = this.status;
    final Widget? subline = status != null
        ? _StatusPill(
            status: status,
            points: statusPoints,
            reconnectDeadline: player.reconnectDeadline,
            clockOffset: clockOffset,
          )
        : player.streak > 0
        ? _Streak(streak: player.streak)
        : showCorrectCount
        ? Text(
            '${player.correctCount} correct',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
            ),
          )
        : null;
    final Widget infoColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isYou
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      spacing: 2,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: <Widget>[
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ?nameLeading,
                  Flexible(
                    child: Text(
                      player.nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.buttonLg,
                    ),
                  ),
                ],
              ),
            ),
            if (player.isPro) const ProBadge(compact: true),
          ],
        ),
        ?subline,
      ],
    );
    return Row(
      spacing: 14,
      children: isYou
          ? <Widget>[
              avatar,
              // Loose fit, so the trigger sits right after the name; the
              // spacer keeps the score at the edge.
              Flexible(child: infoColumn),
              ?trailing,
              const Spacer(),
              score,
            ]
          : <Widget>[score, Expanded(child: infoColumn), avatar],
    );
  }
}

final class _Streak extends StatelessWidget {
  const _Streak({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: <Widget>[
        const AppSvgIcon(AppIcons.flame, width: 12, height: 14),
        Text(
          '$streak in a row',
          style: AppTextStyles.bodySm.copyWith(
            color: AppColors.accentText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

final class _StatusPill extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTextStyles.bodyXs.copyWith(
      fontWeight: FontWeight.w600,
    );
    const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 8, vertical: 2);
    final DateTime? deadline = reconnectDeadline;
    if (status == _OpponentStatus.reconnecting && deadline != null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.accentSurface,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Padding(
          padding: padding,
          child: AppCountdownText(
            target: deadline,
            clockOffset: clockOffset,
            prefix: 'Reconnecting · ',
            style: style.copyWith(color: AppColors.accentText),
          ),
        ),
      );
    }
    final (String label, AppTagTone tone, Widget? leading) = switch (status) {
      _OpponentStatus.thinking => ('Thinking…', AppTagTone.neutral, null),
      _OpponentStatus.answered => (
        'Answered',
        AppTagTone.success,
        const AppSvgIcon(AppIcons.checkSmall, width: 10, height: 10),
      ),
      _OpponentStatus.correct => (
        points == null
            ? 'Correct'
            : 'Correct · ${DisplayFormatters.points(points!)}',
        AppTagTone.success,
        const AppSvgIcon(AppIcons.checkSmall, width: 10, height: 10),
      ),
      _OpponentStatus.wrong => ('Wrong', AppTagTone.danger, null),
      _OpponentStatus.timedOut => ("Time's up", AppTagTone.danger, null),
      _OpponentStatus.reconnecting => (
        'Reconnecting',
        AppTagTone.neutral,
        null,
      ),
    };
    return AppTag(
      label: label,
      tone: tone,
      isPill: true,
      padding: padding,
      style: style,
      leading: leading,
    );
  }
}

final class _RoundInfo extends StatelessWidget {
  const _RoundInfo({required this.snapshot});

  final BattleSnapshotEntity snapshot;

  @override
  Widget build(BuildContext context) {
    final BattleRoundEntity? round = snapshot.round;
    final int count = snapshot.questionCount;
    final int current = round?.number ?? 0;
    final bool overtime = round?.isOvertime ?? false;
    final String discipline = formatDisciplineCode(snapshot.disciplineCode);
    final String phase = snapshot.phase == BattlePhase.reveal
        ? ' · Reveal'
        : '';
    final TextStyle style = AppTextStyles.eyebrow;
    final InlineSpan title = round == null
        ? TextSpan(text: '$discipline · ${snapshot.mode.label}'.toUpperCase())
        : overtime
        ? TextSpan(
            children: <InlineSpan>[
              TextSpan(text: '$discipline · '.toUpperCase()),
              TextSpan(
                text: 'Overtime$phase'.toUpperCase(),
                style: style.copyWith(
                  color: AppColors.accentDeep,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          )
        : TextSpan(
            text: '$discipline · Round $current of $count$phase'.toUpperCase(),
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: <Widget>[
        Text.rich(title, style: style),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: <Widget>[
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
      ],
    );
  }
}

final class _RoundPip extends StatelessWidget {
  const _RoundPip({required this.color, this.width = 36});

  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
