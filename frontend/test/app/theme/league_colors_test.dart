import 'package:test/test.dart';

import 'package:skill_battles/app/theme/league_colors.dart';
import 'package:skill_battles/core/presentation/league/league_rank.dart';

/// An opaque `#RRGGBB` color (the Flutter test checked `alpha == 1`).
final Matcher _opaqueHex = matches(RegExp(r'^#[0-9A-Fa-f]{6}$'));

void main() {
  test('LeagueColors.of returns a palette for every league', () {
    for (final League league in League.values) {
      final LeaguePalette palette = LeagueColors.of(league);
      expect(palette.base.value, _opaqueHex, reason: league.code);
      expect(palette.nameText, isNotNull);
    }
  });

  test('silver name uses the darker override for contrast', () {
    expect(
      LeagueColors.silver.nameText.value,
      LeagueColors.silver.nameOverride!.value,
    );
    expect(LeagueColors.gold.nameText.value, LeagueColors.gold.deep.value);
  });
}
