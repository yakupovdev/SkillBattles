import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/battle_mode.dart';
import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/core/presentation/extensions/play_failure_message.dart';
import 'package:skill_battles/core/presentation/widgets/app_avatar.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_countdown_text.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_notice.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_link.dart';
import 'package:skill_battles/core/presentation/widgets/pro_badge.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_player_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_snapshot_entity.dart';
import 'package:skill_battles/features/battle/presentation/bloc/battle_bloc/battle_bloc.dart';

/// WAITING_READY: both players confirm within the ready window. The
/// difficulty grid is never shown in advance.
final class BattleReadyCheck extends StatelessWidget {
  const BattleReadyCheck({
    required this.snapshot,
    required this.state,
    required this.onLeave,
    super.key,
  });

  final BattleSnapshotEntity snapshot;
  final BattleState state;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final BattlePlayerEntity me = snapshot.me;
    final DateTime? deadline = snapshot.readyDeadline;
    final bool isRanked = snapshot.mode == BattleMode.ranked;
    final bool usesQuota = isRanked && !snapshot.entitlements.unlimitedRanked;
    final bool connected = state.connection == RealtimeStatus.connected;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 24,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 6,
                    children: <Widget>[
                      AppEyebrow(
                        '${formatDisciplineCode(snapshot.disciplineCode)} · '
                        '${snapshot.mode.label}',
                        color: AppColors.primary,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text(
                            'Ready check',
                            style: AppTextStyles.titleLg,
                          ),
                          if (deadline != null)
                            AppCountdownText(
                              target: deadline,
                              clockOffset: snapshot.clockOffset,
                              suffix: ' left',
                              style: AppTextStyles.monoBodySm.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    spacing: 12,
                    children: <Widget>[
                      for (final BattlePlayerEntity player in snapshot.players)
                        _PlayerRow(
                          player: player,
                          isYou: player.id == snapshot.myUserId,
                        ),
                    ],
                  ),
                  if (usesQuota)
                    const AppNotice(
                      message:
                          'This uses one of your free ranked matches when the '
                          'first question opens.',
                    ),
                  if (snapshot.mode == BattleMode.private)
                    const AppNotice(
                      message: 'Private duel · no rating change.',
                      tone: AppNoticeTone.warning,
                    ),
                  if (!connected)
                    const AppNotice(
                      message: 'Connecting to live updates…',
                      tone: AppNoticeTone.warning,
                    ),
                  if (state.readyFailure != null) ...<Widget>[
                    AppInlineError(
                      state.readyFailure!.playMessage(DateTime.now()),
                    ),
                    if (state.readyFailure!.isDailyLimit)
                      AppTextLink(
                        label: 'See Pro plans',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        onPressed: context.goPro,
                      ),
                  ],
                  AppButton(
                    label: me.ready
                        ? 'Ready — waiting for opponent'
                        : state.readyStatus.isLoading
                        ? 'Confirming…'
                        : "I'm ready",
                    expand: true,
                    onPressed: me.ready || state.readyStatus.isLoading
                        ? null
                        : () => context.read<BattleBloc>().add(
                            const BattleReadyPressed(),
                          ),
                  ),
                  Center(
                    child: AppTextLink(
                      label: 'Leave match',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                      onPressed: state.surrenderStatus.isLoading
                          ? null
                          : onLeave,
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
}

final class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player, required this.isYou});

  final BattlePlayerEntity player;
  final bool isYou;

  @override
  Widget build(BuildContext context) {
    final TextStyle caption = AppTextStyles.bodySm.copyWith(
      color: AppColors.muted,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isYou ? AppColors.primarySurface : AppColors.accentSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          spacing: 14,
          children: <Widget>[
            AppAvatar(
              nickname: player.nickname,
              size: AppAvatarSize.md,
              tone: isYou ? AppAvatarTone.primary : AppAvatarTone.accent,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: <Widget>[
                  Row(
                    spacing: 8,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          isYou ? '${player.nickname} (you)' : player.nickname,
                          style: AppTextStyles.bodyLg.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (player.isPro) const ProBadge(),
                    ],
                  ),
                  Row(
                    spacing: 6,
                    children: <Widget>[
                      AppDot(
                        color: player.connected
                            ? AppColors.success
                            : AppColors.faint,
                        size: 7,
                      ),
                      Flexible(
                        child: Text(
                          '${player.rating} · ${formatRankCode(player.rankCode)}'
                          '${player.connected ? '' : ' · offline'}',
                          style: caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 72,
              child: Text(
                player.ready ? 'Ready' : 'Waiting…',
                textAlign: TextAlign.right,
                style: AppTextStyles.bodySm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: player.ready ? AppColors.success : AppColors.faint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
