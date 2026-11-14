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
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_notice.dart';
import 'package:skill_battles/core/presentation/widgets/app_status_view.dart';
import 'package:skill_battles/core/utils/extensions/go_router_extension.dart';
import 'package:skill_battles/features/account/presentation/bloc/account_bloc/account_bloc.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_phase.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_round_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_snapshot_entity.dart';
import 'package:skill_battles/features/battle/domain/usecases/get_battle_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/set_ready_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/submit_answer_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/surrender_usecase.dart';
import 'package:skill_battles/features/battle/domain/usecases/watch_battle_usecase.dart';
import 'package:skill_battles/features/battle/presentation/bloc/battle_bloc/battle_bloc.dart';
import 'package:skill_battles/features/battle/presentation/widgets/battle_countdown_view.dart';
import 'package:skill_battles/features/battle/presentation/widgets/battle_ended_view.dart';
import 'package:skill_battles/features/battle/presentation/widgets/battle_header.dart';
import 'package:skill_battles/features/battle/presentation/widgets/battle_ready_check.dart';
import 'package:skill_battles/features/battle/presentation/widgets/battle_round_view.dart';
import 'package:skill_battles/features/battle/presentation/widgets/battle_time_bar.dart';

/// The live battle (Paper: "05 Live Battle"): ready check, countdown, five
/// rounds plus a possible overtime, reveal after each round. The server
/// drives every phase; this screen renders snapshots and sends actions.
final class BattleScreen extends StatelessWidget implements GoRouterWrapper {
  const BattleScreen({required this.battleId, super.key});

  final String battleId;

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<BattleBloc>(
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
      child: this,
    );
  }

  static Future<void> confirmSurrender(
    BuildContext context,
    BattleSnapshotEntity snapshot,
  ) async {
    final BattleBloc bloc = context.read<BattleBloc>();
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
        BlocListener<AccountBloc, AccountState>(
          listenWhen: (AccountState previous, AccountState current) =>
              previous.entitlementsVersion != null &&
              previous.entitlementsVersion != current.entitlementsVersion,
          listener: (BuildContext context, AccountState state) => context
              .read<BattleBloc>()
              .add(const BattleRefreshRequested(entitlementsChanged: true)),
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: AppDesktopViewport(
          fullBleed: true,
          child: BlocBuilder<BattleBloc, BattleState>(
            builder: (BuildContext context, BattleState state) {
              final BattleSnapshotEntity? snapshot = state.snapshot;
              if (snapshot == null) {
                if (state.loadStatus.isFailure) {
                  return AppErrorView(
                    title: "Couldn't open this match",
                    message: state.failure?.playMessage(DateTime.now()) ?? '',
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
            BattleHeader(snapshot: snapshot),
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
              BattlePhase.reveal when round != null => Center(
                child: BattleRoundView(
                  snapshot: snapshot,
                  round: round,
                  state: state,
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
