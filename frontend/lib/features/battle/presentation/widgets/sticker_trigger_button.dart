import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';

/// The 40 px round button in the "you" block that opens the sticker picker
/// (Paper: "32 Battle stickers — Component sheet", states 1-5).
///
/// While [cooldownUntil] is in the future it shows a draining ring with the
/// seconds left; the ring ticks itself, so no state is emitted per frame.
/// A non-null [disabledMessage] disables the button and is its tooltip.
final class StickerTriggerButton extends StatefulWidget {
  const StickerTriggerButton({
    required this.isOpen,
    required this.cooldownUntil,
    required this.cooldown,
    required this.onTap,
    this.disabledMessage,
    this.focusNode,
    super.key,
  });

  static const String label = 'Send a sticker';

  final bool isOpen;

  /// Local instant the next send is allowed; `null` or past: no cooldown.
  final DateTime? cooldownUntil;

  /// Full length of a cooldown, for the ring fraction.
  final Duration cooldown;
  final VoidCallback onTap;
  final String? disabledMessage;
  final FocusNode? focusNode;

  @override
  State<StickerTriggerButton> createState() => _StickerTriggerButtonState();
}

final class _StickerTriggerButtonState extends State<StickerTriggerButton> {
  late bool _isHovered;

  @override
  void initState() {
    super.initState();
    _isHovered = false;
  }

  void _setHovered(bool value) {
    if (value == _isHovered) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final String? disabledMessage = widget.disabledMessage;
    final bool isDisabled = disabledMessage != null;
    final DateTime? until = widget.cooldownUntil;
    final bool isCoolingDown =
        !isDisabled && until != null && until.isAfter(DateTime.now());
    final String message = disabledMessage ?? StickerTriggerButton.label;

    final Color iconColor;
    final Color fill;
    Border? border;
    if (isDisabled) {
      iconColor = AppColors.faint;
      fill = AppColors.surface;
    } else if (widget.isOpen) {
      iconColor = AppColors.primary;
      fill = AppColors.primaryTint;
      border = Border.all(color: AppColors.primary, width: 1.5);
    } else if (isCoolingDown) {
      iconColor = AppColors.primary;
      fill = AppColors.white;
    } else if (_isHovered) {
      iconColor = AppColors.ink;
      fill = AppColors.surface;
      border = Border.all(color: AppColors.borderStrong);
    } else {
      iconColor = AppColors.inkSoft;
      fill = AppColors.white;
      border = Border.all(color: AppColors.border);
    }

    return Tooltip(
      message: message,
      child: MouseRegion(
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: AppTappable(
          key: const ValueKey<String>('sticker-trigger'),
          focusNode: widget.focusNode,
          onTap: isDisabled ? null : widget.onTap,
          borderRadius: BorderRadius.circular(20),
          semanticLabel: message,
          isSelected: widget.isOpen,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: border,
            ),
            child: SizedBox.square(
              dimension: 40,
              child: isCoolingDown
                  ? RepaintBoundary(
                      // Repaints every frame for 4 s; keep it off the header.
                      child: _CooldownRing(
                        until: until,
                        total: widget.cooldown,
                      ),
                    )
                  : Center(
                      child: AppSvgIcon(
                        AppIcons.sticker,
                        width: 20,
                        height: 20,
                        color: iconColor,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ring that drains clockwise over the remaining cooldown, with the whole
/// seconds left in the middle. Drives itself with one controller.
final class _CooldownRing extends StatefulWidget {
  const _CooldownRing({required this.until, required this.total});

  final DateTime until;
  final Duration total;

  @override
  State<_CooldownRing> createState() => _CooldownRingState();
}

final class _CooldownRingState extends State<_CooldownRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // The ring is a clock, not decoration: reduced motion must not shorten
    // it (the default behaviour scales durations down to almost zero).
    _controller = AnimationController(
      vsync: this,
      animationBehavior: AnimationBehavior.preserve,
    );
    _start();
  }

  void _start() {
    final Duration remaining = widget.until.difference(DateTime.now());
    final double fraction =
        (remaining.inMicroseconds / widget.total.inMicroseconds).clamp(0, 1);
    _controller.value = fraction;
    if (remaining > Duration.zero) {
      _controller.animateTo(0, duration: remaining, curve: Curves.linear);
    }
  }

  @override
  void didUpdateWidget(_CooldownRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.until != widget.until) {
      _controller.stop();
      _start();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTextStyles.monoBodySm.copyWith(
      fontWeight: FontWeight.w600,
      color: AppColors.primary,
    );
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? _) {
        final double fraction = _controller.value;
        final int seconds = (fraction * widget.total.inMilliseconds / 1000)
            .ceil();
        return CustomPaint(
          painter: _RingPainter(fraction: fraction),
          child: Center(child: Text('$seconds', style: style)),
        );
      },
    );
  }
}

final class _RingPainter extends CustomPainter {
  const _RingPainter({required this.fraction});

  final double fraction;

  static const double _stroke = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.width / 2 - _stroke / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..color = AppColors.divider,
    );
    if (fraction <= 0) return;
    // The arc ends at 12 o'clock and its tail moves clockwise as it drains.
    final double sweep = 2 * math.pi * fraction;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 - sweep,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..color = AppColors.primary,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      fraction != oldDelegate.fraction;
}
