import 'package:equatable/equatable.dart';

import 'package:skill_battles/app/theme/app_icons.dart';

/// The 11 rating leagues, lowest first.
enum League {
  bronze,
  iron,
  silver,
  gold,
  platinum,
  diamond,
  emerald,
  brilliant,
  master,
  grandmaster,
  legend;

  /// `GOLD`.
  String get code => name.toUpperCase();

  /// `Gold`, `Grandmaster`.
  String get displayName => '${name[0].toUpperCase()}${name.substring(1)}';

  /// Bronze..Brilliant have divisions I-III; the rest are a single division.
  bool get isDivisional => index < League.master.index;

  static League? tryParse(String code) {
    final String upper = code.toUpperCase();
    for (final League league in League.values) {
      if (league.code == upper) return league;
    }
    return null;
  }
}

/// A league and its division, resolved from a backend rank code.
///
/// Codes look like `GOLD_II` (division 1-3, III is the top of the league) or
/// a bare `MASTER` / `GRANDMASTER` / `LEGEND`. [tryParse] is the only place
/// that reads the code; an unknown code gives `null` and the caller shows
/// text only, without an emblem.
final class LeagueRank extends Equatable {
  const LeagueRank(this.league, [this.division]);

  final League league;

  /// 1-3 for a divisional league, `null` for a single-division one.
  final int? division;

  static const Map<String, int> _romans = <String, int>{
    'I': 1,
    'II': 2,
    'III': 3,
  };

  /// `null` for an unknown league. A divisional league without a valid
  /// suffix counts as division I; a suffix on a single-division league is
  /// ignored.
  static LeagueRank? tryParse(String rankCode) {
    final List<String> parts = rankCode.trim().toUpperCase().split('_');
    final League? league = League.tryParse(parts.first);
    if (league == null) return null;
    if (!league.isDivisional) return LeagueRank(league);
    final int? division = parts.length > 1 ? _romans[parts.last] : null;
    return LeagueRank(league, division ?? 1);
  }

  /// The asset of the emblem.
  String get asset => AppLeagueAssets.emblem(
    leagueFile: league.name,
    isDivisional: league.isDivisional,
    division: division,
  );

  @override
  List<Object?> get props => <Object?>[league, division];
}
