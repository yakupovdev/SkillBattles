import 'package:bloc_signals_jaspr/bloc_signals_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/season_entity.dart';
import 'package:skill_battles/core/presentation/skeleton/skeletonizer.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_segmented_control.dart';
import 'package:skill_battles/core/presentation/widgets/app_status_view.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/core/utils/extensions/route_extension.dart';
import 'package:skill_battles/features/account/domain/entity/season_peak_entity.dart';
import 'package:skill_battles/features/account/domain/usecases/get_season_history_usecase.dart';
import 'package:skill_battles/features/account/domain/usecases/get_statistics_usecase.dart';
import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_disciplines_usecase.dart';
import 'package:skill_battles/features/catalog/domain/usecases/get_ranks_usecase.dart';
import 'package:skill_battles/features/leaderboard/domain/entity/leaderboard_entity.dart';
import 'package:skill_battles/features/leaderboard/domain/usecases/get_leaderboard_usecase.dart';
import 'package:skill_battles/features/leaderboard/presentation/bloc/leaderboard_bloc/leaderboard_bloc.dart';
import 'package:skill_battles/features/leaderboard/presentation/widgets/leaderboard_side_panel.dart';
import 'package:skill_battles/features/leaderboard/presentation/widgets/leaderboard_skeleton_data.dart';
import 'package:skill_battles/features/leaderboard/presentation/widgets/leaderboard_table.dart';

/// The current-season league ladder above the top 50 and your own row.
final class LeaderboardScreen extends StatelessComponent implements RouteWrapper {
  const LeaderboardScreen({this.disciplineCode, super.key});

  final String? disciplineCode;

  @override
  Component wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocSignalProvider<LeaderboardBloc>(
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
  Component build(BuildContext context) {
    return AppDesktopViewport(
      child: div(classes: 'leaderboard-screen', <Component>[
        const _Header(),
        div(classes: 'leaderboard-screen__body', <Component>[
          div(classes: 'leaderboard-screen__main', <Component>[
            const h2(classes: 'leaderboard-screen__title', <Component>[Component.text('Leaderboard')]),
            _Table(disciplineCode: disciplineCode),
          ]),
          const _Side(),
        ]),
      ]),
    );
  }
}

final class _Header extends StatelessComponent {
  const _Header();

  /// `Fall 2026 · 16 days left`.
  static String _seasonLine(SeasonEntity season, DateTime now) {
    final int days = (season.endsAt.difference(now).inHours / 24).ceil();
    final String left = days <= 1 ? 'last day' : '$days days left';
    return '${season.name} · $left';
  }

  @override
  Component build(BuildContext context) {
    return BlocSignalBuilder<LeaderboardBloc, LeaderboardState>(
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
        return div(classes: 'leaderboard-header', <Component>[
          div(classes: 'leaderboard-header__titles', <Component>[
            // The wrapper is the skeleton root, so the eyebrow is one of its
            // leaves.
            Skeletonizer(
              enabled: board == null && !failed,
              child: div(<Component>[
                AppEyebrow(
                  failed
                      ? disciplineName ?? 'Season rankings'
                      : '${disciplineName == null ? '' : '$disciplineName · '}'
                            '${_seasonLine((board ?? LeaderboardSkeletonData.board).season, DateTime.now())}',
                ),
              ]),
            ),
            const h1(classes: 'leaderboard-header__title', <Component>[Component.text('Your climb')]),
          ]),
          if (disciplines.length > 1)
            AppSegmentedControl<String>(
              size: AppSegmentedControlSize.medium,
              selected: state.selectedCode ?? '',
              onSelected: (String code) => context.read<LeaderboardBloc>().add(LeaderboardDisciplineSelected(code)),
              segments: <AppSegment<String>>[
                for (final DisciplineEntity d in disciplines) AppSegment<String>(value: d.code, label: d.displayName),
              ],
            ),
        ]);
      },
    );
  }
}

final class _Table extends StatelessComponent {
  const _Table({required this.disciplineCode});

  final String? disciplineCode;

  @override
  Component build(BuildContext context) {
    return BlocSignalBuilder<LeaderboardBloc, LeaderboardState>(
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
          child: LeaderboardTable(board: board ?? LeaderboardSkeletonData.board),
        );
      },
    );
  }
}

/// The right column with a rule on its left edge.
final class _Side extends StatelessComponent {
  const _Side();

  @override
  Component build(BuildContext context) {
    return BlocSignalBuilder<LeaderboardBloc, LeaderboardState>(
      buildWhen: (LeaderboardState previous, LeaderboardState current) =>
          previous.board != current.board ||
          previous.boardStatus != current.boardStatus ||
          previous.disciplines != current.disciplines ||
          previous.statistics != current.statistics ||
          previous.seasons != current.seasons,
      builder: (BuildContext context, LeaderboardState state) {
        final LeaderboardEntity? board = state.board;
        if (board == null && state.boardStatus.isFailure) {
          return const Component.empty();
        }
        final LeaderboardEntity shown = board ?? LeaderboardSkeletonData.board;
        final List<SeasonPeakEntity> seasons = state.seasons?.items ?? const <SeasonPeakEntity>[];
        return div(classes: 'leaderboard-side', <Component>[
          Skeletonizer(
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
        ]);
      },
    );
  }
}

@css
List<StyleRule> get leaderboardScreenStyles => <StyleRule>[
  css('.leaderboard-screen').styles(
    display: Display.flex,
    padding: const Padding.only(
      left: Unit.pixels(64),
      top: Unit.pixels(48),
      right: Unit.pixels(64),
      bottom: Unit.pixels(64),
    ),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(40)),
  ),
  css('.leaderboard-screen__body').styles(
    display: Display.flex,
    alignItems: AlignItems.stretch,
    gap: const Gap.column(Unit.pixels(64)),
  ),
  css('.leaderboard-screen__main').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(28)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.leaderboard-screen__title').combine(AppTextStyles.titleXl),
  css('.leaderboard-header').styles(display: Display.flex, alignItems: AlignItems.end),
  css('.leaderboard-header__titles').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(8)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.leaderboard-header__title').combine(AppTextStyles.displayMd),
  css('.leaderboard-side').styles(
    width: const Unit.pixels(LeaderboardSidePanel.width),
    padding: const Padding.only(left: Unit.pixels(40)),
    border: const Border.only(
      left: BorderSide(color: AppColors.border, width: Unit.pixels(1)),
    ),
    flex: const Flex(shrink: 0),
  ),
];
