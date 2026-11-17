import 'package:bloc_signals_jaspr/bloc_signals_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/core/domain/entity/battle_result_entity.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/core/presentation/extensions/play_failure_message.dart';
import 'package:skill_battles/core/presentation/overlay/app_overlay.dart';
import 'package:skill_battles/core/presentation/skeleton/skeletonizer.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_locked_panel.dart';
import 'package:skill_battles/core/presentation/widgets/app_status_view.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/core/utils/extensions/route_extension.dart';
import 'package:skill_battles/features/account/presentation/bloc/account_bloc/account_bloc.dart';
import 'package:skill_battles/features/battle_result/domain/entity/battle_review_entity.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/cancel_rematch_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/get_rematch_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/get_result_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/get_review_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/report_round_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/request_rematch_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/watch_rematch_usecase.dart';
import 'package:skill_battles/features/battle_result/presentation/bloc/battle_result_bloc/battle_result_bloc.dart';
import 'package:skill_battles/features/battle_result/presentation/widgets/battle_result_skeleton_data.dart';
import 'package:skill_battles/features/battle_result/presentation/widgets/battle_result_summary.dart';
import 'package:skill_battles/features/battle_result/presentation/widgets/round_review_list.dart';

/// Final score, saved rating change and round review
/// (Paper: "07 Result & Review").
final class BattleResultScreen extends StatelessComponent implements RouteWrapper {
  const BattleResultScreen({required this.battleId, super.key});

  final String battleId;

  @override
  Component wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocSignalProvider<BattleResultBloc>(
      create: (_) => BattleResultBloc(
        battleId: battleId,
        getResult: dependencies.getDep<GetResultUsecase>(),
        getReview: dependencies.getDep<GetReviewUsecase>(),
        getRematch: dependencies.getDep<GetRematchUsecase>(),
        requestRematch: dependencies.getDep<RequestRematchUsecase>(),
        cancelRematch: dependencies.getDep<CancelRematchUsecase>(),
        watchRematch: dependencies.getDep<WatchRematchUsecase>(),
        reportRound: dependencies.getDep<ReportRoundUsecase>(),
      )..add(const BattleResultStarted()),
      child: this,
    );
  }

  @override
  Component build(BuildContext context) {
    return MultiBlocSignalListener(
      listeners: <BlocSignalListenerSingleChildComponent>[
        BlocSignalListener<BattleResultBloc, BattleResultState>(
          listenWhen: (BattleResultState previous, BattleResultState current) =>
              previous.rematchBattleId != current.rematchBattleId && current.rematchBattleId != null,
          listener: (BuildContext context, BattleResultState state) => context.goBattle(state.rematchBattleId!),
        ),
        BlocSignalListener<BattleResultBloc, BattleResultState>(
          listenWhen: (BattleResultState previous, BattleResultState current) =>
              previous.reportStatus != current.reportStatus &&
              (current.reportStatus.isSuccess || current.reportStatus.isFailure),
          listener: (BuildContext context, BattleResultState state) {
            final Failure? failure = state.reportFailure;
            showAppSnackBar(
              context,
              failure == null
                  ? 'Report sent. Thank you!'
                  : failure.hasCode(ApiErrorCodes.reportAlreadyExists)
                  ? 'You already reported this round differently.'
                  : failure.userMessage,
            );
            context.read<BattleResultBloc>().add(const BattleResultReportDismissed());
          },
        ),
        BlocSignalListener<AccountBloc, AccountState>(
          listenWhen: (AccountState previous, AccountState current) =>
              previous.entitlementsVersion != null && previous.entitlementsVersion != current.entitlementsVersion,
          listener: (BuildContext context, AccountState state) =>
              context.read<BattleResultBloc>().add(const BattleResultRefreshRequested()),
        ),
      ],
      child: AppDesktopViewport(
        child: div(classes: 'battle-result', <Component>[
          BlocSignalBuilder<BattleResultBloc, BattleResultState>(
            buildWhen: (BattleResultState previous, BattleResultState current) =>
                previous.resultStatus != current.resultStatus ||
                previous.result != current.result ||
                previous.resultFailure != current.resultFailure,
            builder: (BuildContext context, BattleResultState state) {
              final BattleResultEntity? result = state.result;
              final Failure? failure = state.resultFailure;
              if (result == null && failure != null) {
                return _ResultFailure(battleId: battleId, failure: failure);
              }
              return _Columns(result: result);
            },
          ),
        ]),
      ),
    );
  }
}

/// The summary column (at most 560 px) and the review column, sharing the
/// width 560 : 680 with a 72 px gap.
final class _Columns extends StatelessComponent {
  const _Columns({required this.result});

  final BattleResultEntity? result;

  @override
  Component build(BuildContext context) {
    final BattleResultEntity shown = result ?? BattleResultSkeletonData.result;
    return div(classes: 'battle-result__columns', <Component>[
      div(classes: 'battle-result__summary', <Component>[
        Skeletonizer(
          enabled: result == null,
          child: BattleResultSummary(
            result: shown,
            disciplineName: formatDisciplineCode(shown.disciplineCode),
          ),
        ),
      ]),
      div(classes: 'battle-result__review', <Component>[_Review(result: result)]),
    ]);
  }
}

final class _Review extends StatelessComponent {
  const _Review({required this.result});

  final BattleResultEntity? result;

  @override
  Component build(BuildContext context) {
    return BlocSignalBuilder<BattleResultBloc, BattleResultState>(
      buildWhen: (BattleResultState previous, BattleResultState current) =>
          previous.reviewStatus != current.reviewStatus ||
          previous.review != current.review ||
          previous.reviewFailure != current.reviewFailure ||
          previous.mistakesOnly != current.mistakesOnly ||
          previous.reportedRoundIds != current.reportedRoundIds,
      builder: (BuildContext context, BattleResultState state) {
        final BattleReviewEntity? review = state.review;
        final Failure? failure = state.reviewFailure;
        if (review == null && failure != null) {
          if (failure.hasCode(ApiErrorCodes.proRequired)) {
            return AppLockedPanel(
              title: 'Mistakes-only review',
              message: 'Filtering to your mistakes is part of Pro.',
              onUpgrade: context.goPro,
            );
          }
          return AppErrorView(
            title: "Couldn't load the review",
            message: failure.playMessage(DateTime.now()),
            onRetry: () => context.read<BattleResultBloc>().add(const BattleResultRefreshRequested()),
          );
        }
        final BattleResultEntity? result = this.result;
        return BlocSignalSelector<AccountBloc, AccountState, bool>(
          selector: (AccountState account) => account.entitlements?.canFilterMistakes ?? false,
          builder: (BuildContext context, bool canFilter) => Skeletonizer(
            enabled: review == null,
            child: RoundReviewList(
              // A new entitlement version (and the switch from the skeleton
              // to the real review) starts the list fresh.
              key: ValueKey<int>(review?.answerAccess.entitlementVersion ?? -1),
              review: review ?? BattleResultSkeletonData.review,
              disciplineName: result == null ? '' : formatDisciplineCode(result.disciplineCode),
              opponentNickname: result?.opponent.nickname ?? '',
              opponentId: result?.opponent.id ?? BattleResultSkeletonData.result.opponent.id,
              mistakesOnly: state.mistakesOnly,
              canFilterMistakes: canFilter,
              reportedRoundIds: state.reportedRoundIds,
            ),
          ),
        );
      },
    );
  }
}

final class _ResultFailure extends StatelessComponent {
  const _ResultFailure({required this.battleId, required this.failure});

  final String battleId;
  final Failure failure;

  @override
  Component build(BuildContext context) {
    if (failure.hasCode(ApiErrorCodes.historyAccessRequired)) {
      return div(classes: 'battle-result__locked', <Component>[
        div(classes: 'battle-result__locked-panel', <Component>[
          AppLockedPanel(
            title: 'This match is outside your latest 10',
            message:
                'Free keeps your latest 10 matches open. Pro opens your full '
                'history, including correct answers and explanations. Your '
                'statistics already count every match.',
            onUpgrade: context.goPro,
          ),
        ]),
      ]);
    }
    if (failure.hasCode(ApiErrorCodes.battleNotFinished)) {
      return AppEmptyView(
        title: 'This match is still running',
        message: 'Go back to the match to keep playing.',
        action: AppButton(
          label: 'Open the match',
          onPressed: () => context.goBattle(battleId),
        ),
      );
    }
    if (failure.hasCode(ApiErrorCodes.battleNotFound)) {
      return AppEmptyView(
        title: 'Match not found',
        message: "This match doesn't exist or isn't yours.",
        action: AppButton(
          label: 'Back to home',
          variant: AppButtonVariant.outline,
          onPressed: context.goHome,
        ),
      );
    }
    return AppErrorView(
      message: failure.userMessage,
      onRetry: () => context.read<BattleResultBloc>().add(const BattleResultRefreshRequested()),
    );
  }
}

@css
List<StyleRule> get battleResultScreenStyles => <StyleRule>[
  css('.battle-result').styles(
    display: Display.flex,
    padding: const Padding.symmetric(horizontal: Unit.pixels(64), vertical: Unit.pixels(56)),
    boxSizing: BoxSizing.borderBox,
    flexDirection: FlexDirection.column,
  ),
  css('.battle-result__columns').styles(
    display: Display.flex,
    alignItems: AlignItems.start,
    gap: const Gap.column(Unit.pixels(72)),
  ),
  css('.battle-result__summary').styles(
    minWidth: Unit.zero,
    maxWidth: const Unit.pixels(560),
    flex: const Flex(grow: 560, shrink: 1, basis: Unit.zero),
  ),
  css('.battle-result__review').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    flex: const Flex(grow: 680, shrink: 1, basis: Unit.zero),
  ),
  css('.battle-result__locked').styles(
    display: Display.flex,
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
    flex: const Flex(grow: 1),
  ),
  css('.battle-result__locked-panel').styles(
    width: const Unit.percent(100),
    maxWidth: const Unit.pixels(640),
  ),
];
