import 'dart:async';

import 'package:material_ui/material_ui.dart';

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
final class AppCountdownText extends StatefulWidget {
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
  final TextStyle? style;
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
    final Duration left = widget.target.difference(
      DateTime.now().add(widget.clockOffset),
    );
    return left.isNegative ? Duration.zero : left;
  }

  void _tick() {
    final Duration next = _compute();
    if (next.inSeconds == _remaining.inSeconds &&
        (next == Duration.zero) == (_remaining == Duration.zero)) {
      return;
    }
    setState(() => _remaining = next);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String value = switch (widget.format) {
      AppCountdownFormat.clock => DisplayFormatters.clock(_remaining),
      AppCountdownFormat.compact => DisplayFormatters.compactDuration(
        _remaining,
      ),
      AppCountdownFormat.hms => DisplayFormatters.hms(_remaining),
      AppCountdownFormat.seconds =>
        '${(_remaining.inMilliseconds / 1000).ceil()}',
    };
    return Text('${widget.prefix}$value${widget.suffix}', style: widget.style);
  }
}
