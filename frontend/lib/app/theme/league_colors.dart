import 'package:jaspr/dom.dart';

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
    base: Color('#C07A45'),
    deep: Color('#7A4520'),
    tint: Color('#FBF1E8'),
  );
  static const LeaguePalette iron = LeaguePalette(
    base: Color('#5B6678'),
    deep: Color('#2F3A4A'),
    tint: Color('#EEF1F5'),
  );

  /// The name uses a darker gray than [deep] for contrast on light surfaces.
  static const LeaguePalette silver = LeaguePalette(
    base: Color('#C3CBD6'),
    deep: Color('#5E6B7D'),
    tint: Color('#F3F5F8'),
    nameOverride: Color('#3E4A5B'),
  );
  static const LeaguePalette gold = LeaguePalette(
    base: Color('#F2B52E'),
    deep: Color('#9A6400'),
    tint: Color('#FFF8E6'),
  );
  static const LeaguePalette platinum = LeaguePalette(
    base: Color('#9BE3DC'),
    deep: Color('#1F7F78'),
    tint: Color('#EAFAF8'),
  );
  static const LeaguePalette diamond = LeaguePalette(
    base: Color('#6CC2F7'),
    deep: Color('#1565A8'),
    tint: Color('#EAF6FF'),
  );
  static const LeaguePalette emerald = LeaguePalette(
    base: Color('#22B97D'),
    deep: Color('#0B6B47'),
    tint: Color('#E6F8F0'),
  );
  static const LeaguePalette brilliant = LeaguePalette(
    base: Color('#B65CF0'),
    deep: Color('#6E2AA8'),
    tint: Color('#F6ECFE'),
  );
  static const LeaguePalette master = LeaguePalette(
    base: Color('#E8B64A'),
    deep: Color('#241F4A'),
    tint: Color('#F1EFFA'),
  );
  static const LeaguePalette grandmaster = LeaguePalette(
    base: Color('#D3264B'),
    deep: Color('#8E0F2C'),
    tint: Color('#FDECEF'),
  );

  /// The design has a gradient name; the solid fallback is used on purpose.
  static const LeaguePalette legend = LeaguePalette(
    base: Color('#F7A21B'),
    deep: Color('#7A2E0E'),
    tint: Color('#FFF6E5'),
    nameOverride: Color('#B5560A'),
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
