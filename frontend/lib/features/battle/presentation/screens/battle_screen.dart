import 'package:bloc_signals_jaspr/bloc_signals_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/battle_mode.dart';
import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/core/domain/usecases/generate_id_usecase.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/presentation/extensions/play_failure_message.dart';
import 'package:skill_battles/core/presentation/widgets/app_confirm_dialog.dart';
import 'package:skill_battles/core/presentation/widgets/app_context_menu_blocker.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_notice.dart';
import 'package:skill_battles/core/presentation/widgets/app_status_view.dart';
import 'package:skill_battles/core/utils/extensions/route_extension.dart';
import 'package:skill_battles/features/account/presentation/bloc/account_bloc/account_bloc.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_phase.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_round_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_snapshot_entity.dart';
import 'package:skill_battles/features/battle/domain/usecases/get_battle_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/send_sticker_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/set_ready_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/submit_answer_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/surrender_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/watch_battle_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/watch_stickers_usecase.dart';
import 'package:skill_battles/features/battle/presentation/bloc/battle_bloc/battle_bloc.dart';
import 'package:skill_battles/features/battle/presentation/bloc/battle_stickers_bloc/battle_stickers_bloc.dart';
import 'package:skill_battles/features/battle/presentation/widgets/battle_countdown_view.dart';
import 'package:skill_battles/features/battle/presentation/widgets/battle_ended_view.dart';
import 'package:skill_battles/features/battle/presentation/widgets/battle_focus_guard.dart';
import 'package:skill_battles/features/battle/presentation/widgets/battle_header.dart';
import 'package:skill_battles/features/battle/presentation/widgets/battle_ready_check.dart';
import 'package:skill_battles/features/battle/presentation/widgets/battle_round_view.dart';
import 'package:skill_battles/features/battle/presentation/widgets/battle_sticker_slots.dart';
import 'package:skill_battles/features/battle/presentation/widgets/battle_time_bar.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_overlay.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_picker_scope.dart';

/// The live battle (Paper: "05 Live Battle"): ready check, countdown, five
/// rounds plus a possible overtime, reveal after each round. The server
/// drives every phase; this screen renders snapshots and sends actions.
///
/// Full screen (outside `AppShell`): its root fills the window height and
/// is the positioned box of the page viewport and the sticker overlay.
final class BattleScreen extends StatelessComponent implements RouteWrapper {
  const BattleScreen({required this.battleId, super.key});

  final String battleId;

  @override
  Component wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return MultiBlocSignalProvider(
      providers: <BlocSignalProviderSingleChildComponent>[
        BlocSignalProvider<BattleBloc>(
          create: (_) => BattleBloc(
            battleId: battleId,
            getBattle: dependencies.getDep<GetBattleUsecase>(),
            setReady: dependencies.getDep<SetReadyUsecase>(),
            submitAnswer: dependencies.getDep<SubmitAnswerUsecase>(),
            surrender: dependencies.getDep<SurrenderUsecase>(),
            watchBattle: dependencies.getDep<WatchBattleUsecase>(),
            watchConnection: dependencies.getDep<WatchConnectionUsecase>(),
            generateId: dependencies.getDep<GenerateIdUsecase>(),
          )..add(const BattleStarted()),
        ),
        BlocSignalProvider<BattleStickersBloc>(
          create: (_) => BattleStickersBloc(
            battleId: battleId,
            sendSticker: dependencies.getDep<SendStickerUsecase>(),
            watchStickers: dependencies.getDep<WatchStickersUsecase>(),
            watchConnection: dependencies.getDep<WatchConnectionUsecase>(),
            generateId: dependencies.getDep<GenerateIdUsecase>(),
          )..add(const BattleStickersStarted()),
        ),
      ],
      child: this,
    );
  }

  static Future<void> confirmSurrender(BuildContext context, BattleSnapshotEntity snapshot) async {
    final BattleBloc bloc = context.read<BattleBloc>();
    // The picker must not stay open behind a dialog.
    StickerPickerScope.maybeOf(context)?.close();
    final bool started = snapshot.phase != BattlePhase.waitingReady && snapshot.phase != BattlePhase.countdown;
    final bool confirmed = await showAppConfirmDialog(
      context,
      title: started ? 'Surrender this match?' : 'Leave the match?',
      message: started
          ? snapshot.mode == BattleMode.ranked
                ? 'You lose immediately and your rating changes. This cannot '
                      'be undone.'
                : 'You lose immediately. Private duels never change your '
                      'rating.'
          : 'The match is cancelled before the first question.',
      confirmLabel: started ? 'Surrender' : 'Leave',
      isDestructive: true,
    );
    if (confirmed && !bloc.isClosed) bloc.add(const BattleSurrenderRequested());
  }

  @override
  Component build(BuildContext context) {
    return MultiBlocSignalListener(
      listeners: <BlocSignalListenerSingleChildComponent>[
        BlocSignalListener<BattleBloc, BattleState>(
          listenWhen: (BattleState previous, BattleState current) =>
              previous.phase != current.phase && current.phase == BattlePhase.finished,
          listener: (BuildContext context, BattleState state) {
            context.read<AccountBloc>().add(const AccountRefreshRequested());
            context.goBattleResult(battleId);
          },
        ),
        BlocSignalListener<BattleStickersBloc, BattleStickersState>(
          listenWhen: (BattleStickersState previous, BattleStickersState current) =>
              previous.battleRefreshTicket != current.battleRefreshTicket,
          listener: (BuildContext context, BattleStickersState state) =>
              context.read<BattleBloc>().add(const BattleRefreshRequested()),
        ),
        BlocSignalListener<AccountBloc, AccountState>(
          listenWhen: (AccountState previous, AccountState current) =>
              previous.entitlementsVersion != null && previous.entitlementsVersion != current.entitlementsVersion,
          listener: (BuildContext context, AccountState state) =>
              context.read<BattleBloc>().add(const BattleRefreshRequested(entitlementsChanged: true)),
        ),
      ],
      child: _StickersBattleSync(
        child: StickerPickerScope(
          child: div(classes: 'battle-screen', <Component>[
            AppDesktopViewport(
              fullBleed: true,
              child: AppContextMenuBlocker(
                child: BlocSignalBuilder<BattleBloc, BattleState>(
                  builder: (BuildContext context, BattleState state) {
                    final BattleSnapshotEntity? snapshot = state.snapshot;
                    if (snapshot == null) {
                      if (state.loadStatus.isFailure) {
                        return AppErrorView(
                          title: "Couldn't open this match",
                          message: state.failure?.playMessage(DateTime.now()) ?? '',
                          onRetry: () => context.read<BattleBloc>().add(const BattleRefreshRequested()),
                        );
                      }
                      return const _Loading();
                    }
                    return _BattleBody(snapshot: snapshot, state: state);
                  },
                ),
              ),
            ),
            // Outside the builder above: a sticker never rebuilds the
            // question or the options.
            const StickerOverlay(),
          ]),
        ),
      ),
    );
  }
}

/// The page-level progress indicator while the first snapshot loads.
final class _Loading extends StatelessComponent {
  const _Loading();

  @override
  Component build(BuildContext context) {
    return const div(classes: 'battle-screen__loading', <Component>[
      span(
        classes: 'battle-screen__spinner',
        attributes: <String, String>{'role': 'progressbar', 'aria-label': 'Loading the match'},
        <Component>[],
      ),
    ]);
  }
}

final class _BattleBody extends StatelessComponent {
  const _BattleBody({required this.snapshot, required this.state});

  final BattleSnapshotEntity snapshot;
  final BattleState state;

  @override
  Component build(BuildContext context) {
    final BattleRoundEntity? round = snapshot.round;
    final bool isQuestion = snapshot.phase == BattlePhase.question;
    final bool inRound = round != null && (isQuestion || snapshot.phase == BattlePhase.reveal);
    // The footer sits at the bottom of the window (Paper: margin-top auto).
    return div(classes: 'battle-body', <Component>[
      div(classes: 'battle-body__main', <Component>[
        BattleHeader(
          snapshot: snapshot,
          youTrailing: const BattleStickerTrigger(),
          opponentNameLeading: const BattleHiddenIndicator(),
        ),
        if (inRound)
          BattleTimeBar(
            key: ValueKey<String>('${round.id}-${snapshot.phase.name}'),
            endsAt: isQuestion ? round.deadline : snapshot.nextRoundStartsAt,
            totalSeconds: isQuestion ? round.limitSeconds : null,
            clockOffset: snapshot.clockOffset,
            color: !isQuestion
                ? AppColors.faint
                : round.isOvertime
                ? AppColors.accent
                : AppColors.primary,
            lowColor: isQuestion ? AppColors.danger : null,
          ),
        if (state.connection != RealtimeStatus.connected && !snapshot.phase.isTerminal)
          const _BodyNotice(
            message: 'Connection lost — reconnecting. The round clock keeps running on the server.',
          ),
        if (state.surrenderFailure != null) const _BodyNotice(message: "Couldn't surrender — try again."),
        switch (snapshot.phase) {
          BattlePhase.waitingReady => BattleReadyCheck(
            snapshot: snapshot,
            state: state,
            onLeave: () => BattleScreen.confirmSurrender(context, snapshot),
          ),
          BattlePhase.countdown => BattleCountdownView(snapshot: snapshot),
          BattlePhase.question || BattlePhase.reveal when round != null => BattleFocusGuard(
            enabled: kIsWeb,
            roundId: round.id,
            child: BattleRoundView(snapshot: snapshot, round: round, state: state),
          ),
          BattlePhase.cancelled => BattleCancelledView(result: snapshot.result),
          _ => const p(classes: 'battle-body__results', <Component>[Component.text('Loading the results…')]),
        },
      ]),
      if (inRound)
        div(classes: 'battle-body__footer', <Component>[
          BattleRoundFooter(
            snapshot: snapshot,
            round: round,
            state: state,
            onSurrender: state.surrenderStatus.isLoading
                ? null
                : () => BattleScreen.confirmSurrender(context, snapshot),
          ),
        ]),
    ]);
  }
}

/// A danger notice under the header, in the 880 px column.
final class _BodyNotice extends StatelessComponent {
  const _BodyNotice({required this.message});

  final String message;

  @override
  Component build(BuildContext context) {
    return div(classes: 'battle-body__notice', <Component>[
      BattleColumn(
        child: AppNotice(message: message, tone: AppNoticeTone.danger),
      ),
    ]);
  }
}

/// Tells the sticker bloc the phase, the players and the server clock: the
/// snapshot already there when the screen mounts (a listener alone would
/// miss it), then every change of those values.
final class _StickersBattleSync extends StatefulComponent {
  const _StickersBattleSync({required this.child});

  final Component child;

  @override
  State<_StickersBattleSync> createState() => _StickersBattleSyncState();
}

final class _StickersBattleSyncState extends State<_StickersBattleSync> {
  @override
  void initState() {
    super.initState();
    final BattleSnapshotEntity? snapshot = context.read<BattleBloc>().stateValue.snapshot;
    if (snapshot != null) _forward(snapshot);
  }

  void _forward(BattleSnapshotEntity snapshot) {
    context.read<BattleStickersBloc>().add(
      BattleStickersBattleUpdated(
        phase: snapshot.phase,
        myUserId: snapshot.myUserId,
        opponentUserId: snapshot.opponent.id,
        clockOffset: snapshot.clockOffset,
      ),
    );
  }

  @override
  Component build(BuildContext context) {
    return BlocSignalListener<BattleBloc, BattleState>(
      listenWhen: (BattleState previous, BattleState current) {
        final BattleSnapshotEntity? next = current.snapshot;
        final BattleSnapshotEntity? before = previous.snapshot;
        return next != null &&
            (before == null ||
                before.phase != next.phase ||
                before.myUserId != next.myUserId ||
                before.opponent.id != next.opponent.id ||
                before.clockOffset != next.clockOffset);
      },
      listener: (BuildContext context, BattleState state) => _forward(state.snapshot!),
      child: component.child,
    );
  }
}

@css
List<StyleRule> get battleScreenStyles => <StyleRule>[
  // The positioned, full-height box that `AppDesktopViewport` (absolute,
  // inset 0) and the sticker overlay fill.
  css('.battle-screen').styles(
    position: const Position.relative(),
    overflow: Overflow.hidden,
    backgroundColor: AppColors.white,
    raw: const <String, String>{'height': '100dvh'},
  ),
  css('.battle-screen__loading').styles(
    display: Display.flex,
    padding: const Padding.only(top: Unit.pixels(160)),
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.start,
  ),
  css('.battle-screen__spinner').styles(
    display: Display.inlineBlock,
    width: const Unit.pixels(36),
    height: const Unit.pixels(36),
    boxSizing: BoxSizing.borderBox,
    border: Border.all(color: AppColors.primary, width: const Unit.pixels(4)),
    radius: const BorderRadius.circular(Unit.percent(50)),
    raw: const <String, String>{
      'border-right-color': 'transparent',
      'animation': 'app-spin 0.8s linear infinite',
    },
  ),
  css('.battle-body').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    justifyContent: JustifyContent.spaceBetween,
  ),
  css('.battle-body__main').styles(display: Display.flex, flexDirection: FlexDirection.column),
  css('.battle-body__notice').styles(padding: const Padding.only(top: Unit.pixels(16))),
  css('.battle-body__footer').styles(padding: const Padding.symmetric(vertical: Unit.pixels(40))),
  css('.battle-body__results')
      .styles(padding: const Padding.only(top: Unit.pixels(160)))
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(textAlign: TextAlign.center)),
];
