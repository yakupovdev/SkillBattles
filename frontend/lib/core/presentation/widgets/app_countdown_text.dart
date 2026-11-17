import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';

/// How an [AppCountdownText] writes the remaining time.
enum AppCountdownFormat {
  /// `1:05`.
  clock,

  /// `5h 12m`.
  compact,

  /// `06:42:18`.
  hms,

  /// `4` — whole seconds left.
  seconds,
}

/// Remaining time until a server instant, corrected by the server clock
/// offset. Display only: reaching zero never changes any state.
final class AppCountdownText extends StatefulComponent {
  const AppCountdownText({
    required this.target,
    this.clockOffset = Duration.zero,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.format = AppCountdownFormat.clock,
    super.key,
  });

  final DateTime target;

  /// Server time minus local time.
  final Duration clockOffset;
  final Styles? style;
  final String prefix;
  final String suffix;
  final AppCountdownFormat format;

  @override
  State<AppCountdownText> createState() => _AppCountdownTextState();
}

final class _AppCountdownTextState extends State<AppCountdownText> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _compute();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  Duration _compute() {
    final Duration left = component.target.difference(DateTime.now().add(component.clockOffset));
    return left.isNegative ? Duration.zero : left;
  }

  @override
  void didUpdateComponent(AppCountdownText oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.target != component.target || oldComponent.clockOffset != component.clockOffset) {
      _remaining = _compute();
    }
  }

  void _tick() {
    final Duration next = _compute();
    if (next.inSeconds == _remaining.inSeconds && (next == Duration.zero) == (_remaining == Duration.zero)) {
      return;
    }
    if (mounted) setState(() => _remaining = next);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final String value = switch (component.format) {
      AppCountdownFormat.clock => DisplayFormatters.clock(_remaining),
      AppCountdownFormat.compact => DisplayFormatters.compactDuration(_remaining),
      AppCountdownFormat.hms => DisplayFormatters.hms(_remaining),
      AppCountdownFormat.seconds => '${(_remaining.inMilliseconds / 1000).ceil()}',
    };
    return span(
      classes: 'app-countdown-text',
      styles: component.style,
      <Component>[Component.text('${component.prefix}$value${component.suffix}')],
    );
  }
}

@css
List<StyleRule> get appCountdownTextStyles => <StyleRule>[
  css('.app-countdown-text').styles(raw: const <String, String>{'font-variant-numeric': 'tabular-nums'}),
];
