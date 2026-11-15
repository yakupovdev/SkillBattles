import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/core/domain/entity/entitlements_entity.dart';
import 'package:skill_battles/core/presentation/widgets/division_pips.dart';
import 'package:skill_battles/features/account/domain/entity/calibration_entity.dart';
import 'package:skill_battles/features/account/domain/entity/discipline_stats_entity.dart';
import 'package:skill_battles/features/account/domain/entity/match_stats_entity.dart';
import 'package:skill_battles/features/account/domain/entity/rank_progress_entity.dart';
import 'package:skill_battles/features/account/domain/entity/statistics_entity.dart';
import 'package:skill_battles/features/account/domain/entity/streaks_entity.dart';
import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';
import 'package:skill_battles/features/catalog/domain/entity/rank_ladder_entity.dart';
import 'package:skill_battles/features/catalog/domain/entity/rank_tier_entity.dart';
import 'package:skill_battles/core/presentation/widgets/league_emblem.dart';
import 'package:skill_battles/features/home/presentation/widgets/home_discipline_cards.dart';

const DisciplineEntity _discipline = DisciplineEntity(
  code: 'math',
  displayName: 'Math',
  description: '',
  questionCount: 5,
  baseQuestionSeconds: 30,
  timings: [],
  schedules: [],
  overtimeSeconds: 5,
  readyTimeoutSeconds: 30,
  countdownSeconds: 3,
  revealSeconds: 3,
  reconnectGraceSeconds: 10,
  contentAvailable: true,
);

const MatchStatsEntity _matches = MatchStatsEntity(
  wins: 0,
  losses: 0,
  draws: 0,
  played: 0,
  winRatePercent: null,
  currentWinStreak: 0,
  bestWinStreak: 0,
  accuracyPercent: null,
  avgAnswerTime: null,
  questionCount: 0,
);

DisciplineStatsEntity _stats({
  required String code,
  required String name,
  int rp = 40,
  int? target = 100,
}) => DisciplineStatsEntity(
  disciplineCode: 'math',
  rating: 1500,
  rank: RankProgressEntity(
    rankCode: code,
    rankName: name,
    leagueCode: code.split('_').first,
    divisionRpCurrent: rp,
    divisionRpTarget: target,
    floorRating: 1400,
    ceilingExclusive: 1600,
  ),
  calibration: const CalibrationEntity(
    completedMatches: 5,
    matchesRemaining: 0,
    isCalibrating: false,
    nextKFactor: 32,
  ),
  allTimePeakRating: 1500,
  allTimePeakRankCode: code,
  seasonId: 's',
  seasonPeakRating: 1500,
  seasonPeakRankCode: code,
  seasonRolloverPending: false,
  ranked: _matches,
  privateMatches: _matches,
  topicStats: null,
  ratingHistory: null,
);

StatisticsEntity _statistics(DisciplineStatsEntity? stats) => StatisticsEntity(
  entitlements: const EntitlementsEntity(
    isPro: false,
    version: 1,
    unlimitedRanked: false,
    historyMatchLimit: null,
    canViewCorrectAnswers: false,
    canViewExplanations: false,
    canViewAdvancedAnalytics: false,
    canFilterMistakes: false,
  ),
  streaks: StreaksEntity(
    dailyCurrent: 0,
    dailyBest: 0,
    lastQualifiedDate: null,
    weeklyCurrent: 0,
    weeklyBest: 0,
    currentWeekStart: DateTime.utc(2026),
    currentWeekActiveDays: 0,
    currentWeekTarget: 3,
  ),
  disciplines: <DisciplineStatsEntity>[?stats],
);

RankTierEntity _tier(String code, String name, int? division) => RankTierEntity(
  code: code,
  displayName: name,
  leagueCode: code.split('_').first,
  floorRating: 0,
  ceilingExclusive: null,
  divisionNumber: division,
);

final RankLadderEntity _ladder = RankLadderEntity(
  tiers: <RankTierEntity>[
    _tier('GOLD_III', 'Gold III', 3),
    _tier('PLATINUM_I', 'Platinum I', 1),
    _tier('LEGEND', 'Legend', null),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  DisciplineStatsEntity? stats, {
  RankLadderEntity? ranks,
  bool skeleton = false,
}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Skeletonizer(
            enabled: skeleton,
            child: HomeDisciplineCards(
              disciplines: const <DisciplineEntity>[_discipline],
              statistics: _statistics(stats),
              ranks: ranks,
              selectedCode: 'math',
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
}

List<String> _assets(WidgetTester tester) => tester
    .widgetList<SvgPicture>(find.byType(SvgPicture))
    .map((SvgPicture p) => (p.bytesLoader as SvgAssetLoader).assetName)
    .where((String a) => a.startsWith('assets/leagues/'))
    .toList();

void main() {
  testWidgets('shows the league hero: emblem, rank name, pips and RP', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _stats(code: 'GOLD_II', name: 'Gold II'));

    expect(_assets(tester), contains('assets/leagues/gold_2.svg'));
    expect(find.text('Gold II'), findsOneWidget);
    expect(find.text('YOUR LEAGUE'), findsOneWidget);
    expect(tester.widget<DivisionPips>(find.byType(DivisionPips)).division, 2);
    expect(find.textContaining('40 / 100 RP'), findsOneWidget);
  });

  testWidgets('shows the next league preview from the ladder', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      _stats(code: 'GOLD_III', name: 'Gold III'),
      ranks: _ladder,
    );

    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Platinum'), findsOneWidget);
    expect(_assets(tester), contains('assets/leagues/platinum_1.svg'));
  });

  testWidgets('hides the next league when the ladder is missing', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _stats(code: 'GOLD_III', name: 'Gold III'));

    expect(find.text('Next'), findsNothing);
  });

  testWidgets('hides the next league in the top league', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      _stats(code: 'LEGEND', name: 'Legend', target: null),
      ranks: _ladder,
    );

    expect(find.text('Next'), findsNothing);
    expect(_assets(tester), <String>['assets/leagues/legend.svg']);
  });

  testWidgets('open tier shows no RP cap and no pips', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _stats(code: 'LEGEND', name: 'Legend', target: null));

    expect(find.textContaining('Open tier · no RP cap'), findsOneWidget);
    expect(find.byType(DivisionPips), findsNothing);
  });

  testWidgets('without statistics no emblem is shown', (
    WidgetTester tester,
  ) async {
    await _pump(tester, null);

    expect(find.text('Math'), findsOneWidget);
    expect(_assets(tester), isEmpty);
    expect(find.text('YOUR LEAGUE'), findsNothing);
  });

  testWidgets('unknown rank code shows the text without emblem or crash', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _stats(code: 'COPPER_I', name: 'Copper I'));

    expect(tester.takeException(), isNull);
    expect(find.text('Copper I'), findsOneWidget);
    expect(_assets(tester), isEmpty);
    expect(find.byType(DivisionPips), findsNothing);
  });

  final RankLadderEntity ladder2 = RankLadderEntity(
    tiers: <RankTierEntity>[
      _tier('MASTER', 'Master', null),
      _tier('GRANDMASTER', 'Grandmaster', null),
    ],
  );

  testWidgets('Master card has no pips and shows the next tier text', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      _stats(code: 'MASTER', name: 'Master'),
      ranks: ladder2,
    );

    expect(_assets(tester), contains('assets/leagues/master.svg'));
    expect(find.byType(DivisionPips), findsNothing);
    expect(
      find.textContaining('· to Grandmaster', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('Grandmaster card renders its full name without overflow', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      _stats(code: 'GRANDMASTER', name: 'Grandmaster', target: null),
      ranks: ladder2,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Grandmaster'), findsOneWidget);
    expect(find.byType(DivisionPips), findsNothing);
  });

  testWidgets('skeleton keeps the real hero, bones the emblem, ignores Next', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      _stats(code: 'GOLD_III', name: 'Gold III'),
      ranks: _ladder,
      skeleton: true,
    );

    expect(_assets(tester), isEmpty);
    expect(find.byType(LeagueEmblem), findsWidgets);
    expect(find.text('Gold III'), findsOneWidget);
    expect(find.text('YOUR LEAGUE'), findsOneWidget);
  });
}
