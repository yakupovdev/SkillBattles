import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/js_interop.dart';
import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/core/presentation/utils/reduced_motion.dart';
import 'package:skill_battles/core/presentation/utils/visibility_gate.dart';

/// A whole number that counts from [from] to [to] with an ease-out curve
/// (tabular digits, so the layout never shifts).
///
/// With [play] `null` it starts by itself, once, when it first scrolls into
/// view (after [delayMs]). With a [play] flag it is controlled: `true`
/// counts to [to], `false` shows [from] at once. Under reduced motion, and
/// on the server, it shows [to] immediately (or [from] while [play] is
/// `false`).
final class AppCountUp extends StatefulComponent {
  const AppCountUp({
    required this.from,
    required this.to,
    this.durationMs = 600,
    this.delayMs = 0,
    this.play,
    this.format = _plain,
    super.key,
  });

  final int from;
  final int to;
  final int durationMs;
  final int delayMs;
  final bool? play;

  /// Text of a value ("+18", "1,000").
  final String Function(int value) format;

  static String _plain(int value) => '$value';

  @override
  State<AppCountUp> createState() => _AppCountUpState();
}

final class _AppCountUpState extends State<AppCountUp> {
  late GlobalNodeKey<web.HTMLElement> _elementKey;
  late int _value;
  late bool _isAnimated;
  VisibilityGate? _gate;
  Timer? _delayTimer;
  int? _frameId;
  late JSFunction _onFrame;
  late double _startTime;

  @override
  void initState() {
    super.initState();
    _elementKey = GlobalNodeKey<web.HTMLElement>();
    _isAnimated = kIsWeb && !prefersReducedMotion();
    _startTime = 0;
    _onFrame = _frame.toJS;
    final bool? play = component.play;
    _value = _isAnimated && play != true ? component.from : component.to;
    if (!_isAnimated) {
      _value = play == false ? component.from : component.to;
      return;
    }
    if (play == null) context.binding.addPostFrameCallback(_watch);
  }

  @override
  void didUpdateComponent(AppCountUp oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (component.play == null || oldComponent.play == component.play) return;
    if (!_isAnimated) {
      setState(() => _value = component.play! ? component.to : component.from);
      return;
    }
    _cancel();
    if (component.play!) {
      _begin();
    } else {
      setState(() => _value = component.from);
    }
  }

  void _watch() {
    if (!mounted) return;
    final web.HTMLElement? element = _elementKey.currentNode;
    // Nothing to observe: show the final value rather than stay at `from`.
    if (element == null) {
      setState(() => _value = component.to);
      return;
    }
    final VisibilityGate gate = VisibilityGate(
      threshold: 0.15,
      onChanged: (bool isActive) {
        if (!isActive) return;
        _gate?.dispose();
        _gate = null;
        _begin();
      },
    );
    _gate = gate;
    if (!gate.attach(element)) {
      gate.dispose();
      _gate = null;
      setState(() => _value = component.to);
    }
  }

  void _begin() {
    _delayTimer = Timer(Duration(milliseconds: component.delayMs), () {
      if (!mounted) return;
      _startTime = 0;
      _frameId = web.window.requestAnimationFrame(_onFrame);
    });
  }

  void _frame(double now) {
    if (!mounted) return;
    if (_startTime == 0) _startTime = now;
    final double t = ((now - _startTime) / component.durationMs).clamp(0, 1).toDouble();
    final double eased = 1 - (1 - t) * (1 - t) * (1 - t);
    final int next = (component.from + (component.to - component.from) * eased).round();
    if (next != _value) setState(() => _value = next);
    _frameId = t < 1 ? web.window.requestAnimationFrame(_onFrame) : null;
  }

  void _cancel() {
    _delayTimer?.cancel();
    _delayTimer = null;
    final int? id = _frameId;
    if (id != null) web.window.cancelAnimationFrame(id);
    _frameId = null;
  }

  @override
  void dispose() {
    _gate?.dispose();
    _cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return span(
      key: _elementKey,
      classes: 'app-count-up',
      <Component>[Component.text(component.format(_value))],
    );
  }
}

@css
List<StyleRule> get appCountUpStyles => <StyleRule>[
  css('.app-count-up').styles(raw: const <String, String>{'font-variant-numeric': 'tabular-nums'}),
];
