import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/core/presentation/league/league_rank.dart';

void main() {
  group('League', () {
    test('has the 11 leagues, lowest first', () {
      expect(League.values.map((League l) => l.code), <String>[
        'BRONZE',
        'IRON',
        'SILVER',
        'GOLD',
        'PLATINUM',
        'DIAMOND',
        'EMERALD',
        'BRILLIANT',
        'MASTER',
        'GRANDMASTER',
        'LEGEND',
      ]);
    });

    test('only Bronze..Brilliant are divisional', () {
      expect(League.values.where((League l) => l.isDivisional).length, 8);
      expect(League.brilliant.isDivisional, isTrue);
      expect(League.master.isDivisional, isFalse);
    });
  });

  test('League.displayName capitalizes the league name', () {
    expect(League.bronze.displayName, 'Bronze');
    expect(League.grandmaster.displayName, 'Grandmaster');
    expect(League.legend.displayName, 'Legend');
  });

  group('LeagueRank.tryParse', () {
    for (final League league in League.values.where(
      (League l) => l.isDivisional,
    )) {
      test('${league.code}_I/II/III give division 1/2/3', () {
        expect(LeagueRank.tryParse('${league.code}_I'), LeagueRank(league, 1));
        expect(LeagueRank.tryParse('${league.code}_II'), LeagueRank(league, 2));
        expect(
          LeagueRank.tryParse('${league.code}_III'),
          LeagueRank(league, 3),
        );
      });
    }

    test('bare single-division leagues have no division', () {
      expect(LeagueRank.tryParse('MASTER'), const LeagueRank(League.master));
      expect(
        LeagueRank.tryParse('GRANDMASTER'),
        const LeagueRank(League.grandmaster),
      );
      expect(LeagueRank.tryParse('LEGEND'), const LeagueRank(League.legend));
      expect(LeagueRank.tryParse('LEGEND')!.division, isNull);
    });

    test('a divisional league without a valid suffix is division 1', () {
      expect(LeagueRank.tryParse('GOLD'), const LeagueRank(League.gold, 1));
      expect(LeagueRank.tryParse('GOLD_IV'), const LeagueRank(League.gold, 1));
      expect(LeagueRank.tryParse('GOLD_'), const LeagueRank(League.gold, 1));
      expect(LeagueRank.tryParse('GOLD_X'), const LeagueRank(League.gold, 1));
    });

    test('a suffix on a single-division league is ignored', () {
      expect(LeagueRank.tryParse('MASTER_II'), const LeagueRank(League.master));
    });

    test('is case and whitespace tolerant', () {
      expect(
        LeagueRank.tryParse(' silver_ii '),
        const LeagueRank(League.silver, 2),
      );
    });

    test('unknown league and empty string give null', () {
      expect(LeagueRank.tryParse('COPPER_I'), isNull);
      expect(LeagueRank.tryParse(''), isNull);
      expect(LeagueRank.tryParse('_II'), isNull);
    });
  });

  group('LeagueRank.asset', () {
    test('divisional leagues use the division number', () {
      expect(
        const LeagueRank(League.silver, 2).asset,
        'assets/leagues/silver_2.svg',
      );
    });

    test('single-division leagues use the bare name', () {
      expect(
        const LeagueRank(League.legend).asset,
        'assets/leagues/legend.svg',
      );
    });

    test('a divisional rank without division falls back to _1', () {
      expect(
        AppLeagueAssets.emblem(leagueFile: 'gold', isDivisional: true),
        'assets/leagues/gold_1.svg',
      );
      expect(
        AppLeagueAssets.emblem(
          leagueFile: 'gold',
          isDivisional: true,
          division: 7,
        ),
        'assets/leagues/gold_1.svg',
      );
    });

    test('every league and division has an existing, declared file', () {
      final List<String> assets = <String>[
        for (final League league in League.values)
          if (league.isDivisional)
            for (int d = 1; d <= 3; d++) LeagueRank(league, d).asset
          else
            LeagueRank(league).asset,
      ];
      final String pubspec = File('pubspec.yaml').readAsStringSync();

      expect(assets.toSet(), hasLength(27));
      expect(pubspec, contains('- assets/leagues/'));
      for (final String asset in assets) {
        expect(File(asset).existsSync(), isTrue, reason: asset);
      }
      expect(
        Directory('assets/leagues').listSync().whereType<File>(),
        hasLength(27),
      );
    });
  });
}
