import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/battle_mode.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_status_view.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/core/utils/extensions/go_router_extension.dart';
import 'package:skill_battles/features/account/presentation/bloc/account_bloc/account_bloc.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_disciplines_usecase.dart';
import 'package:skill_battles/features/history/domain/entity/history_page_entity.dart';
import 'package:skill_battles/features/history/domain/entity/history_params_entity.dart';
import 'package:skill_battles/features/history/domain/usecases/get_history_usecase.dart';
import 'package:skill_battles/features/history/presentation/bloc/history_bloc/history_bloc.dart';
import 'package:skill_battles/features/history/presentation/widgets/history_filters.dart';
import 'package:skill_battles/features/history/presentation/widgets/history_skeleton_data.dart';
import 'package:skill_battles/features/history/presentation/widgets/history_table.dart';

/// Match history (Paper: "23 History (Free — latest 10)"). For Free the
/// server keeps only the latest matches before filtering.
final class HistoryScreen extends StatelessWidget implements GoRouterWrapper {
  const HistoryScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<HistoryBloc>(
      create: (_) => HistoryBloc(
        getDisciplines: dependencies.getDep<GetDisciplinesUsecase>(),
        getHistory: dependencies.getDep<GetHistoryUsecase>(),
      )..add(const HistoryStarted()),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    // The Free limit changes what the server returns: re-read on upgrade.
    return BlocListener<AccountBloc, AccountState>(
      listenWhen: (AccountState previous, AccountState current) =>
          previous.entitlementsVersion != null &&
          previous.entitlementsVersion != current.entitlementsVersion,
      listener: (BuildContext context, AccountState state) =>
          context.read<HistoryBloc>().add(const HistoryStarted()),
      child: const AppDesktopViewport(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 64, vertical: 44),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 24,
            children: <Widget>[_Header(), _Body(), _UpgradeBanner()],
          ),
        ),
      ),
    );
  }
}

final class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: <Widget>[
              BlocSelector<AccountBloc, AccountState, int?>(
                selector: (AccountState state) =>
                    state.entitlements?.historyMatchLimit,
                builder: (BuildContext context, int? limit) => AppEyebrow(
                  limit == null
                      ? 'All your matches'
                      : 'Your latest $limit matches',
                ),
              ),
              const Text('Match history', style: AppTextStyles.displayMd),
            ],
          ),
        ),
        const _Filters(),
      ],
    );
  }
}

final class _Filters extends StatelessWidget {
  const _Filters();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryBloc, HistoryState>(
      buildWhen: (HistoryState previous, HistoryState current) =>
          previous.disciplines != current.disciplines ||
          previous.params != current.params,
      builder: (BuildContext context, HistoryState state) {
        final HistoryParamsEntity params = state.params;
        return HistoryFilters(
          disciplines: state.disciplines,
          disciplineCode: params.disciplineCode,
          mode: params.mode,
          onDisciplineSelected: (String? code) =>
              context.read<HistoryBloc>().add(
                HistoryParamsChanged(mode: params.mode, disciplineCode: code),
              ),
          onModeSelected: (BattleMode? mode) => context.read<HistoryBloc>().add(
            HistoryParamsChanged(
              mode: mode,
              disciplineCode: params.disciplineCode,
            ),
          ),
        );
      },
    );
  }
}

final class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryBloc, HistoryState>(
      buildWhen: (HistoryState previous, HistoryState current) =>
          previous.loadStatus != current.loadStatus ||
          previous.page != current.page ||
          previous.failure != current.failure ||
          previous.disciplines != current.disciplines ||
          previous.params != current.params,
      builder: (BuildContext context, HistoryState state) {
        final HistoryParamsEntity params = state.params;
        if (state.loadStatus.isFailure) {
          return AppErrorView(
            message: state.failure?.userMessage ?? '',
            onRetry: () => context.read<HistoryBloc>().add(
              HistoryParamsChanged(
                page: params.page,
                mode: params.mode,
                disciplineCode: params.disciplineCode,
              ),
            ),
          );
        }
        final HistoryPageEntity? page = state.page;
        // A new page or filter is a new question: the old rows don't
        // answer it, so they are skeletonized until it arrives.
        final bool isLoading = page == null || state.loadStatus.isLoading;
        return Skeletonizer(
          enabled: isLoading,
          child: HistoryTable(
            page: isLoading ? HistorySkeletonData.page : page,
            disciplines: state.disciplines,
            onPageSelected: isLoading
                ? null
                : (int index) => context.read<HistoryBloc>().add(
                    HistoryParamsChanged(
                      page: index,
                      mode: params.mode,
                      disciplineCode: params.disciplineCode,
                    ),
                  ),
          ),
        );
      },
    );
  }
}

final class _UpgradeBanner extends StatelessWidget {
  const _UpgradeBanner();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AccountBloc, AccountState, int?>(
      selector: (AccountState state) => state.entitlements?.historyMatchLimit,
      builder: (BuildContext context, int? limit) => limit == null
          ? const SizedBox.shrink()
          : HistoryUpgradeBanner(limit: limit, onUpgrade: context.goPro),
    );
  }
}
