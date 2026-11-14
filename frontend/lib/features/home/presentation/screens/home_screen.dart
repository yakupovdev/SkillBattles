import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/season_entity.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_status_view.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/core/utils/extensions/go_router_extension.dart';
import 'package:skill_battles/features/account/domain/entity/limits_entity.dart';
import 'package:skill_battles/features/account/domain/entity/streaks_entity.dart';
import 'package:skill_battles/features/account/domain/usecases/get_activity_usecase.dart';
import 'package:skill_battles/features/account/domain/usecases/get_statistics_usecase.dart';
import 'package:skill_battles/features/account/presentation/bloc/account_bloc/account_bloc.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_current_season_usecase.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_disciplines_usecase.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_ranks_usecase.dart';
import 'package:skill_battles/features/home/presentation/bloc/home_bloc/home_bloc.dart';
import 'package:skill_battles/features/home/presentation/widgets/home_activity_banner.dart';
import 'package:skill_battles/features/home/presentation/widgets/home_discipline_cards.dart';
import 'package:skill_battles/features/home/presentation/widgets/home_mode_section.dart';
import 'package:skill_battles/features/home/presentation/widgets/home_sidebar.dart';
import 'package:skill_battles/features/home/presentation/widgets/home_skeleton_data.dart';
import 'package:skill_battles/features/private_duel/domain/usecases/join_duel_usecase.dart';

/// Discipline and mode picker with ratings, limits and streaks
/// (Paper: "14 Home v0.3").
final class HomeScreen extends StatefulWidget implements GoRouterWrapper {
  const HomeScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<HomeBloc>(
      create: (_) => HomeBloc(
        getDisciplines: dependencies.getDep<GetDisciplinesUsecase>(),
        getRanks: dependencies.getDep<GetRanksUsecase>(),
        getStatistics: dependencies.getDep<GetStatisticsUsecase>(),
        getActivity: dependencies.getDep<GetActivityUsecase>(),
        getCurrentSeason: dependencies.getDep<GetCurrentSeasonUsecase>(),
        joinDuel: dependencies.getDep<JoinDuelUsecase>(),
      )..add(const HomeStarted()),
      child: this,
    );
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

final class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Limits and plan may have changed during a match.
    context.read<AccountBloc>().add(const AccountRefreshRequested());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: <BlocListener<dynamic, dynamic>>[
        BlocListener<HomeBloc, HomeState>(
          listenWhen: (HomeState previous, HomeState current) =>
              previous.joinedBattleId != current.joinedBattleId &&
              current.joinedBattleId != null,
          listener: (BuildContext context, HomeState state) =>
              context.goBattle(state.joinedBattleId!),
        ),
        BlocListener<AccountBloc, AccountState>(
          listenWhen: (AccountState previous, AccountState current) =>
              previous.entitlementsVersion != null &&
              previous.entitlementsVersion != current.entitlementsVersion,
          listener: (BuildContext context, AccountState state) =>
              context.read<HomeBloc>().add(const HomeRefreshRequested()),
        ),
      ],
      child: AppDesktopViewport(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
          child: BlocBuilder<HomeBloc, HomeState>(
            buildWhen: (HomeState previous, HomeState current) =>
                previous.loadStatus != current.loadStatus ||
                previous.hasContent != current.hasContent ||
                previous.failure != current.failure,
            builder: (BuildContext context, HomeState state) {
              if (state.loadStatus.isFailure && !state.hasContent) {
                return AppErrorView(
                  message: state.failure?.userMessage ?? '',
                  onRetry: () => context.read<HomeBloc>().add(
                    const HomeRefreshRequested(),
                  ),
                );
              }
              return Skeletonizer(
                enabled: !state.hasContent,
                child: const _HomeContent(),
              );
            },
          ),
        ),
      ),
    );
  }
}

final class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    // The Stack takes the viewport's minimum height, so the sidebar divider
    // runs down the whole page as on the artboard.
    return Stack(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 64,
          children: <Widget>[
            Expanded(
              child: BlocBuilder<HomeBloc, HomeState>(
                buildWhen: (HomeState previous, HomeState current) =>
                    previous.disciplines != current.disciplines ||
                    previous.statistics != current.statistics ||
                    previous.ranks != current.ranks ||
                    previous.selectedCode != current.selectedCode ||
                    previous.activity != current.activity ||
                    previous.season != current.season,
                builder: (BuildContext context, HomeState state) {
                  final bool real = state.hasContent;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 36,
                    children: <Widget>[
                      _Header(season: state.season),
                      if (real && !state.activity.isNone)
                        HomeActivityBanner(activity: state.activity),
                      HomeDisciplineCards(
                        disciplines: real
                            ? state.disciplines
                            : HomeSkeletonData.disciplines,
                        statistics:
                            state.statistics ?? HomeSkeletonData.statistics,
                        ranks: state.ranks,
                        selectedCode: real
                            ? state.selectedCode
                            : HomeSkeletonData.disciplines.first.code,
                        onSelected: (String code) => context
                            .read<HomeBloc>()
                            .add(HomeDisciplineSelected(code)),
                      ),
                      BlocSelector<AccountBloc, AccountState, LimitsEntity?>(
                        selector: (AccountState account) =>
                            account.account?.limits,
                        builder: (BuildContext context, LimitsEntity? limits) =>
                            HomeModeSection(
                              discipline: real ? state.selected : null,
                              limits: limits,
                            ),
                      ),
                    ],
                  );
                },
              ),
            ),
            BlocSelector<HomeBloc, HomeState, StreaksEntity>(
              selector: (HomeState state) =>
                  (state.statistics ?? HomeSkeletonData.statistics).streaks,
              builder: (BuildContext context, StreaksEntity streaks) =>
                  BlocBuilder<AccountBloc, AccountState>(
                    buildWhen: (AccountState previous, AccountState current) =>
                        previous.isPro != current.isPro ||
                        previous.account?.limits.date !=
                            current.account?.limits.date,
                    builder: (BuildContext context, AccountState account) =>
                        HomeSidebar(
                          streaks: streaks,
                          today: account.account?.limits.date ?? DateTime.now(),
                          isPro: account.isPro,
                        ),
                  ),
            ),
          ],
        ),
        const Positioned(
          top: 0,
          bottom: 0,
          right: HomeSidebar.width - 1,
          width: 1,
          child: ColoredBox(color: AppColors.border),
        ),
      ],
    );
  }
}

final class _Header extends StatelessWidget {
  const _Header({required this.season});

  final SeasonEntity? season;

  @override
  Widget build(BuildContext context) {
    final SeasonEntity? season = this.season;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: <Widget>[
        AppEyebrow(
          season == null
              ? 'Choose a discipline'
              : '${season.name} season · ends '
                    '${DisplayFormatters.etBoundaryDay(season.endsAt)}',
        ),
        const Text(
          'What are we battling today?',
          style: AppTextStyles.displayMd,
        ),
      ],
    );
  }
}
