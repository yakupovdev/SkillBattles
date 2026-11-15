import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/core/domain/entity/public_player_entity.dart';
import 'package:skill_battles/core/domain/entity/rank_progress_entity.dart';
import 'package:skill_battles/core/domain/entity/season_entity.dart';
import 'package:skill_battles/core/presentation/widgets/app_progress_bar.dart';
import 'package:skill_battles/features/account/domain/entity/discipline_stats_entity.dart';
import 'package:skill_battles/features/leaderboard/domain/entity/leaderboard_entity.dart';
import 'package:skill_battles/features/leaderboard/domain/entity/leaderboard_entry_entity.dart';
import 'package:skill_battles/features/leaderboard/presentation/widgets/leaderboard_side_panel.dart';
import 'package:skill_battles/features/leaderboard/presentation/widgets/leaderboard_skeleton_data.dart';
import 'package:skill_battles/features/leaderboard/presentation/widgets/leaderboard_table.dart';

LeaderboardEntryEntity _entry(int i, String code) => LeaderboardEntryEntity(
  position: i,
  player: PublicPlayerEntity(id: 'p$i', nickname: 'Player$i', isPro: false),
  rating: 2000 - i,
  rankCode: code,
  isCalibrating: false,
);

LeaderboardEntity _board(List<LeaderboardEntryEntity> top) => LeaderboardEntity(
  disciplineCode: 'math',
  season: SeasonEntity(
    id: 's',
    name: 'S1',
    startsAt: DateTime.utc(2026, 9),
    endsAt: DateTime.utc(2026, 12),
  ),
  generatedAt: DateTime.utc(2026),
  top: top,
  me: null,
);

List<String> _assets(WidgetTester tester) => tester
    .widgetList<SvgPicture>(find.byType(SvgPicture))
    .map((SvgPicture p) => (p.bytesLoader as SvgAssetLoader).assetName)
    .toList();

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1440, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

DisciplineStatsEntity _stats(String code, String name, int? target) {
  final DisciplineStatsEntity m = LeaderboardSkeletonData.stats;
  return DisciplineStatsEntity(
    disciplineCode: 'math',
    rating: 1960,
    rank: RankProgressEntity(
      rankCode: code,
      rankName: name,
      leagueCode: code.split('_').first,
      divisionRpCurrent: 32,
      divisionRpTarget: target,
      floorRating: 1900,
      ceilingExclusive: 2000,
    ),
    calibration: m.calibration,
    allTimePeakRating: 1960,
    allTimePeakRankCode: code,
    seasonId: 's',
    seasonPeakRating: 1960,
    seasonPeakRankCode: code,
    seasonRolloverPending: false,
    ranked: m.ranked,
    privateMatches: m.privateMatches,
    topicStats: null,
    ratingHistory: null,
  );
}

void main() {
  group('LeaderboardTable', () {
    testWidgets('shows the emblem and rank name per row', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        LeaderboardTable(
          board: _board(<LeaderboardEntryEntity>[
            _entry(1, 'MASTER'),
            _entry(2, 'GOLD_III'),
          ]),
        ),
      );

      expect(_assets(tester), <String>[
        'assets/leagues/master.svg',
        'assets/leagues/gold_3.svg',
      ]);
      expect(find.text('Master'), findsOneWidget);
      expect(find.text('Gold III'), findsOneWidget);
    });

    testWidgets('unknown rank code shows the name without emblem', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        LeaderboardTable(
          board: _board(<LeaderboardEntryEntity>[_entry(1, 'COPPER_I')]),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Copper I'), findsOneWidget);
      expect(find.byType(SvgPicture), findsNothing);
    });
  });

  group('LeaderboardSidePanel', () {
    final LeaderboardEntity board = _board(<LeaderboardEntryEntity>[]);

    testWidgets('shows the own league when stats are present', (
      WidgetTester tester,
    ) async {
      final DisciplineStatsEntity stats = _stats(
        'PLATINUM_II',
        'Platinum II',
        100,
      );
      await _pump(
        tester,
        LeaderboardSidePanel(
          board: board,
          disciplines: const [],
          stats: stats,
          seasons: const [],
        ),
      );

      expect(_assets(tester), <String>['assets/leagues/platinum_2.svg']);
      expect(find.text('32 / 100 RP'), findsOneWidget);
    });

    testWidgets('shows no league block without stats', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        LeaderboardSidePanel(
          board: board,
          disciplines: const [],
          stats: null,
          seasons: const [],
        ),
      );

      expect(find.byType(SvgPicture), findsNothing);
    });

    testWidgets('skeleton stats render as a bone, not an SVG', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        Skeletonizer(
          child: LeaderboardSidePanel(
            board: LeaderboardSkeletonData.board,
            disciplines: const [],
            stats: LeaderboardSkeletonData.stats,
            seasons: const [],
          ),
        ),
      );

      expect(find.byType(SvgPicture), findsNothing);
    });
  });

  group('extra', () {
    final LeaderboardEntity board = _board(<LeaderboardEntryEntity>[]);

    testWidgets('sidebar open tier has no progress bar', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        LeaderboardSidePanel(
          board: board,
          disciplines: const [],
          stats: _stats('LEGEND', 'Legend', null),
          seasons: const [],
        ),
      );

      expect(find.text('Open tier'), findsOneWidget);
      expect(find.byType(AppProgressBar), findsNothing);
    });

    testWidgets('Grandmaster sidebar renders in full without overflow', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        LeaderboardSidePanel(
          board: board,
          disciplines: const [],
          stats: _stats('GRANDMASTER', 'Grandmaster', 100),
          seasons: const [],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Grandmaster'), findsOneWidget);
    });

    testWidgets('own row rank name is weight 600, others are not', (
      WidgetTester tester,
    ) async {
      final LeaderboardEntryEntity me = _entry(9, 'GOLD_III');
      await _pump(
        tester,
        LeaderboardTable(
          board: LeaderboardEntity(
            disciplineCode: 'math',
            season: board.season,
            generatedAt: board.generatedAt,
            top: <LeaderboardEntryEntity>[_entry(5, 'GOLD_I'), me],
            me: me,
          ),
        ),
      );

      expect(
        tester.widget<Text>(find.text('Gold III')).style?.fontWeight,
        FontWeight.w600,
      );
      expect(
        tester.widget<Text>(find.text('Gold I')).style?.fontWeight,
        isNot(FontWeight.w600),
      );
    });
  });
}
