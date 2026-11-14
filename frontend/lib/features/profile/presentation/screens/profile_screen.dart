import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/core/domain/entity/user_entity.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_segmented_control.dart';
import 'package:skill_battles/core/presentation/widgets/app_status_view.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/core/utils/extensions/go_router_extension.dart';
import 'package:skill_battles/features/account/domain/entity/discipline_stats_entity.dart';
import 'package:skill_battles/features/account/domain/entity/season_peak_entity.dart';
import 'package:skill_battles/features/account/domain/entity/statistics_entity.dart';
import 'package:skill_battles/features/account/domain/usecases/get_season_history_usecase.dart';
import 'package:skill_battles/features/account/domain/usecases/get_statistics_usecase.dart';
import 'package:skill_battles/features/account/presentation/bloc/account_bloc/account_bloc.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_disciplines_usecase.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_ranks_usecase.dart';
import 'package:skill_battles/features/catalog/presentation/extensions/catalog_labels.dart';
import 'package:skill_battles/features/history/domain/entity/history_page_entity.dart';
import 'package:skill_battles/features/history/domain/usecases/get_history_usecase.dart';
import 'package:skill_battles/features/profile/presentation/bloc/profile_bloc/profile_bloc.dart';
import 'package:skill_battles/features/profile/presentation/widgets/match_history_section.dart';
import 'package:skill_battles/features/profile/presentation/widgets/profile_skeleton_data.dart';
import 'package:skill_battles/features/profile/presentation/widgets/profile_stats_section.dart';

/// Ratings, statistics, seasons and match history (Paper: "08 Profile").
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
        getHistory: dependencies.getDep<GetHistoryUsecase>(),
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
          padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
          child: BlocBuilder<ProfileBloc, ProfileState>(
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
                child: _ProfileContent(
                  state: state,
                  statistics: statistics ?? ProfileSkeletonData.statistics,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

final class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.state, required this.statistics});

  final ProfileState state;
  final StatisticsEntity statistics;

  @override
  Widget build(BuildContext context) {
    final DisciplineStatsEntity stats =
        statistics.forDiscipline(state.selectedCode ?? '') ??
        statistics.disciplines.first;
    final int matchCount = statistics.disciplines.fold(
      0,
      (int sum, DisciplineStatsEntity d) =>
          sum + d.ranked.played + d.privateMatches.played,
    );
    final List<SeasonPeakEntity> seasons =
        state.seasons?.items ?? const <SeasonPeakEntity>[];
    final HistoryPageEntity history =
        state.history ?? ProfileSkeletonData.history;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 36,
      children: <Widget>[
        BlocSelector<AccountBloc, AccountState, UserEntity?>(
          selector: (AccountState account) => account.account?.user,
          builder: (BuildContext context, UserEntity? user) =>
              ProfileHeader(user: user, matchCount: matchCount),
        ),
        if (statistics.disciplines.length > 1)
          Align(
            alignment: Alignment.centerLeft,
            child: AppSegmentedControl<String>(
              size: AppSegmentedControlSize.small,
              selected: stats.disciplineCode,
              onSelected: (String code) => context.read<ProfileBloc>().add(
                ProfileDisciplineSelected(code),
              ),
              segments: <AppSegment<String>>[
                for (final DisciplineStatsEntity d in statistics.disciplines)
                  AppSegment<String>(
                    value: d.disciplineCode,
                    label: state.disciplines.nameOf(d.disciplineCode),
                  ),
              ],
            ),
          ),
        ProfileRatingPanel(stats: stats, ranks: state.ranks),
        ProfileMatchStats(stats: stats, streaks: statistics.streaks),
        ProfileAnalyticsSection(stats: stats),
        ProfileSeasonsSection(
          seasons: seasons
              .where(
                (SeasonPeakEntity s) =>
                    s.disciplineCode == stats.disciplineCode,
              )
              .toList(growable: false),
          disciplines: state.disciplines,
          ranks: state.ranks,
        ),
        MatchHistorySection(
          page: history,
          params: state.historyParams,
          disciplines: state.disciplines,
        ),
      ],
    );
  }
}
