import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/js_interop.dart';
import 'package:universal_web/web.dart' as web;

/// Shows [child] at its natural size and scales it down, keeping the aspect
/// ratio, when it is wider than the available width (a display formula
/// wider than the text column).
///
/// The child sits in an inline-block measured with a `ResizeObserver`; the
/// scale is a CSS transform and the box takes the scaled height, so the text
/// after it moves up with it. Nothing scrolls and nothing is cut.
final class MathFitWidth extends StatefulComponent {
  const MathFitWidth({required this.child, super.key});

  final Component child;

  @override
  State<MathFitWidth> createState() => _MathFitWidthState();
}

final class _MathFitWidthState extends State<MathFitWidth> {
  late GlobalNodeKey<web.HTMLElement> _boxKey;
  late GlobalNodeKey<web.HTMLElement> _contentKey;
  late double _scale;
  late double? _height;
  web.ResizeObserver? _observer;

  @override
  void initState() {
    super.initState();
    _boxKey = GlobalNodeKey<web.HTMLElement>();
    _contentKey = GlobalNodeKey<web.HTMLElement>();
    _scale = 1;
    _height = null;
    if (kIsWeb) context.binding.addPostFrameCallback(_observe);
  }

  @override
  void dispose() {
    _observer?.disconnect();
    super.dispose();
  }

  void _observe() {
    final web.HTMLElement? box = _boxKey.currentNode;
    final web.HTMLElement? content = _contentKey.currentNode;
    if (!mounted || box == null || content == null) return;
    final web.ResizeObserver observer = web.ResizeObserver(
      ((JSArray<web.ResizeObserverEntry> entries, web.ResizeObserver observer) => _measure()).toJS,
    );
    observer
      ..observe(box)
      ..observe(content);
    _observer = observer;
    _measure();
  }

  void _measure() {
    final web.HTMLElement? box = _boxKey.currentNode;
    final web.HTMLElement? content = _contentKey.currentNode;
    if (!mounted || box == null || content == null) return;
    // Layout sizes ignore the transform: this is the natural size.
    final double natural = content.offsetWidth.toDouble();
    final double available = box.clientWidth.toDouble();
    final double scale = natural > available && natural > 0 && available > 0 ? available / natural : 1;
    final double? height = scale < 1 ? content.offsetHeight * scale : null;
    if ((scale - _scale).abs() < 0.001 && height == _height) return;
    setState(() {
      _scale = scale;
      _height = height;
    });
  }

  @override
  Component build(BuildContext context) {
    final double? height = _height;
    return div(
      key: _boxKey,
      classes: 'math-fit-width',
      styles: height == null ? null : Styles(height: Unit.pixels(height)),
      <Component>[
        span(
          key: _contentKey,
          classes: 'math-fit-width__content',
          styles: _scale == 1 ? null : Styles(transform: Transform.scale(_scale)),
          <Component>[component.child],
        ),
      ],
    );
  }
}

@css
List<StyleRule> get mathFitWidthStyles => <StyleRule>[
  css('.math-fit-width').styles(maxWidth: const Unit.percent(100), overflow: Overflow.hidden),
  css('.math-fit-width__content').styles(
    display: Display.inlineBlock,
    whiteSpace: WhiteSpace.noWrap,
    raw: const <String, String>{'transform-origin': '0 0'},
  ),
];
