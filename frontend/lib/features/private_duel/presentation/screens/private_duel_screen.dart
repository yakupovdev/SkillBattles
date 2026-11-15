import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/public_player_entity.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/core/presentation/extensions/play_failure_message.dart';
import 'package:skill_battles/core/presentation/widgets/app_avatar.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_countdown_text.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_notice.dart';
import 'package:skill_battles/core/presentation/widgets/app_status_view.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_link.dart';
import 'package:skill_battles/core/presentation/widgets/pro_badge.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/core/utils/extensions/go_router_extension.dart';
import 'package:skill_battles/features/friends/presentation/widgets/room_invitation_section.dart';
import 'package:skill_battles/features/notifications/presentation/bloc/notification_bloc/notification_bloc.dart';
import 'package:skill_battles/features/private_duel/domain/entity/duel_entity.dart';
import 'package:skill_battles/features/private_duel/domain/entity/duel_status.dart';
import 'package:skill_battles/features/private_duel/domain/usecases/cancel_duel_usecase.dart';
import 'package:skill_battles/features/private_duel/domain/usecases/create_duel_usecase.dart';
import 'package:skill_battles/features/private_duel/domain/usecases/get_duel_usecase.dart';
import 'package:skill_battles/features/private_duel/domain/usecases/watch_duel_usecase.dart';
import 'package:skill_battles/features/private_duel/presentation/bloc/private_duel_bloc/private_duel_bloc.dart';

/// The host's private code room (Paper: "04 Private Duel"). Unlimited for
/// every plan; never changes Elo. Both players pass Ready in the battle.
final class PrivateDuelScreen extends StatelessWidget
    implements GoRouterWrapper {
  const PrivateDuelScreen({this.disciplineCode, this.duelId, super.key});

  final String? disciplineCode;
  final String? duelId;

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<PrivateDuelBloc>(
      create: (_) =>
          PrivateDuelBloc(
            createDuel: dependencies.getDep<CreateDuelUsecase>(),
            getDuel: dependencies.getDep<GetDuelUsecase>(),
            cancelDuel: dependencies.getDep<CancelDuelUsecase>(),
            watchDuel: dependencies.getDep<WatchDuelUsecase>(),
            watchConnection: dependencies.getDep<WatchConnectionUsecase>(),
          )..add(
            PrivateDuelStarted(disciplineCode: disciplineCode, duelId: duelId),
          ),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: <BlocListener<PrivateDuelBloc, PrivateDuelState>>[
        BlocListener<PrivateDuelBloc, PrivateDuelState>(
          listenWhen: (PrivateDuelState previous, PrivateDuelState current) =>
              previous.battleId != current.battleId && current.battleId != null,
          listener: (BuildContext context, PrivateDuelState state) {
            // Marks the battle as opened, so the global listener of an
            // accepted invitation does not navigate a second time.
            context.read<NotificationBloc>().add(
              NotificationBattleOpened(state.battleId!),
            );
            context.goBattle(state.battleId!);
          },
        ),
        BlocListener<PrivateDuelBloc, PrivateDuelState>(
          listenWhen: (PrivateDuelState previous, PrivateDuelState current) =>
              previous.cancelStatus != current.cancelStatus &&
              current.cancelStatus.isSuccess,
          listener: (BuildContext context, PrivateDuelState state) =>
              context.goHome(),
        ),
      ],
      child: AppDesktopViewport(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 72),
          child: BlocBuilder<PrivateDuelBloc, PrivateDuelState>(
            builder: (BuildContext context, PrivateDuelState state) {
              final DuelEntity? duel = state.duel;
              if (duel == null) {
                if (state.loadStatus.isFailure) {
                  return AppErrorView(
                    title: "Couldn't open a private room",
                    message:
                        state.failure?.playMessage(DateTime.now()) ??
                        'Choose a discipline on the home screen first.',
                    onRetry: disciplineCode == null && duelId == null
                        ? null
                        : () => context.read<PrivateDuelBloc>().add(
                            PrivateDuelStarted(
                              disciplineCode: disciplineCode,
                              duelId: duelId,
                            ),
                          ),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 80,
                children: <Widget>[
                  Expanded(flex: 752, child: _CodeColumn(duel: duel)),
                  Flexible(
                    flex: 480,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: duel.status == DuelStatus.waiting
                          ? RoomInvitationScope(
                              duelId: duel.id,
                              child: _RoomCard(duel: duel, state: state),
                            )
                          : _RoomCard(duel: duel, state: state),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

final class _CodeColumn extends StatelessWidget {
  const _CodeColumn({required this.duel});

  final DuelEntity duel;

  @override
  Widget build(BuildContext context) {
    final bool open = duel.status == DuelStatus.waiting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 40,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: <Widget>[
            AppEyebrow(
              'Private duel · ${formatDisciplineCode(duel.disciplineCode)} · '
              'Unranked',
            ),
            Text(
              open ? 'Send this code\nto your friend' : 'This room is closed',
              style: AppTextStyles.displayMd,
            ),
          ],
        ),
        Opacity(
          opacity: open ? 1 : 0.4,
          child: _CodeTiles(code: duel.code),
        ),
        if (open) _CopyRow(code: duel.code, expiresAt: duel.expiresAt),
        const AppNotice(
          message: 'Private duels never change your rating.',
          tone: AppNoticeTone.warning,
          hug: true,
        ),
      ],
    );
  }
}

final class _CodeTiles extends StatelessWidget {
  const _CodeTiles({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Code ${code.split('').join(' ')}',
      excludeSemantics: true,
      child: Row(
        spacing: 10,
        children: <Widget>[
          for (final String char in code.split(''))
            Container(
              width: 84,
              height: 104,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                char,
                style: AppTextStyles.monoXxl.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;

  Future<void> _copy(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: code));
    messenger.showSnackBar(const SnackBar(content: Text('Code copied')));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 12,
      children: <Widget>[
        AppButton(
          label: 'Copy code',
          variant: AppButtonVariant.dark,
          size: AppButtonSize.medium,
          icon: const _CopyIcon(),
          onPressed: () => _copy(context),
        ),
        Row(
          children: <Widget>[
            Text(
              'Expires in ',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.muted),
            ),
            AppCountdownText(
              target: expiresAt,
              style: AppTextStyles.monoBodyMd,
            ),
          ],
        ),
      ],
    );
  }
}

final class _CopyIcon extends StatelessWidget {
  const _CopyIcon();

  @override
  Widget build(BuildContext context) {
    return AppSvgIcon(
      AppIcons.copy,
      width: 16,
      height: 16,
      color: IconTheme.of(context).color ?? AppColors.white,
    );
  }
}

final class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.duel, required this.state});

  final DuelEntity duel;
  final PrivateDuelState state;

  @override
  Widget build(BuildContext context) {
    final PublicPlayerEntity? guest = duel.guest;
    final String discipline = formatDisciplineCode(duel.disciplineCode);
    final String? closed = switch (duel.status) {
      DuelStatus.expired => 'The code expired before anyone joined.',
      DuelStatus.cancelled => 'The room was cancelled.',
      DuelStatus.waiting || DuelStatus.matched => null,
    };
    return DecoratedBox(
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
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text('Ready check', style: AppTextStyles.titleLg),
                ),
                Text(
                  '${guest == null ? 1 : 2} of 2 joined',
                  style: AppTextStyles.monoBodySm.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: <Widget>[
                _PlayerRow(
                  player: duel.host,
                  isYou: true,
                  subtitle: 'Host · $discipline',
                  status: 'In room',
                ),
                if (guest == null && duel.status == DuelStatus.waiting)
                  const RoomGuestSlot(fallback: _WaitingRow())
                else if (guest == null)
                  const _WaitingRow()
                else
                  _PlayerRow(
                    player: guest,
                    isYou: false,
                    subtitle: 'Online · joined just now',
                    status: 'Joined',
                  ),
              ],
            ),
            if (duel.status == DuelStatus.waiting && guest == null)
              RoomInvitationActions(disciplineCode: duel.disciplineCode),
            Text(
              duel.status == DuelStatus.matched
                  ? 'Opening the ready check…'
                  : 'When your friend joins, you both confirm "Ready" and the '
                        'match starts.',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.muted,
                height: 18 / 13,
              ),
            ),
            if (closed != null) ...<Widget>[
              AppNotice(message: closed, tone: AppNoticeTone.danger),
              AppButton(
                label: 'Create a new room',
                expand: true,
                onPressed: () => context.read<PrivateDuelBloc>().add(
                  PrivateDuelStarted(disciplineCode: duel.disciplineCode),
                ),
              ),
            ],
            if (state.cancelFailure != null)
              AppInlineError(state.cancelFailure!.userMessage),
            Center(
              child: AppTextLink(
                label: duel.status == DuelStatus.waiting
                    ? 'Cancel duel'
                    : 'Back to home',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w500,
                ),
                onPressed: state.cancelStatus.isLoading
                    ? null
                    : duel.status == DuelStatus.waiting
                    ? () => context.read<PrivateDuelBloc>().add(
                        const PrivateDuelCancelRequested(),
                      )
                    : context.goHome,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The empty guest slot, shaped like a player row.
final class _WaitingRow extends StatelessWidget {
  const _WaitingRow();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          spacing: 14,
          children: <Widget>[
            const SizedBox.square(
              dimension: 44,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.muted,
                  backgroundColor: AppColors.border,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: <Widget>[
                  Text(
                    'Your friend',
                    style: AppTextStyles.bodyLg.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                  Text(
                    'Share the code or invite a friend',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const _RowStatus(label: 'Waiting…', color: AppColors.faint),
          ],
        ),
      ),
    );
  }
}

final class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.isYou,
    required this.subtitle,
    required this.status,
  });

  final PublicPlayerEntity player;
  final bool isYou;
  final String subtitle;
  final String status;

  @override
  Widget build(BuildContext context) {
    final TextStyle subtitleStyle = AppTextStyles.bodySm.copyWith(
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
                        child: Text.rich(
                          TextSpan(
                            text: player.nickname,
                            children: <InlineSpan>[
                              if (isYou)
                                TextSpan(
                                  text: ' (you)',
                                  style: AppTextStyles.bodyLg.copyWith(
                                    color: AppColors.muted,
                                  ),
                                ),
                            ],
                          ),
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
                  if (isYou)
                    Text(subtitle, style: subtitleStyle)
                  else
                    Row(
                      spacing: 6,
                      children: <Widget>[
                        const AppDot(color: AppColors.success, size: 7),
                        Flexible(child: Text(subtitle, style: subtitleStyle)),
                      ],
                    ),
                ],
              ),
            ),
            _RowStatus(label: status, color: AppColors.success),
          ],
        ),
      ),
    );
  }
}

/// The right-hand status of a row, in a fixed 72 px lane.
final class _RowStatus extends StatelessWidget {
  const _RowStatus({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Text(
        label,
        textAlign: TextAlign.right,
        style: AppTextStyles.bodySm.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
