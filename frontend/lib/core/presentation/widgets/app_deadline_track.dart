import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';

/// A 6 px track whose fill is the remaining fraction of a deadline's
/// [lifetime], corrected by the server [clockOffset]. Display only.
final class AppDeadlineTrack extends StatefulComponent {
  const AppDeadlineTrack({
    required this.expiresAt,
    required this.lifetime,
    this.clockOffset = Duration.zero,
    this.isExpired = false,
    super.key,
  });

  final DateTime expiresAt;
  final Duration lifetime;

  /// Server time minus local time.
  final Duration clockOffset;
  final bool isExpired;

  @override
  State<AppDeadlineTrack> createState() => _AppDeadlineTrackState();
}

final class _AppDeadlineTrackState extends State<AppDeadlineTrack> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  double get _fraction {
    if (component.isExpired || component.lifetime <= Duration.zero) return 0;
    final Duration left = component.expiresAt.difference(DateTime.now().add(component.clockOffset));
    return (left.inMilliseconds / component.lifetime.inMilliseconds).clamp(0.0, 1.0);
  }

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'app-deadline-track',
      styles: Styles(backgroundColor: component.isExpired ? AppColors.divider : AppColors.primaryLine),
      attributes: const <String, String>{'aria-hidden': 'true'},
      <Component>[
        div(
          classes: 'app-deadline-track__fill',
          styles: Styles(width: Unit.percent(_fraction * 100)),
          const <Component>[],
        ),
      ],
    );
  }
}

@css
List<StyleRule> get appDeadlineTrackStyles => <StyleRule>[
  css('.app-deadline-track').styles(
    height: const Unit.pixels(6),
    radius: const BorderRadius.circular(Unit.pixels(3)),
    overflow: Overflow.hidden,
  ),
  css('.app-deadline-track__fill').styles(
    height: const Unit.percent(100),
    transition: const Transition('width', duration: Duration(milliseconds: 500), curve: Curve.linear),
    backgroundColor: AppColors.primary,
  ),
];
