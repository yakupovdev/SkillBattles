import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Three small pips; the first [division] are filled with [color].
///
/// Hidden for a single-division league ([division] is `null`).
final class DivisionPips extends StatelessComponent {
  const DivisionPips({
    required this.division,
    required this.color,
    required this.emptyColor,
    super.key,
  });

  final int? division;
  final Color color;
  final Color emptyColor;

  @override
  Component build(BuildContext context) {
    final int? filled = division;
    if (filled == null) return const Component.empty();
    return div(
      classes: 'division-pips',
      attributes: const <String, String>{'aria-hidden': 'true'},
      <Component>[
        for (int i = 1; i <= 3; i++)
          span(
            classes: 'division-pips__pip',
            styles: Styles(backgroundColor: i <= filled ? color : emptyColor),
            const <Component>[],
          ),
      ],
    );
  }
}

@css
List<StyleRule> get divisionPipsStyles => <StyleRule>[
  css('.division-pips').styles(
    display: Display.inlineFlex,
    gap: const Gap.column(Unit.pixels(4)),
    flex: const Flex(shrink: 0),
  ),
  css('.division-pips__pip').styles(
    display: Display.block,
    width: const Unit.pixels(16),
    height: const Unit.pixels(4),
    radius: const BorderRadius.circular(Unit.pixels(2)),
  ),
];
