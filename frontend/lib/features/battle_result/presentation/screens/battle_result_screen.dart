import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/core/domain/entity/battle_result_entity.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/core/presentation/extensions/play_failure_message.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_locked_panel.dart';
import 'package:skill_battles/core/presentation/widgets/app_status_view.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/core/utils/extensions/go_router_extension.dart';
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
final class BattleResultScreen extends StatelessWidget
    implements GoRouterWrapper {
  const BattleResultScreen({required this.battleId, super.key});

  final String battleId;

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<BattleResultBloc>(
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
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: <BlocListener<dynamic, dynamic>>[
        BlocListener<BattleResultBloc, BattleResultState>(
          listenWhen: (BattleResultState previous, BattleResultState current) =>
              previous.rematchBattleId != current.rematchBattleId &&
              current.rematchBattleId != null,
          listener: (BuildContext context, BattleResultState state) =>
              context.goBattle(state.rematchBattleId!),
        ),
        BlocListener<BattleResultBloc, BattleResultState>(
          listenWhen: (BattleResultState previous, BattleResultState current) =>
              previous.reportStatus != current.reportStatus &&
              (current.reportStatus.isSuccess ||
                  current.reportStatus.isFailure),
          listener: (BuildContext context, BattleResultState state) {
            final Failure? failure = state.reportFailure;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  failure == null
                      ? 'Report sent. Thank you!'
                      : failure.hasCode(ApiErrorCodes.reportAlreadyExists)
                      ? 'You already reported this round differently.'
                      : failure.userMessage,
                ),
              ),
            );
            context.read<BattleResultBloc>().add(
              const BattleResultReportDismissed(),
            );
          },
        ),
        BlocListener<AccountBloc, AccountState>(
          listenWhen: (AccountState previous, AccountState current) =>
              previous.entitlementsVersion != null &&
              previous.entitlementsVersion != current.entitlementsVersion,
          listener: (BuildContext context, AccountState state) => context
              .read<BattleResultBloc>()
              .add(const BattleResultRefreshRequested()),
        ),
      ],
      child: AppDesktopViewport(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 56),
          child: BlocBuilder<BattleResultBloc, BattleResultState>(
            buildWhen:
                (BattleResultState previous, BattleResultState current) =>
                    previous.resultStatus != current.resultStatus ||
                    previous.result != current.result ||
                    previous.resultFailure != current.resultFailure,
            builder: (BuildContext context, BattleResultState state) {
              final BattleResultEntity? result = state.result;
              final Failure? failure = state.resultFailure;
              if (result == null && failure != null) {
                return _ResultFailure(battleId: battleId, failure: failure);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 72,
                children: <Widget>[
                  Flexible(
                    flex: 560,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Skeletonizer(
                        enabled: result == null,
                        child: BattleResultSummary(
                          result: result ?? BattleResultSkeletonData.result,
                          disciplineName: formatDisciplineCode(
                            (result ?? BattleResultSkeletonData.result)
                                .disciplineCode,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(flex: 680, child: _Review(result: result)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

final class _Review extends StatelessWidget {
  const _Review({required this.result});

  final BattleResultEntity? result;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BattleResultBloc, BattleResultState>(
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
            onRetry: () => context.read<BattleResultBloc>().add(
              const BattleResultRefreshRequested(),
            ),
          );
        }
        final BattleResultEntity? result = this.result;
        return BlocSelector<AccountBloc, AccountState, bool>(
          selector: (AccountState account) =>
              account.entitlements?.canFilterMistakes ?? false,
          builder: (BuildContext context, bool canFilter) => Skeletonizer(
            enabled: review == null,
            child: RoundReviewList(
              key: ValueKey<int>(review?.answerAccess.entitlementVersion ?? -1),
              review: review ?? BattleResultSkeletonData.review,
              opponentNickname: result?.opponent.nickname ?? '',
              opponentId:
                  result?.opponent.id ??
                  BattleResultSkeletonData.result.opponent.id,
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

final class _ResultFailure extends StatelessWidget {
  const _ResultFailure({required this.battleId, required this.failure});

  final String battleId;
  final Failure failure;

  @override
  Widget build(BuildContext context) {
    if (failure.hasCode(ApiErrorCodes.historyAccessRequired)) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: AppLockedPanel(
            title: 'This match is outside your latest 10',
            message:
                'Free keeps your latest 10 matches open. Pro opens your full '
                'history, including correct answers and explanations. Your '
                'statistics already count every match.',
            onUpgrade: context.goPro,
          ),
        ),
      );
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
      onRetry: () => context.read<BattleResultBloc>().add(
        const BattleResultRefreshRequested(),
      ),
    );
  }
}
