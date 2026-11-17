import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';

/// The 6 px strip under the battle header, drawn from a server instant.
/// Display only: it never closes a round.
///
/// - Question: the time left of the round, blue (amber in overtime), red in
///   the last fifth.
/// - Reveal: grey, draining until the next round (Paper: "Next in 4").
final class BattleTimeBar extends StatefulComponent {
  const BattleTimeBar({
    required this.endsAt,
    required this.clockOffset,
    required this.color,
    this.totalSeconds,
    this.lowColor,
    super.key,
  });

  /// `null` renders a full bar.
  final DateTime? endsAt;

  /// Full length of the bar; when `null`, the time left at the first build.
  final int? totalSeconds;
  final Duration clockOffset;
  final Color color;

  /// Color for the last fifth of the time, if any.
  final Color? lowColor;

  @override
  State<BattleTimeBar> createState() => _BattleTimeBarState();
}

final class _BattleTimeBarState extends State<BattleTimeBar> {
  Timer? _timer;
  late int _totalMs;
  late double _fraction;

  @override
  void initState() {
    super.initState();
    final int? seconds = component.totalSeconds;
    _totalMs = seconds != null ? seconds * 1000 : _leftMs();
    _fraction = _compute();
    if (component.endsAt != null) {
      _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        final double next = _compute();
        if ((next - _fraction).abs() > 0.002 && mounted) setState(() => _fraction = next);
      });
    }
  }

  int _leftMs() {
    final DateTime? endsAt = component.endsAt;
    if (endsAt == null) return 0;
    return endsAt.difference(DateTime.now().add(component.clockOffset)).inMilliseconds;
  }

  double _compute() {
    if (component.endsAt == null) return 1;
    if (_totalMs <= 0) return 0;
    return (_leftMs() / _totalMs).clamp(0, 1).toDouble();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final Color? low = component.lowColor;
    final Color color = low != null && _fraction < 0.2 ? low : component.color;
    return div(
      classes: 'battle-time-bar',
      attributes: const <String, String>{'aria-hidden': 'true'},
      <Component>[
        div(
          classes: 'battle-time-bar__fill',
          styles: Styles(width: Unit.percent(_fraction * 100), backgroundColor: color),
          const <Component>[],
        ),
      ],
    );
  }
}

@css
List<StyleRule> get battleTimeBarStyles => <StyleRule>[
  css('.battle-time-bar').styles(
    width: const Unit.percent(100),
    height: const Unit.pixels(6),
    flex: const Flex(shrink: 0),
    backgroundColor: AppColors.surface,
  ),
  css('.battle-time-bar__fill').styles(height: const Unit.percent(100)),
];
