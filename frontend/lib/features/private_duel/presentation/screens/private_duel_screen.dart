import 'package:bloc_signals_jaspr/bloc_signals_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/js_interop.dart';
import 'package:universal_web/web.dart' as web;

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
import 'package:skill_battles/core/presentation/overlay/app_overlay.dart';
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
import 'package:skill_battles/core/utils/extensions/route_extension.dart';
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
final class PrivateDuelScreen extends StatelessComponent implements RouteWrapper {
  const PrivateDuelScreen({this.disciplineCode, this.duelId, super.key});

  final String? disciplineCode;
  final String? duelId;

  @override
  Component wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocSignalProvider<PrivateDuelBloc>(
      create: (_) => PrivateDuelBloc(
        createDuel: dependencies.getDep<CreateDuelUsecase>(),
        getDuel: dependencies.getDep<GetDuelUsecase>(),
        cancelDuel: dependencies.getDep<CancelDuelUsecase>(),
        watchDuel: dependencies.getDep<WatchDuelUsecase>(),
        watchConnection: dependencies.getDep<WatchConnectionUsecase>(),
      )..add(PrivateDuelStarted(disciplineCode: disciplineCode, duelId: duelId)),
      child: this,
    );
  }

  @override
  Component build(BuildContext context) {
    return MultiBlocSignalListener(
      listeners: <BlocSignalListenerSingleChildComponent>[
        BlocSignalListener<PrivateDuelBloc, PrivateDuelState>(
          listenWhen: (PrivateDuelState previous, PrivateDuelState current) =>
              previous.battleId != current.battleId && current.battleId != null,
          listener: (BuildContext context, PrivateDuelState state) {
            // Marks the battle as opened, so the global listener of an
            // accepted invitation does not navigate a second time.
            context.read<NotificationBloc>().add(NotificationBattleOpened(state.battleId!));
            context.goBattle(state.battleId!);
          },
        ),
        BlocSignalListener<PrivateDuelBloc, PrivateDuelState>(
          listenWhen: (PrivateDuelState previous, PrivateDuelState current) =>
              previous.cancelStatus != current.cancelStatus && current.cancelStatus.isSuccess,
          listener: (BuildContext context, PrivateDuelState state) => context.goHome(),
        ),
      ],
      child: AppDesktopViewport(
        child: div(classes: 'private-duel', <Component>[
          BlocSignalBuilder<PrivateDuelBloc, PrivateDuelState>(
            builder: (BuildContext context, PrivateDuelState state) {
              final DuelEntity? duel = state.duel;
              if (duel == null) {
                if (state.loadStatus.isFailure) {
                  return AppErrorView(
                    title: "Couldn't open a private room",
                    message:
                        state.failure?.playMessage(DateTime.now()) ?? 'Choose a discipline on the home screen first.',
                    onRetry: disciplineCode == null && duelId == null
                        ? null
                        : () => context.read<PrivateDuelBloc>().add(
                            PrivateDuelStarted(disciplineCode: disciplineCode, duelId: duelId),
                          ),
                  );
                }
                return const div(classes: 'private-duel__loading', <Component>[
                  span(
                    classes: 'private-duel__spinner',
                    attributes: <String, String>{'role': 'progressbar', 'aria-label': 'Loading'},
                    <Component>[],
                  ),
                ]);
              }
              return div(classes: 'private-duel__layout', <Component>[
                div(classes: 'private-duel__main', <Component>[_CodeColumn(duel: duel)]),
                div(classes: 'private-duel__side', <Component>[
                  if (duel.status == DuelStatus.waiting)
                    RoomInvitationScope(
                      duelId: duel.id,
                      child: _RoomCard(duel: duel, state: state),
                    )
                  else
                    _RoomCard(duel: duel, state: state),
                ]),
              ]);
            },
          ),
        ]),
      ),
    );
  }
}

final class _CodeColumn extends StatelessComponent {
  const _CodeColumn({required this.duel});

  final DuelEntity duel;

  @override
  Component build(BuildContext context) {
    final bool open = duel.status == DuelStatus.waiting;
    return div(classes: 'private-duel__code-column', <Component>[
      div(classes: 'private-duel__heading', <Component>[
        AppEyebrow('Private duel · ${formatDisciplineCode(duel.disciplineCode)} · Unranked'),
        h1(classes: 'private-duel__title', <Component>[
          Component.text(open ? 'Send this code\nto your friend' : 'This room is closed'),
        ]),
      ]),
      div(styles: Styles(opacity: open ? 1 : 0.4), <Component>[_CodeTiles(code: duel.code)]),
      if (open) _CopyRow(code: duel.code, expiresAt: duel.expiresAt),
      const AppNotice(message: 'Private duels never change your rating.', tone: AppNoticeTone.warning, hug: true),
    ]);
  }
}

final class _CodeTiles extends StatelessComponent {
  const _CodeTiles({required this.code});

  final String code;

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'private-duel__tiles',
      attributes: <String, String>{'role': 'img', 'aria-label': 'Code ${code.split('').join(' ')}'},
      <Component>[
        for (final String char in code.split(''))
          span(classes: 'private-duel__tile', <Component>[Component.text(char)]),
      ],
    );
  }
}

final class _CopyRow extends StatefulComponent {
  const _CopyRow({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;

  @override
  State<_CopyRow> createState() => _CopyRowState();
}

final class _CopyRowState extends State<_CopyRow> {
  Future<void> _copy() async {
    try {
      await web.window.navigator.clipboard.writeText(component.code).toDart;
    } on Object {
      // The browser refused (no permission or an insecure page).
      if (mounted) showAppSnackBar(context, "Couldn't copy the code");
      return;
    }
    if (mounted) showAppSnackBar(context, 'Code copied');
  }

  @override
  Component build(BuildContext context) {
    return div(classes: 'private-duel__copy-row', <Component>[
      AppButton(
        label: 'Copy code',
        variant: AppButtonVariant.dark,
        size: AppButtonSize.medium,
        icon: AppSvgIcon(
          AppIcons.copy,
          width: 16,
          height: 16,
          color: AppButton.foregroundOf(AppButtonVariant.dark),
        ),
        onPressed: _copy,
      ),
      p(classes: 'private-duel__expires', <Component>[
        const span(<Component>[Component.text('Expires in ')]),
        AppCountdownText(target: component.expiresAt, style: AppTextStyles.monoBodyMd),
      ]),
    ]);
  }
}

final class _RoomCard extends StatelessComponent {
  const _RoomCard({required this.duel, required this.state});

  final DuelEntity duel;
  final PrivateDuelState state;

  @override
  Component build(BuildContext context) {
    final PublicPlayerEntity? guest = duel.guest;
    final String discipline = formatDisciplineCode(duel.disciplineCode);
    final String? closed = switch (duel.status) {
      DuelStatus.expired => 'The code expired before anyone joined.',
      DuelStatus.cancelled => 'The room was cancelled.',
      DuelStatus.waiting || DuelStatus.matched => null,
    };
    final String? cancelError = state.cancelFailure?.userMessage;
    return div(classes: 'private-duel__room', <Component>[
      div(classes: 'private-duel__room-head', <Component>[
        const h2(classes: 'private-duel__room-title', <Component>[Component.text('Ready check')]),
        p(classes: 'private-duel__joined', <Component>[Component.text('${guest == null ? 1 : 2} of 2 joined')]),
      ]),
      div(classes: 'private-duel__players', <Component>[
        _PlayerRow(player: duel.host, isYou: true, subtitle: 'Host · $discipline', status: 'In room'),
        if (guest == null && duel.status == DuelStatus.waiting)
          const RoomGuestSlot(fallback: _WaitingRow())
        else if (guest == null)
          const _WaitingRow()
        else
          _PlayerRow(player: guest, isYou: false, subtitle: 'Online · joined just now', status: 'Joined'),
      ]),
      if (duel.status == DuelStatus.waiting && guest == null)
        RoomInvitationActions(disciplineCode: duel.disciplineCode),
      p(classes: 'private-duel__hint', <Component>[
        Component.text(
          duel.status == DuelStatus.matched
              ? 'Opening the ready check…'
              : 'When your friend joins, you both confirm "Ready" and the '
                    'match starts.',
        ),
      ]),
      if (closed != null) ...<Component>[
        AppNotice(message: closed, tone: AppNoticeTone.danger),
        AppButton(
          label: 'Create a new room',
          expand: true,
          onPressed: () => context.read<PrivateDuelBloc>().add(PrivateDuelStarted(disciplineCode: duel.disciplineCode)),
        ),
      ],
      if (cancelError != null) AppInlineError(cancelError),
      div(classes: 'private-duel__room-link', <Component>[
        AppTextLink(
          label: duel.status == DuelStatus.waiting ? 'Cancel duel' : 'Back to home',
          style: AppTextStyles.bodyMd.combine(const Styles(color: AppColors.muted, fontWeight: FontWeight.w500)),
          onPressed: state.cancelStatus.isLoading
              ? null
              : duel.status == DuelStatus.waiting
              ? () => context.read<PrivateDuelBloc>().add(const PrivateDuelCancelRequested())
              : context.goHome,
        ),
      ]),
    ]);
  }
}

/// The empty guest slot, shaped like a player row.
final class _WaitingRow extends StatelessComponent {
  const _WaitingRow();

  @override
  Component build(BuildContext context) {
    return const div(classes: 'private-duel__waiting', <Component>[
      span(classes: 'private-duel__waiting-spinner-box', <Component>[
        span(
          classes: 'private-duel__waiting-spinner',
          attributes: <String, String>{'aria-hidden': 'true'},
          <Component>[],
        ),
      ]),
      div(classes: 'private-duel__player-texts', <Component>[
        p(classes: 'private-duel__waiting-name', <Component>[Component.text('Your friend')]),
        p(classes: 'private-duel__subtitle', <Component>[Component.text('Share the code or invite a friend')]),
      ]),
      _RowStatus(label: 'Waiting…', color: AppColors.faint),
    ]);
  }
}

final class _PlayerRow extends StatelessComponent {
  const _PlayerRow({required this.player, required this.isYou, required this.subtitle, required this.status});

  final PublicPlayerEntity player;
  final bool isYou;
  final String subtitle;
  final String status;

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'private-duel__player',
      styles: Styles(backgroundColor: isYou ? AppColors.primarySurface : AppColors.accentSurface),
      <Component>[
        AppAvatar(
          nickname: player.nickname,
          size: AppAvatarSize.md,
          tone: isYou ? AppAvatarTone.primary : AppAvatarTone.accent,
        ),
        div(classes: 'private-duel__player-texts', <Component>[
          div(classes: 'private-duel__player-name-row', <Component>[
            p(classes: 'private-duel__player-name', <Component>[
              span(<Component>[Component.text(player.nickname)]),
              if (isYou) const span(classes: 'private-duel__you', <Component>[Component.text(' (you)')]),
            ]),
            if (player.isPro) const ProBadge(),
          ]),
          if (isYou)
            p(classes: 'private-duel__subtitle', <Component>[Component.text(subtitle)])
          else
            div(classes: 'private-duel__online', <Component>[
              const AppDot(color: AppColors.success, size: 7),
              p(classes: 'private-duel__subtitle', <Component>[Component.text(subtitle)]),
            ]),
        ]),
        _RowStatus(label: status, color: AppColors.success),
      ],
    );
  }
}

/// The right-hand status of a row, in a fixed 72 px lane.
final class _RowStatus extends StatelessComponent {
  const _RowStatus({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Component build(BuildContext context) {
    return p(classes: 'private-duel__row-status', styles: Styles(color: color), <Component>[Component.text(label)]);
  }
}

@css
List<StyleRule> get privateDuelScreenStyles => <StyleRule>[
  css.keyframes('private-duel-spin', <String, Styles>{
    'to': const Styles(transform: Transform.rotate(Angle.deg(360))),
  }),
  css('.private-duel').styles(
    display: Display.flex,
    padding: const Padding.symmetric(horizontal: Unit.pixels(64), vertical: Unit.pixels(72)),
    flexDirection: FlexDirection.column,
  ),
  css('.private-duel__loading').styles(
    display: Display.flex,
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
    flex: const Flex(grow: 1),
  ),
  css('.private-duel__spinner').styles(
    display: Display.block,
    width: const Unit.pixels(36),
    height: const Unit.pixels(36),
    border: Border.all(color: AppColors.primary, width: const Unit.pixels(4)),
    radius: const BorderRadius.circular(Unit.percent(50)),
    raw: const <String, String>{
      'border-right-color': 'transparent',
      'animation': 'private-duel-spin 0.8s linear infinite',
    },
  ),
  css('.private-duel__layout').styles(
    display: Display.flex,
    alignItems: AlignItems.start,
    gap: const Gap.column(Unit.pixels(80)),
  ),
  css('.private-duel__main').styles(
    minWidth: Unit.zero,
    flex: const Flex(grow: 752, shrink: 1, basis: Unit.zero),
  ),
  css('.private-duel__side').styles(
    minWidth: Unit.zero,
    maxWidth: const Unit.pixels(480),
    flex: const Flex(grow: 480, shrink: 1, basis: Unit.zero),
  ),
  css('.private-duel__code-column').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(40)),
  ),
  css('.private-duel__heading').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(10)),
  ),
  css('.private-duel__title').styles(whiteSpace: WhiteSpace.preLine).combine(AppTextStyles.displayMd),
  css('.private-duel__tiles').styles(display: Display.flex, gap: const Gap.column(Unit.pixels(10))),
  css('.private-duel__tile')
      .styles(
        display: Display.flex,
        width: const Unit.pixels(84),
        height: const Unit.pixels(104),
        radius: const BorderRadius.circular(Unit.pixels(14)),
        justifyContent: JustifyContent.center,
        alignItems: AlignItems.center,
        backgroundColor: AppColors.surface,
      )
      .combine(AppTextStyles.monoXxl)
      .combine(const Styles(fontWeight: FontWeight.w600, letterSpacing: Unit.zero)),
  css('.private-duel__copy-row').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(12)),
  ),
  css('.private-duel__expires').combine(AppTextStyles.bodyMd).combine(const Styles(color: AppColors.muted)),
  css('.private-duel__room').styles(
    display: Display.flex,
    padding: const Padding.all(Unit.pixels(32)),
    border: Border.all(color: AppColors.border, width: const Unit.pixels(1)),
    radius: const BorderRadius.circular(Unit.pixels(20)),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(24)),
  ),
  css('.private-duel__room-head').styles(display: Display.flex, alignItems: AlignItems.center),
  css('.private-duel__room-title')
      .styles(
        minWidth: Unit.zero,
        flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
      )
      .combine(AppTextStyles.titleLg),
  css('.private-duel__joined').combine(AppTextStyles.monoBodySm).combine(const Styles(color: AppColors.muted)),
  css('.private-duel__players').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(12)),
  ),
  css('.private-duel__hint')
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.muted, lineHeight: Unit.pixels(18))),
  css('.private-duel__room-link').styles(display: Display.flex, justifyContent: JustifyContent.center),
  css('.private-duel__waiting').styles(
    display: Display.flex,
    padding: const Padding.all(Unit.pixels(15)),
    border: Border.all(color: AppColors.border, width: const Unit.pixels(1)),
    radius: const BorderRadius.circular(Unit.pixels(12)),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(14)),
  ),
  css('.private-duel__waiting-spinner-box').styles(
    display: Display.flex,
    width: const Unit.pixels(44),
    height: const Unit.pixels(44),
    padding: const Padding.all(Unit.pixels(12)),
    flex: const Flex(shrink: 0),
  ),
  css('.private-duel__waiting-spinner').styles(
    display: Display.block,
    width: const Unit.percent(100),
    height: const Unit.percent(100),
    border: Border.all(color: AppColors.border, width: const Unit.pixels(2)),
    radius: const BorderRadius.circular(Unit.percent(50)),
    raw: const <String, String>{
      'border-top-color': '#6B6F7A',
      'animation': 'private-duel-spin 0.8s linear infinite',
    },
  ),
  css('.private-duel__waiting-name')
      .combine(AppTextStyles.bodyLg)
      .combine(const Styles(color: AppColors.muted, fontWeight: FontWeight.w600)),
  css('.private-duel__player').styles(
    display: Display.flex,
    padding: const Padding.all(Unit.pixels(16)),
    radius: const BorderRadius.circular(Unit.pixels(12)),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(14)),
  ),
  css('.private-duel__player-texts').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(2)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.private-duel__player-name-row').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(8)),
  ),
  css('.private-duel__player-name')
      .styles(
        minWidth: Unit.zero,
        overflow: Overflow.hidden,
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.bodyLg)
      .combine(const Styles(fontWeight: FontWeight.w600)),
  css('.private-duel__you').styles(color: AppColors.muted, fontWeight: FontWeight.w400),
  css('.private-duel__online').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(6)),
  ),
  css('.private-duel__subtitle')
      .styles(minWidth: Unit.zero)
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.muted)),
  css('.private-duel__row-status')
      .styles(width: const Unit.pixels(72), flex: const Flex(shrink: 0))
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(textAlign: TextAlign.right, fontWeight: FontWeight.w600)),
];
