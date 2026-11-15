import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';

/// A 6 px track whose fill is the remaining fraction of a deadline's
/// [lifetime], corrected by the server [clockOffset]. Display only.
final class AppDeadlineTrack extends StatefulWidget {
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
    if (widget.isExpired || widget.lifetime <= Duration.zero) return 0;
    final Duration left = widget.expiresAt.difference(
      DateTime.now().add(widget.clockOffset),
    );
    return (left.inMilliseconds / widget.lifetime.inMilliseconds).clamp(
      0.0,
      1.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: SizedBox(
          height: 6,
          child: ColoredBox(
            color: widget.isExpired ? AppColors.divider : AppColors.primaryLine,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: _fraction,
                heightFactor: 1,
                child: const ColoredBox(color: AppColors.primary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
