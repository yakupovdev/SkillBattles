import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/core/presentation/league/league_rank.dart';
import 'package:skill_battles/core/presentation/skeleton/skeletonizer.dart';

/// The emblem of a league and division (`assets/leagues/`).
///
/// [locked] shows it in grayscale at 35% opacity, [dimmed] at 70% (the "Next"
/// preview). While a `Skeletonizer` is enabled it is one bone of its size and
/// the file is not loaded. The emblem is hidden from screen readers unless a
/// [semanticLabel] is given, because the rank name is shown next to it.
final class LeagueEmblem extends StatelessComponent {
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

  @override
  Component build(BuildContext context) {
    final Styles box = Styles(width: Unit.pixels(size), height: Unit.pixels(size));
    if (Skeletonizer.isEnabled(context)) {
      return Skeleton.leaf(
        child: span(classes: 'league-emblem', styles: box, const <Component>[]),
      );
    }
    final double? opacity = locked
        ? 0.35
        : dimmed
        ? 0.7
        : null;
    final String? label = semanticLabel;
    return img(
      src: rank.asset,
      alt: label ?? '',
      width: size.round(),
      height: size.round(),
      classes: opacity == null ? 'league-emblem' : 'league-emblem league-emblem--muted',
      styles: opacity == null ? box : box.combine(Styles(opacity: opacity)),
      attributes: label == null ? const <String, String>{'aria-hidden': 'true'} : null,
    );
  }
}

@css
List<StyleRule> get leagueEmblemStyles => <StyleRule>[
  css('.league-emblem').styles(display: Display.block, flex: const Flex(shrink: 0)),
  css('.league-emblem--muted').styles(filter: const Filter.grayscale(1)),
];
