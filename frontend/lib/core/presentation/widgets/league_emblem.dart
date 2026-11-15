import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/core/presentation/league/league_rank.dart';

/// The emblem of a league and division (`assets/leagues/`).
///
/// [locked] shows it in grayscale at 35% opacity, [dimmed] at 70% (the "Next"
/// preview). While a `Skeletonizer` is enabled it is one bone of its size and
/// the file is not loaded. The emblem is hidden from screen readers unless a
/// [semanticLabel] is given, because the rank name is shown next to it.
final class LeagueEmblem extends StatelessWidget {
  const LeagueEmblem({
    required this.rank,
    required this.size,
    this.locked = false,
    this.dimmed = false,
    this.semanticLabel,
    super.key,
  });

  final LeagueRank rank;
  final double size;
  final bool locked;
  final bool dimmed;
  final String? semanticLabel;

  static const ColorFilter _grayscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    if (Skeletonizer.maybeOf(context)?.enabled ?? false) {
      return Skeleton.leaf(child: SizedBox.square(dimension: size));
    }
    Widget emblem = SvgPicture.asset(
      rank.asset,
      width: size,
      height: size,
      excludeFromSemantics: true,
    );
    final double? opacity = locked
        ? 0.35
        : dimmed
        ? 0.7
        : null;
    if (opacity != null) {
      emblem = Opacity(
        opacity: opacity,
        child: ColorFiltered(colorFilter: _grayscale, child: emblem),
      );
    }
    final String? label = semanticLabel;
    return label == null
        ? ExcludeSemantics(child: emblem)
        : Semantics(label: label, image: true, child: emblem);
  }
}
