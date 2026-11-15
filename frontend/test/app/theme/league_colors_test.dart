import 'package:flutter_test/flutter_test.dart';

import 'package:skill_battles/app/theme/league_colors.dart';
import 'package:skill_battles/core/presentation/league/league_rank.dart';

void main() {
  test('LeagueColors.of returns a palette for every league', () {
    for (final League league in League.values) {
      final LeaguePalette palette = LeagueColors.of(league);
      expect(palette.base.a, 1, reason: league.code);
      expect(palette.nameText, isNotNull);
    }
  });

  test('silver name uses the darker override for contrast', () {
    expect(LeagueColors.silver.nameText, LeagueColors.silver.nameOverride);
    expect(LeagueColors.gold.nameText, LeagueColors.gold.deep);
  });
}
