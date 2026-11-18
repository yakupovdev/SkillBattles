import 'package:bloc_signals_jaspr/bloc_signals_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/season_entity.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/skeleton/skeletonizer.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_status_view.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/core/utils/extensions/route_extension.dart';
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
final class HomeScreen extends StatefulComponent implements RouteWrapper {
  const HomeScreen({super.key});

  @override
  Component wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocSignalProvider<HomeBloc>(
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
  Component build(BuildContext context) {
    return MultiBlocSignalListener(
      listeners: <BlocSignalListenerSingleChildComponent>[
        BlocSignalListener<HomeBloc, HomeState>(
          listenWhen: (HomeState previous, HomeState current) =>
              previous.joinedBattleId != current.joinedBattleId && current.joinedBattleId != null,
          listener: (BuildContext context, HomeState state) => context.goBattle(state.joinedBattleId!),
        ),
        BlocSignalListener<AccountBloc, AccountState>(
          listenWhen: (AccountState previous, AccountState current) =>
              previous.entitlementsVersion != null && previous.entitlementsVersion != current.entitlementsVersion,
          listener: (BuildContext context, AccountState state) =>
              context.read<HomeBloc>().add(const HomeRefreshRequested()),
        ),
      ],
      child: AppDesktopViewport(
        child: div(classes: 'home-screen', <Component>[
          BlocSignalBuilder<HomeBloc, HomeState>(
            buildWhen: (HomeState previous, HomeState current) =>
                previous.loadStatus != current.loadStatus ||
                previous.hasContent != current.hasContent ||
                previous.failure != current.failure,
            builder: (BuildContext context, HomeState state) {
              if (state.loadStatus.isFailure && !state.hasContent) {
                return AppErrorView(
                  message: state.failure?.userMessage ?? '',
                  onRetry: () => context.read<HomeBloc>().add(const HomeRefreshRequested()),
                );
              }
              return Skeletonizer(enabled: !state.hasContent, child: const _HomeContent());
            },
          ),
        ]),
      ),
    );
  }
}

final class _HomeContent extends StatelessComponent {
  const _HomeContent();

  @override
  Component build(BuildContext context) {
    // The content box takes the viewport's minimum height, so the sidebar
    // divider runs down the whole page as on the artboard.
    return div(classes: 'home-content', <Component>[
      div(classes: 'home-content__main', <Component>[
        BlocSignalBuilder<HomeBloc, HomeState>(
          buildWhen: (HomeState previous, HomeState current) =>
              previous.disciplines != current.disciplines ||
              previous.statistics != current.statistics ||
              previous.ranks != current.ranks ||
              previous.selectedCode != current.selectedCode ||
              previous.activity != current.activity ||
              previous.season != current.season,
          builder: (BuildContext context, HomeState state) {
            final bool real = state.hasContent;
            return div(classes: 'home-content__column', <Component>[
              _Header(season: state.season),
              if (real && !state.activity.isNone) HomeActivityBanner(activity: state.activity),
              HomeDisciplineCards(
                disciplines: real ? state.disciplines : HomeSkeletonData.disciplines,
                statistics: state.statistics ?? HomeSkeletonData.statistics,
                ranks: state.ranks,
                selectedCode: real ? state.selectedCode : HomeSkeletonData.disciplines.first.code,
                onSelected: (String code) => context.read<HomeBloc>().add(HomeDisciplineSelected(code)),
              ),
              BlocSignalSelector<AccountBloc, AccountState, LimitsEntity?>(
                selector: (AccountState account) => account.account?.limits,
                builder: (BuildContext context, LimitsEntity? limits) =>
                    HomeModeSection(discipline: real ? state.selected : null, limits: limits),
              ),
            ]);
          },
        ),
      ]),
      BlocSignalSelector<HomeBloc, HomeState, StreaksEntity>(
        selector: (HomeState state) => (state.statistics ?? HomeSkeletonData.statistics).streaks,
        builder: (BuildContext context, StreaksEntity streaks) => BlocSignalBuilder<AccountBloc, AccountState>(
          buildWhen: (AccountState previous, AccountState current) =>
              previous.isPro != current.isPro || previous.account?.limits.date != current.account?.limits.date,
          builder: (BuildContext context, AccountState account) => HomeSidebar(
            streaks: streaks,
            today: account.account?.limits.date ?? DateTime.now(),
            isPro: account.isPro,
          ),
        ),
      ),
      Skeleton.keep(
        child: const div(
          classes: 'home-content__divider',
          attributes: <String, String>{'aria-hidden': 'true'},
          <Component>[],
        ),
      ),
    ]);
  }
}

final class _Header extends StatelessComponent {
  const _Header({required this.season});

  final SeasonEntity? season;

  @override
  Component build(BuildContext context) {
    final SeasonEntity? season = this.season;
    return div(classes: 'home-header', <Component>[
      AppEyebrow(
        season == null
            ? 'Choose a discipline'
            : '${season.name} season · ends '
                  '${DisplayFormatters.etBoundaryDay(season.endsAt)}',
      ),
      const h1(classes: 'home-header__title', <Component>[Component.text('What are we battling today?')]),
    ]);
  }
}

@css
List<StyleRule> get homeScreenStyles => <StyleRule>[
  css('.home-screen').styles(
    display: Display.flex,
    padding: const Padding.symmetric(horizontal: Unit.pixels(64), vertical: Unit.pixels(48)),
    flexDirection: FlexDirection.column,
  ),
  css('.home-content').styles(
    display: Display.flex,
    position: const Position.relative(),
    flexDirection: FlexDirection.row,
    alignItems: AlignItems.start,
    gap: const Gap.column(Unit.pixels(64)),
    flex: const Flex(grow: 1, shrink: 0, basis: Unit.auto),
  ),
  css('.home-content__main').styles(
    minWidth: Unit.zero,
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.home-content__column').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(36)),
  ),
  css('.home-content__divider').styles(
    position: Position.absolute(top: Unit.zero, right: Unit.pixels(HomeSidebar.width - 1), bottom: Unit.zero),
    width: const Unit.pixels(1),
    backgroundColor: AppColors.border,
  ),
  css('.home-header').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(8)),
  ),
  css('.home-header__title').combine(AppTextStyles.displayMd),
];
