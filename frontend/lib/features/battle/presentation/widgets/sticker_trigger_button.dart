import 'dart:async';
import 'dart:math' as math;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';

/// The 40 px round button in the "you" block that opens the sticker picker
/// (Paper: "32 Battle stickers — Component sheet", states 1-5).
///
/// While [cooldownUntil] is in the future it shows a draining ring with the
/// seconds left; the ring drains with a CSS animation, so no state is
/// emitted per frame. A non-null [disabledMessage] disables the button and
/// is its tooltip.
final class StickerTriggerButton extends StatefulComponent {
  const StickerTriggerButton({
    required this.isOpen,
    required this.cooldownUntil,
    required this.cooldown,
    required this.onTap,
    this.disabledMessage,
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
  Component build(BuildContext context) {
    final String? disabledMessage = component.disabledMessage;
    final bool isDisabled = disabledMessage != null;
    final DateTime? until = component.cooldownUntil;
    final bool isCoolingDown = !isDisabled && until != null && until.isAfter(DateTime.now());
    final String message = disabledMessage ?? StickerTriggerButton.label;

    final Color iconColor;
    final Color fill;
    Border? border;
    if (isDisabled) {
      iconColor = AppColors.faint;
      fill = AppColors.surface;
    } else if (component.isOpen) {
      iconColor = AppColors.primary;
      fill = AppColors.primaryTint;
      border = Border.all(color: AppColors.primary, width: const Unit.pixels(1.5));
    } else if (isCoolingDown) {
      iconColor = AppColors.primary;
      fill = AppColors.white;
    } else if (_isHovered) {
      iconColor = AppColors.ink;
      fill = AppColors.surface;
      border = Border.all(color: AppColors.borderStrong, width: const Unit.pixels(1));
    } else {
      iconColor = AppColors.inkSoft;
      fill = AppColors.white;
      border = Border.all(color: AppColors.border, width: const Unit.pixels(1));
    }

    // The tooltip of the Flutter app is the native `title` hint.
    return span(
      classes: 'sticker-trigger',
      attributes: <String, String>{'title': message},
      events: <String, void Function(web.Event)>{
        'mouseenter': (web.Event _) => _setHovered(true),
        'mouseleave': (web.Event _) => _setHovered(false),
      },
      <Component>[
        AppTappable(
          onTap: isDisabled ? null : component.onTap,
          radius: 20,
          semanticLabel: message,
          isSelected: component.isOpen,
          classes: 'sticker-trigger__button',
          styles: Styles(border: border, backgroundColor: fill),
          child: isCoolingDown
              ? _CooldownRing(key: ValueKey<DateTime>(until), until: until, total: component.cooldown)
              : AppSvgIcon(AppIcons.sticker, width: 20, height: 20, color: iconColor),
        ),
      ],
    );
  }
}

/// Ring that drains clockwise over the remaining cooldown, with the whole
/// seconds left in the middle. The arc is a CSS animation (it never
/// rebuilds); the number is updated by a timer when it changes.
///
/// The ring is a clock, not decoration: reduced motion does not shorten it.
final class _CooldownRing extends StatefulComponent {
  const _CooldownRing({required this.until, required this.total, super.key});

  final DateTime until;
  final Duration total;

  static const double _stroke = 2.5;
  static const double _radius = 20 - _stroke / 2;
  static const double _circumference = 2 * math.pi * _radius;

  @override
  State<_CooldownRing> createState() => _CooldownRingState();
}

final class _CooldownRingState extends State<_CooldownRing> {
  late Timer _timer;
  late int _seconds;

  // Fixed for the life of this ring (it is keyed by `until`).
  late double _startFraction;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = component.until.difference(DateTime.now());
    _startFraction = _fractionOf(_remaining);
    _seconds = _secondsOf(_startFraction);
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  double _fractionOf(Duration remaining) =>
      (remaining.inMicroseconds / component.total.inMicroseconds).clamp(0, 1).toDouble();

  int _secondsOf(double fraction) => (fraction * component.total.inMilliseconds / 1000).ceil();

  void _tick() {
    final int next = _secondsOf(_fractionOf(component.until.difference(DateTime.now())));
    if (next != _seconds && mounted) setState(() => _seconds = next);
    if (next == 0) _timer.cancel();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    const double c = _CooldownRing._circumference;
    final int durationMs = _remaining.isNegative ? 0 : _remaining.inMilliseconds;
    return span(classes: 'sticker-trigger__ring', <Component>[
      svg(
        width: const Unit.pixels(40),
        height: const Unit.pixels(40),
        viewBox: '0 0 40 40',
        attributes: const <String, String>{'aria-hidden': 'true'},
        <Component>[
          circle(
            cx: '20',
            cy: '20',
            r: '${_CooldownRing._radius}',
            fill: Colors.transparent,
            stroke: AppColors.divider,
            strokeWidth: '${_CooldownRing._stroke}',
            const <Component>[],
          ),
          if (_startFraction > 0)
            // Starts at 12 o'clock and runs counter-clockwise (mirrored), so
            // the arc ends at 12 and its tail moves clockwise as it drains.
            circle(
              classes: 'sticker-trigger__arc',
              cx: '20',
              cy: '20',
              r: '${_CooldownRing._radius}',
              fill: Colors.transparent,
              stroke: AppColors.primary,
              strokeWidth: '${_CooldownRing._stroke}',
              styles: Styles(
                raw: <String, String>{
                  '--ring-from': '${c * (1 - _startFraction)}',
                  '--ring-to': '$c',
                  'stroke-dasharray': '$c $c',
                  'animation-duration': '${durationMs}ms',
                },
              ),
              attributes: const <String, String>{
                'transform': 'translate(40 0) scale(-1 1) rotate(-90 20 20)',
                'stroke-linecap': 'round',
              },
              const <Component>[],
            ),
        ],
      ),
      span(classes: 'sticker-trigger__seconds', <Component>[Component.text('$_seconds')]),
    ]);
  }
}

@css
List<StyleRule> get stickerTriggerButtonStyles => <StyleRule>[
  css('.sticker-trigger').styles(display: Display.inlineFlex, flex: const Flex(shrink: 0)),
  css('.sticker-trigger__button').styles(
    display: Display.flex,
    width: const Unit.pixels(40),
    height: const Unit.pixels(40),
    boxSizing: BoxSizing.borderBox,
    radius: const BorderRadius.circular(Unit.percent(50)),
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
  ),
  css('.sticker-trigger__ring').styles(
    display: Display.flex,
    position: const Position.relative(),
    width: const Unit.pixels(40),
    height: const Unit.pixels(40),
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
  ),
  css('.sticker-trigger__ring svg').styles(
    position: const Position.absolute(top: Unit.zero, left: Unit.zero),
  ),
  css('.sticker-trigger__arc').styles(
    raw: const <String, String>{
      'animation-name': 'sticker-ring-drain',
      'animation-timing-function': 'linear',
      'animation-fill-mode': 'both',
    },
  ),
  css.keyframes('sticker-ring-drain', <String, Styles>{
    'from': const Styles(raw: <String, String>{'stroke-dashoffset': 'var(--ring-from)'}),
    'to': const Styles(raw: <String, String>{'stroke-dashoffset': 'var(--ring-to)'}),
  }),
  css('.sticker-trigger__seconds')
      .styles(position: const Position.relative())
      .combine(AppTextStyles.monoBodySm)
      .combine(const Styles(color: AppColors.primary, fontWeight: FontWeight.w600)),
];
