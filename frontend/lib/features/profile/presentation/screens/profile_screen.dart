import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_segmented_control.dart';
import 'package:skill_battles/core/presentation/widgets/app_status_view.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/core/utils/extensions/go_router_extension.dart';
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
final class ProfileScreen extends StatelessWidget implements GoRouterWrapper {
  const ProfileScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<ProfileBloc>(
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
  Widget build(BuildContext context) {
    return BlocListener<AccountBloc, AccountState>(
      listenWhen: (AccountState previous, AccountState current) =>
          previous.entitlementsVersion != null &&
          previous.entitlementsVersion != current.entitlementsVersion,
      listener: (BuildContext context, AccountState state) =>
          context.read<ProfileBloc>().add(const ProfileRefreshRequested()),
      child: AppDesktopViewport(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 44),
          child: BlocBuilder<ProfileBloc, ProfileState>(
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
                  onRetry: () => context.read<ProfileBloc>().add(
                    const ProfileRefreshRequested(),
                  ),
                );
              }
              return Skeletonizer(
                enabled: statistics == null,
                child: _StatsContent(
                  statistics: statistics ?? ProfileSkeletonData.statistics,
                  selectedCode: state.selectedCode,
                  disciplines: statistics == null
                      ? ProfileSkeletonData.disciplines
                      : state.disciplines,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

final class _StatsContent extends StatelessWidget {
  const _StatsContent({
    required this.statistics,
    required this.selectedCode,
    required this.disciplines,
  });

  final StatisticsEntity statistics;
  final String? selectedCode;
  final List<DisciplineEntity> disciplines;

  @override
  Widget build(BuildContext context) {
    final DisciplineStatsEntity stats =
        statistics.forDiscipline(selectedCode ?? '') ??
        statistics.disciplines.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 32,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 24,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: <Widget>[
                  AppEyebrow(
                    'All-time · ${formatRankCode(stats.seasonId)} season',
                  ),
                  Text(
                    '${disciplines.nameOf(stats.disciplineCode)} stats',
                    style: AppTextStyles.displayMd,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (statistics.disciplines.length > 1)
              AppSegmentedControl<String>(
                size: AppSegmentedControlSize.medium,
                selected: stats.disciplineCode,
                onSelected: (String code) => context.read<ProfileBloc>().add(
                  ProfileDisciplineSelected(code),
                ),
                segments: <AppSegment<String>>[
                  for (final DisciplineStatsEntity d in statistics.disciplines)
                    AppSegment<String>(
                      value: d.disciplineCode,
                      label: disciplines.nameOf(d.disciplineCode),
                    ),
                ],
              ),
          ],
        ),
        ProfileKpiStrip(stats: stats),
        ProfileAnalyticsSection(stats: stats),
      ],
    );
  }
}
