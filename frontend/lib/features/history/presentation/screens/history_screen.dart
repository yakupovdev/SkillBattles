import 'package:bloc_signals_jaspr/bloc_signals_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/battle_mode.dart';
import 'package:skill_battles/core/presentation/skeleton/skeletonizer.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_status_view.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/core/utils/extensions/route_extension.dart';
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
final class HistoryScreen extends StatelessComponent implements RouteWrapper {
  const HistoryScreen({super.key});

  @override
  Component wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocSignalProvider<HistoryBloc>(
      create: (_) => HistoryBloc(
        getDisciplines: dependencies.getDep<GetDisciplinesUsecase>(),
        getHistory: dependencies.getDep<GetHistoryUsecase>(),
      )..add(const HistoryStarted()),
      child: this,
    );
  }

  @override
  Component build(BuildContext context) {
    // The Free limit changes what the server returns: re-read on upgrade.
    return BlocSignalListener<AccountBloc, AccountState>(
      listenWhen: (AccountState previous, AccountState current) =>
          previous.entitlementsVersion != null && previous.entitlementsVersion != current.entitlementsVersion,
      listener: (BuildContext context, AccountState state) => context.read<HistoryBloc>().add(const HistoryStarted()),
      child: const AppDesktopViewport(
        child: div(classes: 'history-screen', <Component>[_Header(), _Body(), _UpgradeBanner()]),
      ),
    );
  }
}

final class _Header extends StatelessComponent {
  const _Header();

  @override
  Component build(BuildContext context) {
    return div(classes: 'history-header', <Component>[
      div(classes: 'history-header__titles', <Component>[
        BlocSignalSelector<AccountBloc, AccountState, int?>(
          selector: (AccountState state) => state.entitlements?.historyMatchLimit,
          builder: (BuildContext context, int? limit) =>
              AppEyebrow(limit == null ? 'All your matches' : 'Your latest $limit matches'),
        ),
        const h1(classes: 'history-header__title', <Component>[Component.text('Match history')]),
      ]),
      const _Filters(),
    ]);
  }
}

final class _Filters extends StatelessComponent {
  const _Filters();

  @override
  Component build(BuildContext context) {
    return BlocSignalBuilder<HistoryBloc, HistoryState>(
      buildWhen: (HistoryState previous, HistoryState current) =>
          previous.disciplines != current.disciplines || previous.params != current.params,
      builder: (BuildContext context, HistoryState state) {
        final HistoryParamsEntity params = state.params;
        return HistoryFilters(
          disciplines: state.disciplines,
          disciplineCode: params.disciplineCode,
          mode: params.mode,
          onDisciplineSelected: (String? code) =>
              context.read<HistoryBloc>().add(HistoryParamsChanged(mode: params.mode, disciplineCode: code)),
          onModeSelected: (BattleMode? mode) => context.read<HistoryBloc>().add(
            HistoryParamsChanged(mode: mode, disciplineCode: params.disciplineCode),
          ),
        );
      },
    );
  }
}

final class _Body extends StatelessComponent {
  const _Body();

  @override
  Component build(BuildContext context) {
    return BlocSignalBuilder<HistoryBloc, HistoryState>(
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
              HistoryParamsChanged(page: params.page, mode: params.mode, disciplineCode: params.disciplineCode),
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
                    HistoryParamsChanged(page: index, mode: params.mode, disciplineCode: params.disciplineCode),
                  ),
          ),
        );
      },
    );
  }
}

final class _UpgradeBanner extends StatelessComponent {
  const _UpgradeBanner();

  @override
  Component build(BuildContext context) {
    return BlocSignalSelector<AccountBloc, AccountState, int?>(
      selector: (AccountState state) => state.entitlements?.historyMatchLimit,
      builder: (BuildContext context, int? limit) =>
          limit == null ? const Component.empty() : HistoryUpgradeBanner(limit: limit, onUpgrade: context.goPro),
    );
  }
}

@css
List<StyleRule> get historyScreenStyles => <StyleRule>[
  css('.history-screen').styles(
    display: Display.flex,
    padding: const Padding.symmetric(horizontal: Unit.pixels(64), vertical: Unit.pixels(44)),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(24)),
  ),
  css('.history-header').styles(display: Display.flex, alignItems: AlignItems.end),
  css('.history-header__titles').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(8)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.history-header__title').combine(AppTextStyles.displayMd),
];
