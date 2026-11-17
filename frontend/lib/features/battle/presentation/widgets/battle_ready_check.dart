import 'package:bloc_signals_jaspr/bloc_signals_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

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
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_player_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_snapshot_entity.dart';
import 'package:skill_battles/features/battle/presentation/bloc/battle_bloc/battle_bloc.dart';

/// WAITING_READY: both players confirm within the ready window. The
/// difficulty grid is never shown in advance.
final class BattleReadyCheck extends StatelessComponent {
  const BattleReadyCheck({required this.snapshot, required this.state, required this.onLeave, super.key});

  final BattleSnapshotEntity snapshot;
  final BattleState state;
  final VoidCallback onLeave;

  @override
  Component build(BuildContext context) {
    final BattlePlayerEntity me = snapshot.me;
    final DateTime? deadline = snapshot.readyDeadline;
    final bool isRanked = snapshot.mode == BattleMode.ranked;
    final bool usesQuota = isRanked && !snapshot.entitlements.unlimitedRanked;
    final bool connected = state.connection == RealtimeStatus.connected;
    final Failure? readyFailure = state.readyFailure;
    return div(classes: 'battle-ready', <Component>[
      div(classes: 'battle-ready__card', <Component>[
        div(classes: 'battle-ready__heading', <Component>[
          AppEyebrow(
            '${formatDisciplineCode(snapshot.disciplineCode)} · ${snapshot.mode.label}',
            color: AppColors.primary,
          ),
          div(classes: 'battle-ready__title-row', <Component>[
            const h2(classes: 'battle-ready__title', <Component>[Component.text('Ready check')]),
            if (deadline != null)
              AppCountdownText(
                target: deadline,
                clockOffset: snapshot.clockOffset,
                suffix: ' left',
                style: AppTextStyles.monoBodySm.combine(const Styles(color: AppColors.muted)),
              ),
          ]),
        ]),
        div(classes: 'battle-ready__players', <Component>[
          for (final BattlePlayerEntity player in snapshot.players)
            _PlayerRow(player: player, isYou: player.id == snapshot.myUserId),
        ]),
        if (usesQuota)
          const AppNotice(message: 'This uses one of your free ranked matches when the first question opens.'),
        if (snapshot.mode == BattleMode.private)
          const AppNotice(message: 'Private duel · no rating change.', tone: AppNoticeTone.warning),
        if (!connected) const AppNotice(message: 'Connecting to live updates…', tone: AppNoticeTone.warning),
        if (readyFailure != null) ...<Component>[
          AppInlineError(readyFailure.playMessage(DateTime.now())),
          if (readyFailure.isDailyLimit)
            AppTextLink(
              label: 'See Pro plans',
              style: AppTextStyles.bodySm.combine(
                const Styles(color: AppColors.primary, fontWeight: FontWeight.w500),
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
              : () => context.read<BattleBloc>().add(const BattleReadyPressed()),
        ),
        div(classes: 'battle-ready__leave', <Component>[
          AppTextLink(
            label: 'Leave match',
            style: AppTextStyles.bodyMd.combine(const Styles(color: AppColors.muted, fontWeight: FontWeight.w500)),
            onPressed: state.surrenderStatus.isLoading ? null : onLeave,
          ),
        ]),
      ]),
    ]);
  }
}

final class _PlayerRow extends StatelessComponent {
  const _PlayerRow({required this.player, required this.isYou});

  final BattlePlayerEntity player;
  final bool isYou;

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'battle-ready__player',
      styles: Styles(backgroundColor: isYou ? AppColors.primarySurface : AppColors.accentSurface),
      <Component>[
        AppAvatar(
          nickname: player.nickname,
          size: AppAvatarSize.md,
          tone: isYou ? AppAvatarTone.primary : AppAvatarTone.accent,
        ),
        div(classes: 'battle-ready__player-info', <Component>[
          div(classes: 'battle-ready__player-line', <Component>[
            span(classes: 'battle-ready__player-name', <Component>[
              Component.text(isYou ? '${player.nickname} (you)' : player.nickname),
            ]),
            if (player.isPro) const ProBadge(),
          ]),
          div(classes: 'battle-ready__player-line battle-ready__player-line--caption', <Component>[
            AppDot(color: player.connected ? AppColors.success : AppColors.faint, size: 7),
            span(classes: 'battle-ready__player-caption', <Component>[
              Component.text(
                '${player.rating} · ${formatRankCode(player.rankCode)}'
                '${player.connected ? '' : ' · offline'}',
              ),
            ]),
          ]),
        ]),
        span(
          classes: 'battle-ready__player-status',
          styles: Styles(color: player.ready ? AppColors.success : AppColors.faint),
          <Component>[Component.text(player.ready ? 'Ready' : 'Waiting…')],
        ),
      ],
    );
  }
}

@css
List<StyleRule> get battleReadyCheckStyles => <StyleRule>[
  css('.battle-ready').styles(
    display: Display.flex,
    padding: const Padding.symmetric(horizontal: Unit.pixels(32), vertical: Unit.pixels(56)),
    justifyContent: JustifyContent.center,
  ),
  css('.battle-ready__card').styles(
    display: Display.flex,
    width: const Unit.percent(100),
    maxWidth: const Unit.pixels(520),
    padding: const Padding.all(Unit.pixels(32)),
    boxSizing: BoxSizing.borderBox,
    border: Border.all(color: AppColors.border, width: const Unit.pixels(1)),
    radius: const BorderRadius.circular(Unit.pixels(20)),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(24)),
  ),
  css('.battle-ready__heading').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(6)),
  ),
  css('.battle-ready__title-row').styles(
    display: Display.flex,
    justifyContent: JustifyContent.spaceBetween,
    alignItems: AlignItems.center,
  ),
  css('.battle-ready__title').combine(AppTextStyles.titleLg),
  css('.battle-ready__players').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(12)),
  ),
  css('.battle-ready__player').styles(
    display: Display.flex,
    padding: const Padding.all(Unit.pixels(16)),
    radius: const BorderRadius.circular(Unit.pixels(12)),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(14)),
  ),
  css('.battle-ready__player-info').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(2)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.battle-ready__player-line').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(8)),
  ),
  css('.battle-ready__player-line--caption').styles(gap: const Gap.column(Unit.pixels(6))),
  css('.battle-ready__player-name')
      .styles(
        minWidth: Unit.zero,
        overflow: Overflow.hidden,
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.bodyLg)
      .combine(const Styles(fontWeight: FontWeight.w600)),
  css('.battle-ready__player-caption')
      .styles(
        minWidth: Unit.zero,
        overflow: Overflow.hidden,
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.muted)),
  css('.battle-ready__player-status')
      .styles(width: const Unit.pixels(72), flex: const Flex(shrink: 0))
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(textAlign: TextAlign.right, fontWeight: FontWeight.w600)),
  css('.battle-ready__leave').styles(display: Display.flex, justifyContent: JustifyContent.center),
];
