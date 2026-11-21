import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A decorative 2 px circle on a blue panel that slowly "breathes"
/// (scale 1 to 1.04, alternating). The inner ring of a panel is out of
/// phase with the outer one ([isInner]). Hidden from assistive technology.
final class WelcomeRing extends StatelessComponent {
  const WelcomeRing({
    required this.size,
    required this.top,
    required this.right,
    required this.color,
    required this.periodSeconds,
    this.isInner = false,
    super.key,
  });

  final double size;
  final double top;
  final double right;
  final Color color;

  /// Duration of one half breath.
  final int periodSeconds;
  final bool isInner;

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'welcome-ring',
      styles: Styles(
        position: Position.absolute(top: Unit.pixels(top), right: Unit.pixels(right)),
        width: Unit.pixels(size),
        height: Unit.pixels(size),
        border: Border.all(color: color, width: const Unit.pixels(2)),
        raw: <String, String>{
          '--ring-period': '${periodSeconds}s',
          '--ring-offset': isInner ? '-${periodSeconds}s' : '0s',
        },
      ),
      attributes: const <String, String>{'aria-hidden': 'true'},
      const <Component>[],
    );
  }
}

@css
List<StyleRule> get welcomeRingStyles => <StyleRule>[
  css('.welcome-ring').styles(
    radius: const BorderRadius.circular(Unit.percent(50)),
    pointerEvents: PointerEvents.none,
    raw: const <String, String>{
      'animation': 'welcome-breathe var(--ring-period) ease-in-out var(--ring-offset) infinite alternate',
    },
  ),
  css.keyframes('welcome-breathe', <String, Styles>{
    'from': const Styles(transform: Transform.scale(1)),
    'to': const Styles(transform: Transform.scale(1.04)),
  }),
  css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), <StyleRule>[
    css('.welcome-ring').styles(raw: const <String, String>{'animation': 'none'}),
  ]),
];
