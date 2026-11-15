import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/season_entity.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_segmented_control.dart';
import 'package:skill_battles/core/presentation/widgets/app_status_view.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/core/utils/extensions/go_router_extension.dart';
import 'package:skill_battles/features/account/domain/entity/season_peak_entity.dart';
import 'package:skill_battles/features/account/domain/usecases/get_season_history_usecase.dart';
import 'package:skill_battles/features/account/domain/usecases/get_statistics_usecase.dart';
import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_disciplines_usecase.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_ranks_usecase.dart';
import 'package:skill_battles/features/leaderboard/domain/entity/leaderboard_entity.dart';
import 'package:skill_battles/features/leaderboard/domain/usecases/get_leaderboard_usecase.dart';
import 'package:skill_battles/features/leaderboard/presentation/bloc/leaderboard_bloc/leaderboard_bloc.dart';
// import 'package:skill_battles/features/leaderboard/presentation/widgets/leaderboard_climb_board.dart';
import 'package:skill_battles/features/leaderboard/presentation/widgets/leaderboard_side_panel.dart';
import 'package:skill_battles/features/leaderboard/presentation/widgets/leaderboard_skeleton_data.dart';
import 'package:skill_battles/features/leaderboard/presentation/widgets/leaderboard_table.dart';

/// The current-season league ladder above the top 50 and your own row.
final class LeaderboardScreen extends StatelessWidget
    implements GoRouterWrapper {
  const LeaderboardScreen({this.disciplineCode, super.key});

  final String? disciplineCode;

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<LeaderboardBloc>(
      create: (_) => LeaderboardBloc(
        getDisciplines: dependencies.getDep<GetDisciplinesUsecase>(),
        getRanks: dependencies.getDep<GetRanksUsecase>(),
        getLeaderboard: dependencies.getDep<GetLeaderboardUsecase>(),
        getStatistics: dependencies.getDep<GetStatisticsUsecase>(),
        getSeasonHistory: dependencies.getDep<GetSeasonHistoryUsecase>(),
      )..add(LeaderboardStarted(disciplineCode: disciplineCode)),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDesktopViewport(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(64, 48, 64, 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 40,
          children: <Widget>[
            const _Header(),
            // const _ClimbBoard(),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 64,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 28,
                      children: <Widget>[
                        const Text('Leaderboard', style: AppTextStyles.titleXl),
                        _Table(disciplineCode: disciplineCode),
                      ],
                    ),
                  ),
                  const _Side(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _Header extends StatelessWidget {
  const _Header();

  /// `Fall 2026 · 16 days left`.
  static String _seasonLine(SeasonEntity season, DateTime now) {
    final int days = (season.endsAt.difference(now).inHours / 24).ceil();
    final String left = days <= 1 ? 'last day' : '$days days left';
    return '${season.name} · $left';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeaderboardBloc, LeaderboardState>(
      buildWhen: (LeaderboardState previous, LeaderboardState current) =>
          previous.board != current.board ||
          previous.boardStatus != current.boardStatus ||
          previous.disciplines != current.disciplines ||
          previous.selectedCode != current.selectedCode,
      builder: (BuildContext context, LeaderboardState state) {
        final LeaderboardEntity? board = state.board;
        final List<DisciplineEntity> disciplines = state.disciplines;
        String? disciplineName;
        for (final DisciplineEntity discipline in disciplines) {
          if (discipline.code == state.selectedCode) {
            disciplineName = discipline.displayName;
            break;
          }
        }
        final bool failed = board == null && state.boardStatus.isFailure;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: <Widget>[
                  Skeletonizer(
                    enabled: board == null && !failed,
                    child: AppEyebrow(
                      failed
                          ? disciplineName ?? 'Season rankings'
                          : '${disciplineName == null ? '' : '$disciplineName · '}${_seasonLine((board ?? LeaderboardSkeletonData.board).season, DateTime.now())}',
                    ),
                  ),
                  const Text('Your climb', style: AppTextStyles.displayMd),
                ],
              ),
            ),
            if (disciplines.length > 1)
              AppSegmentedControl<String>(
                size: AppSegmentedControlSize.medium,
                selected: state.selectedCode ?? '',
                onSelected: (String code) => context
                    .read<LeaderboardBloc>()
                    .add(LeaderboardDisciplineSelected(code)),
                segments: <AppSegment<String>>[
                  for (final DisciplineEntity d in disciplines)
                    AppSegment<String>(value: d.code, label: d.displayName),
                ],
              ),
          ],
        );
      },
    );
  }
}

// final class _ClimbBoard extends StatelessWidget {
//   const _ClimbBoard();

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<LeaderboardBloc, LeaderboardState>(
//       buildWhen: (LeaderboardState previous, LeaderboardState current) =>
//           previous.board != current.board ||
//           previous.boardStatus != current.boardStatus ||
//           previous.statistics != current.statistics ||
//           previous.ranks != current.ranks,
//       builder: (BuildContext context, LeaderboardState state) {
//         final LeaderboardEntity? board = state.board;
//         if (board == null && state.boardStatus.isFailure) {
//           return const SizedBox.shrink();
//         }
//         return Skeletonizer(
//           enabled: board == null,
//           child: LeaderboardClimbBoard(
//             board: board ?? LeaderboardSkeletonData.climbBoard,
//             stats: board == null
//                 ? LeaderboardSkeletonData.stats
//                 : state.statistics?.forDiscipline(board.disciplineCode),
//             ranks: state.ranks,
//           ),
//         );
//       },
//     );
//   }
// }

final class _Table extends StatelessWidget {
  const _Table({required this.disciplineCode});

  final String? disciplineCode;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeaderboardBloc, LeaderboardState>(
      buildWhen: (LeaderboardState previous, LeaderboardState current) =>
          previous.board != current.board ||
          previous.boardStatus != current.boardStatus ||
          previous.failure != current.failure ||
          previous.selectedCode != current.selectedCode,
      builder: (BuildContext context, LeaderboardState state) {
        final LeaderboardEntity? board = state.board;
        if (board == null && state.boardStatus.isFailure) {
          return AppErrorView(
            message: state.failure?.userMessage ?? '',
            onRetry: () => context.read<LeaderboardBloc>().add(
              state.selectedCode == null
                  ? LeaderboardStarted(disciplineCode: disciplineCode)
                  : LeaderboardDisciplineSelected(state.selectedCode!),
            ),
          );
        }
        return Skeletonizer(
          enabled: board == null,
          child: LeaderboardTable(
            board: board ?? LeaderboardSkeletonData.board,
          ),
        );
      },
    );
  }
}

/// The right column with a rule on its left edge.
final class _Side extends StatelessWidget {
  const _Side();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeaderboardBloc, LeaderboardState>(
      buildWhen: (LeaderboardState previous, LeaderboardState current) =>
          previous.board != current.board ||
          previous.boardStatus != current.boardStatus ||
          previous.disciplines != current.disciplines ||
          previous.statistics != current.statistics ||
          previous.seasons != current.seasons,
      builder: (BuildContext context, LeaderboardState state) {
        final LeaderboardEntity? board = state.board;
        if (board == null && state.boardStatus.isFailure) {
          return const SizedBox.shrink();
        }
        final LeaderboardEntity shown = board ?? LeaderboardSkeletonData.board;
        final List<SeasonPeakEntity> seasons =
            state.seasons?.items ?? const <SeasonPeakEntity>[];
        return Container(
          width: LeaderboardSidePanel.width,
          padding: const EdgeInsets.only(left: 40),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: AppColors.border)),
          ),
          alignment: Alignment.topLeft,
          child: Skeletonizer(
            enabled: board == null,
            child: LeaderboardSidePanel(
              board: shown,
              disciplines: state.disciplines,
              stats: board == null
                  ? LeaderboardSkeletonData.stats
                  : state.statistics?.forDiscipline(shown.disciplineCode),
              seasons: seasons,
            ),
          ),
        );
      },
    );
  }
}
