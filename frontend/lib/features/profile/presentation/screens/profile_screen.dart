import 'package:bloc_signals_jaspr/bloc_signals_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/core/presentation/skeleton/skeletonizer.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_segmented_control.dart';
import 'package:skill_battles/core/presentation/widgets/app_status_view.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/core/utils/extensions/route_extension.dart';
import 'package:skill_battles/features/account/domain/entity/discipline_stats_entity.dart';
import 'package:skill_battles/features/account/domain/entity/statistics_entity.dart';
import 'package:skill_battles/features/account/domain/usecases/get_season_history_usecase.dart';
import 'package:skill_battles/features/account/domain/usecases/get_statistics_usecase.dart';
import 'package:skill_battles/features/account/presentation/bloc/account_bloc/account_bloc.dart';
import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_disciplines_usecase.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_ranks_usecase.dart';
import 'package:skill_battles/features/catalog/presentation/extensions/catalog_labels.dart';
import 'package:skill_battles/features/profile/presentation/bloc/profile_bloc/profile_bloc.dart';
import 'package:skill_battles/features/profile/presentation/widgets/profile_skeleton_data.dart';
import 'package:skill_battles/features/profile/presentation/widgets/profile_stats_section.dart';

/// Statistics of one discipline (Paper: "21 Stats (Pro)", "22 Stats (Free —
/// advanced locked)"). Basic statistics count every match on every plan;
/// topic analytics and the Elo graph are Pro.
final class ProfileScreen extends StatelessComponent implements RouteWrapper {
  const ProfileScreen({super.key});

  @override
  Component wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocSignalProvider<ProfileBloc>(
      create: (_) => ProfileBloc(
        getStatistics: dependencies.getDep<GetStatisticsUsecase>(),
        getDisciplines: dependencies.getDep<GetDisciplinesUsecase>(),
        getRanks: dependencies.getDep<GetRanksUsecase>(),
        getSeasonHistory: dependencies.getDep<GetSeasonHistoryUsecase>(),
      )..add(const ProfileStarted()),
      child: this,
    );
  }

  @override
  Component build(BuildContext context) {
    return BlocSignalListener<AccountBloc, AccountState>(
      listenWhen: (AccountState previous, AccountState current) =>
          previous.entitlementsVersion != null && previous.entitlementsVersion != current.entitlementsVersion,
      listener: (BuildContext context, AccountState state) =>
          context.read<ProfileBloc>().add(const ProfileRefreshRequested()),
      child: AppDesktopViewport(
        child: div(classes: 'profile-page', <Component>[
          BlocSignalBuilder<ProfileBloc, ProfileState>(
            buildWhen: (ProfileState previous, ProfileState current) =>
                previous.loadStatus != current.loadStatus ||
                previous.failure != current.failure ||
                previous.statistics != current.statistics ||
                previous.selectedCode != current.selectedCode ||
                previous.disciplines != current.disciplines,
            builder: (BuildContext context, ProfileState state) {
              final StatisticsEntity? statistics = state.statistics;
              if (statistics == null && state.loadStatus.isFailure) {
                return AppErrorView(
                  message: state.failure?.userMessage ?? '',
                  onRetry: () => context.read<ProfileBloc>().add(const ProfileRefreshRequested()),
                );
              }
              return Skeletonizer(
                enabled: statistics == null,
                child: _StatsContent(
                  statistics: statistics ?? ProfileSkeletonData.statistics,
                  selectedCode: state.selectedCode,
                  disciplines: statistics == null ? ProfileSkeletonData.disciplines : state.disciplines,
                ),
              );
            },
          ),
        ]),
      ),
    );
  }
}

final class _StatsContent extends StatelessComponent {
  const _StatsContent({required this.statistics, required this.selectedCode, required this.disciplines});

  final StatisticsEntity statistics;
  final String? selectedCode;
  final List<DisciplineEntity> disciplines;

  @override
  Component build(BuildContext context) {
    final DisciplineStatsEntity stats = statistics.forDiscipline(selectedCode ?? '') ?? statistics.disciplines.first;
    return div(classes: 'profile-stats', <Component>[
      div(classes: 'profile-stats__header', <Component>[
        div(classes: 'profile-stats__heading', <Component>[
          AppEyebrow('All-time · ${formatRankCode(stats.seasonId)} season'),
          h1(classes: 'profile-stats__title', <Component>[
            Component.text('${disciplines.nameOf(stats.disciplineCode)} stats'),
          ]),
        ]),
        if (statistics.disciplines.length > 1)
          AppSegmentedControl<String>(
            size: AppSegmentedControlSize.medium,
            selected: stats.disciplineCode,
            onSelected: (String code) => context.read<ProfileBloc>().add(ProfileDisciplineSelected(code)),
            segments: <AppSegment<String>>[
              for (final DisciplineStatsEntity d in statistics.disciplines)
                AppSegment<String>(value: d.disciplineCode, label: disciplines.nameOf(d.disciplineCode)),
            ],
          ),
      ]),
      ProfileKpiStrip(stats: stats),
      ProfileAnalyticsSection(stats: stats),
    ]);
  }
}

@css
List<StyleRule> get profileScreenStyles => <StyleRule>[
  css('.profile-page').styles(
    display: Display.flex,
    padding: const Padding.symmetric(horizontal: Unit.pixels(64), vertical: Unit.pixels(44)),
    flexDirection: FlexDirection.column,
  ),
  css('.profile-stats').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(32)),
  ),
  css('.profile-stats__header').styles(
    display: Display.flex,
    alignItems: AlignItems.end,
    gap: const Gap.column(Unit.pixels(24)),
  ),
  css('.profile-stats__heading').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(8)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.profile-stats__title')
      .styles(
        maxWidth: const Unit.percent(100),
        overflow: Overflow.hidden,
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.displayMd),
];
