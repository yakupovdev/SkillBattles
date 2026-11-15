import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
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
import 'package:skill_battles/core/utils/extensions/go_router_extension.dart';
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
final class BattleScreen extends StatelessWidget implements GoRouterWrapper {
  const BattleScreen({required this.battleId, super.key});

  final String battleId;

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<BattleBloc>(
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
        BlocProvider<BattleStickersBloc>(
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

  static Future<void> confirmSurrender(
    BuildContext context,
    BattleSnapshotEntity snapshot,
  ) async {
    final BattleBloc bloc = context.read<BattleBloc>();
    // The picker must not stay open behind a dialog.
    StickerPickerScope.maybeOf(context)?.close();
    final bool started =
        snapshot.phase != BattlePhase.waitingReady &&
        snapshot.phase != BattlePhase.countdown;
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
    if (confirmed) bloc.add(const BattleSurrenderRequested());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: <BlocListener<dynamic, dynamic>>[
        BlocListener<BattleBloc, BattleState>(
          listenWhen: (BattleState previous, BattleState current) =>
              previous.phase != current.phase &&
              current.phase == BattlePhase.finished,
          listener: (BuildContext context, BattleState state) {
            context.read<AccountBloc>().add(const AccountRefreshRequested());
            context.goBattleResult(battleId);
          },
        ),
        BlocListener<BattleStickersBloc, BattleStickersState>(
          listenWhen: (
            BattleStickersState previous,
            BattleStickersState current,
          ) => previous.battleRefreshTicket != current.battleRefreshTicket,
          listener: (BuildContext context, BattleStickersState state) =>
              context.read<BattleBloc>().add(const BattleRefreshRequested()),
        ),
        BlocListener<AccountBloc, AccountState>(
          listenWhen: (AccountState previous, AccountState current) =>
              previous.entitlementsVersion != null &&
              previous.entitlementsVersion != current.entitlementsVersion,
          listener: (BuildContext context, AccountState state) => context
              .read<BattleBloc>()
              .add(const BattleRefreshRequested(entitlementsChanged: true)),
        ),
      ],
      child: _StickersBattleSync(
        child: Scaffold(
          backgroundColor: AppColors.white,
          body: StickerPickerScope(
            child: Stack(
              children: <Widget>[
                AppDesktopViewport(
                  fullBleed: true,
                  child: AppContextMenuBlocker(
                    child: BlocBuilder<BattleBloc, BattleState>(
                      builder: (BuildContext context, BattleState state) {
                        final BattleSnapshotEntity? snapshot = state.snapshot;
                        if (snapshot == null) {
                          if (state.loadStatus.isFailure) {
                            return AppErrorView(
                              title: "Couldn't open this match",
                              message:
                                  state.failure?.playMessage(DateTime.now()) ??
                                  '',
                              onRetry: () => context.read<BattleBloc>().add(
                                const BattleRefreshRequested(),
                              ),
                            );
                          }
                          return const Padding(
                            padding: EdgeInsets.only(top: 160),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _BattleBody(snapshot: snapshot, state: state);
                      },
                    ),
                  ),
                ),
                // Outside the builder above: a sticker never rebuilds the
                // question or the options.
                const Positioned.fill(child: StickerOverlay()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _BattleBody extends StatelessWidget {
  const _BattleBody({required this.snapshot, required this.state});

  final BattleSnapshotEntity snapshot;
  final BattleState state;

  @override
  Widget build(BuildContext context) {
    final BattleRoundEntity? round = snapshot.round;
    final bool isQuestion = snapshot.phase == BattlePhase.question;
    final bool inRound =
        round != null && (isQuestion || snapshot.phase == BattlePhase.reveal);
    // The footer sits at the bottom of the window (Paper: margin-top auto).
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            BattleHeader(
              snapshot: snapshot,
              youTrailing: const BattleStickerTrigger(),
              opponentNameLeading: const BattleHiddenIndicator(),
            ),
            if (inRound)
              BattleTimeBar(
                key: ValueKey<String>('${round.id}-${snapshot.phase.name}'),
                endsAt: isQuestion
                    ? round.deadline
                    : snapshot.nextRoundStartsAt,
                totalSeconds: isQuestion ? round.limitSeconds : null,
                clockOffset: snapshot.clockOffset,
                color: !isQuestion
                    ? AppColors.faint
                    : round.isOvertime
                    ? AppColors.accent
                    : AppColors.primary,
                lowColor: isQuestion ? AppColors.danger : null,
              ),
            if (state.connection != RealtimeStatus.connected &&
                !snapshot.phase.isTerminal)
              const Padding(
                padding: EdgeInsets.fromLTRB(32, 16, 32, 0),
                child: Center(
                  child: BattleColumn(
                    child: AppNotice(
                      message:
                          'Connection lost — reconnecting. The round clock '
                          'keeps running on the server.',
                      tone: AppNoticeTone.danger,
                    ),
                  ),
                ),
              ),
            if (state.surrenderFailure != null)
              const Padding(
                padding: EdgeInsets.fromLTRB(32, 16, 32, 0),
                child: Center(
                  child: BattleColumn(
                    child: AppNotice(
                      message: "Couldn't surrender — try again.",
                      tone: AppNoticeTone.danger,
                    ),
                  ),
                ),
              ),
            switch (snapshot.phase) {
              BattlePhase.waitingReady => BattleReadyCheck(
                snapshot: snapshot,
                state: state,
                onLeave: () => BattleScreen.confirmSurrender(context, snapshot),
              ),
              BattlePhase.countdown => BattleCountdownView(snapshot: snapshot),
              BattlePhase.question ||
              BattlePhase.reveal when round != null => BattleFocusGuard(
                // Web only for now; mobile platforms are a separate task.
                enabled: kIsWeb,
                roundId: round.id,
                child: Center(
                  child: BattleRoundView(
                    snapshot: snapshot,
                    round: round,
                    state: state,
                  ),
                ),
              ),
              BattlePhase.cancelled => BattleCancelledView(
                result: snapshot.result,
              ),
              _ => const Padding(
                padding: EdgeInsets.only(top: 160),
                child: Center(child: Text('Loading the results…')),
              ),
            },
          ],
        ),
        if (inRound)
          Padding(
            padding: const EdgeInsets.only(top: 40, bottom: 40),
            child: Center(
              child: BattleRoundFooter(
                snapshot: snapshot,
                round: round,
                state: state,
                onSurrender: state.surrenderStatus.isLoading
                    ? null
                    : () => BattleScreen.confirmSurrender(context, snapshot),
              ),
            ),
          ),
      ],
    );
  }
}

/// Tells the sticker bloc the phase, the players and the server clock: the
/// snapshot already there when the screen mounts (a listener alone would
/// miss it), then every change of those values.
final class _StickersBattleSync extends StatefulWidget {
  const _StickersBattleSync({required this.child});

  final Widget child;

  @override
  State<_StickersBattleSync> createState() => _StickersBattleSyncState();
}

final class _StickersBattleSyncState extends State<_StickersBattleSync> {
  @override
  void initState() {
    super.initState();
    final BattleSnapshotEntity? snapshot = context
        .read<BattleBloc>()
        .state
        .snapshot;
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
  Widget build(BuildContext context) {
    return BlocListener<BattleBloc, BattleState>(
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
      listener: (BuildContext context, BattleState state) =>
          _forward(state.snapshot!),
      child: widget.child,
    );
  }
}
