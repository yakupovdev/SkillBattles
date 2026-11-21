import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/core/presentation/utils/reduced_motion.dart';
import 'package:skill_battles/core/presentation/utils/visibility_gate.dart';

/// Fades and lifts its [child] in once, when [threshold] of it first enters
/// the viewport. Siblings can be staggered with [delayMs].
///
/// The hidden-before-reveal look is only applied while the observer is
/// attached in the browser: on the server, without JS, without
/// `IntersectionObserver` and under `prefers-reduced-motion` the content is
/// simply visible. Descendants can react to the reveal with the
/// `.app-reveal--in` (revealed) and `.app-reveal--armed` (waiting) classes.
final class AppReveal extends StatefulComponent {
  const AppReveal({
    required this.child,
    this.tag = 'div',
    this.classes,
    this.styles,
    this.attributes,
    this.delayMs = 0,
    this.threshold = 0.15,
    this.fades = true,
    super.key,
  });

  final Component child;

  /// HTML tag of the wrapper (`li`, `section`, ...).
  final String tag;
  final String? classes;
  final Styles? styles;
  final Map<String, String>? attributes;

  /// Delay of the transition, for staggering siblings.
  final int delayMs;

  /// Share of the element that must be visible to reveal it.
  final double threshold;

  /// Whether the wrapper itself fades up. Set `false` to only toggle the
  /// state classes and animate descendants from CSS.
  final bool fades;

  @override
  State<AppReveal> createState() => _AppRevealState();
}

final class _AppRevealState extends State<AppReveal> {
  late GlobalNodeKey<web.HTMLElement> _elementKey;
  late bool _isArmed;
  late bool _isRevealed;
  VisibilityGate? _gate;

  @override
  void initState() {
    super.initState();
    _elementKey = GlobalNodeKey<web.HTMLElement>();
    _isRevealed = false;
    _isArmed = kIsWeb && !prefersReducedMotion();
    if (_isArmed) context.binding.addPostFrameCallback(_attach);
  }

  void _attach() {
    if (!mounted) return;
    final web.HTMLElement? element = _elementKey.currentNode;
    if (element == null) {
      setState(() => _isArmed = false);
      return;
    }
    final VisibilityGate gate = VisibilityGate(
      threshold: component.threshold,
      onChanged: (bool isActive) {
        if (isActive) _reveal();
      },
    );
    _gate = gate;
    if (!gate.attach(element)) {
      gate.dispose();
      _gate = null;
      setState(() => _isArmed = false);
    }
  }

  void _reveal() {
    _gate?.dispose();
    _gate = null;
    if (mounted && !_isRevealed) setState(() => _isRevealed = true);
  }

  @override
  void dispose() {
    _gate?.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final String state = _isRevealed
        ? ' app-reveal--armed app-reveal--in'
        : _isArmed
        ? ' app-reveal--armed'
        : '';
    final String? extra = component.classes;
    return Component.element(
      tag: component.tag,
      key: _elementKey,
      classes: 'app-reveal${component.fades ? ' app-reveal--fade' : ''}$state${extra == null ? '' : ' $extra'}',
      styles: Styles.combine(<Styles>[
        Styles(raw: <String, String>{'--reveal-delay': '${component.delayMs}ms'}),
        ?component.styles,
      ]),
      attributes: component.attributes,
      children: <Component>[component.child],
    );
  }
}

@css
List<StyleRule> get appRevealStyles => <StyleRule>[
  css('.app-reveal--fade.app-reveal--armed').styles(
    opacity: 0,
    transform: const Transform.translate(y: Unit.pixels(24)),
  ),
  css('.app-reveal--fade.app-reveal--armed.app-reveal--in').styles(
    opacity: 1,
    transform: Transform.none,
    raw: const <String, String>{
      'transition':
          'opacity 600ms cubic-bezier(0.2, 0.7, 0.2, 1) var(--reveal-delay, 0ms), '
          'transform 600ms cubic-bezier(0.2, 0.7, 0.2, 1) var(--reveal-delay, 0ms)',
    },
  ),
  css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), <StyleRule>[
    css('.app-reveal--fade.app-reveal--armed').styles(
      opacity: 1,
      transform: Transform.none,
      raw: const <String, String>{'transition': 'none'},
    ),
  ]),
];
