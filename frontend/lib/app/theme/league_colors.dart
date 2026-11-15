import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/core/presentation/league/league_rank.dart';

/// Colors of one league around its emblem (the emblem's own colors live in
/// the SVG): the hero circle, pips, progress fill and the league name.
final class LeaguePalette {
  const LeaguePalette({
    required this.base,
    required this.deep,
    required this.tint,
    this.nameOverride,
  });

  final Color base;
  final Color deep;
  final Color tint;

  /// Replaces [deep] as the name color when it lacks contrast.
  final Color? nameOverride;

  /// Color of the league name on a light surface.
  Color get nameText => nameOverride ?? deep;
}

/// League palette of the Paper design ("League emblems" spec), next to
/// `AppColors`.
abstract final class LeagueColors {
  static const LeaguePalette bronze = LeaguePalette(
    base: Color(0xFFC07A45),
    deep: Color(0xFF7A4520),
    tint: Color(0xFFFBF1E8),
  );
  static const LeaguePalette iron = LeaguePalette(
    base: Color(0xFF5B6678),
    deep: Color(0xFF2F3A4A),
    tint: Color(0xFFEEF1F5),
  );

  /// The name uses a darker gray than [deep] for contrast on light surfaces.
  static const LeaguePalette silver = LeaguePalette(
    base: Color(0xFFC3CBD6),
    deep: Color(0xFF5E6B7D),
    tint: Color(0xFFF3F5F8),
    nameOverride: Color(0xFF3E4A5B),
  );
  static const LeaguePalette gold = LeaguePalette(
    base: Color(0xFFF2B52E),
    deep: Color(0xFF9A6400),
    tint: Color(0xFFFFF8E6),
  );
  static const LeaguePalette platinum = LeaguePalette(
    base: Color(0xFF9BE3DC),
    deep: Color(0xFF1F7F78),
    tint: Color(0xFFEAFAF8),
  );
  static const LeaguePalette diamond = LeaguePalette(
    base: Color(0xFF6CC2F7),
    deep: Color(0xFF1565A8),
    tint: Color(0xFFEAF6FF),
  );
  static const LeaguePalette emerald = LeaguePalette(
    base: Color(0xFF22B97D),
    deep: Color(0xFF0B6B47),
    tint: Color(0xFFE6F8F0),
  );
  static const LeaguePalette brilliant = LeaguePalette(
    base: Color(0xFFB65CF0),
    deep: Color(0xFF6E2AA8),
    tint: Color(0xFFF6ECFE),
  );
  static const LeaguePalette master = LeaguePalette(
    base: Color(0xFFE8B64A),
    deep: Color(0xFF241F4A),
    tint: Color(0xFFF1EFFA),
  );
  static const LeaguePalette grandmaster = LeaguePalette(
    base: Color(0xFFD3264B),
    deep: Color(0xFF8E0F2C),
    tint: Color(0xFFFDECEF),
  );

  /// The design has a gradient name; the solid fallback is used on purpose.
  static const LeaguePalette legend = LeaguePalette(
    base: Color(0xFFF7A21B),
    deep: Color(0xFF7A2E0E),
    tint: Color(0xFFFFF6E5),
    nameOverride: Color(0xFFB5560A),
  );

  static LeaguePalette of(League league) => switch (league) {
    League.bronze => bronze,
    League.iron => iron,
    League.silver => silver,
    League.gold => gold,
    League.platinum => platinum,
    League.diamond => diamond,
    League.emerald => emerald,
    League.brilliant => brilliant,
    League.master => master,
    League.grandmaster => grandmaster,
    League.legend => legend,
  };
}
