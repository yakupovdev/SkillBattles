import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/utils/reduced_motion.dart';
import 'package:skill_battles/core/presentation/utils/visibility_gate.dart';
import 'package:skill_battles/core/presentation/widgets/app_avatar.dart';

/// Picture of a private room waiting for a friend. The six code tiles
/// appear one by one as if typed, the countdown ticks while the card is on
/// screen and the "Waiting" dots pulse. Fixed sample data.
final class RoomCodeFragment extends StatelessComponent {
  const RoomCodeFragment({super.key});

  static const List<String> _code = <String>['K', '7', 'Q', '2', 'M', '8'];

  @override
  Component build(BuildContext context) {
    return div(classes: 'room-fragment', <Component>[
      div(classes: 'room-fragment__head', const <Component>[
        span(classes: 'room-fragment__label', <Component>[Component.text('ROOM CODE')]),
        span(classes: 'room-fragment__note', <Component>[Component.text('Unranked · no rating change')]),
      ]),
      div(classes: 'room-fragment__code', <Component>[
        for (int i = 0; i < _code.length; i++)
          span(
            classes: 'room-fragment__tile',
            styles: Styles(raw: <String, String>{'--tile': '$i'}),
            <Component>[Component.text(_code[i])],
          ),
      ]),
      div(classes: 'room-fragment__wait', const <Component>[
        div(classes: 'room-fragment__guest', <Component>[
          AppAvatar(nickname: 'timur.b', size: AppAvatarSize.row, tone: AppAvatarTone.accent),
          span(classes: 'room-fragment__waiting', <Component>[
            Component.text('Waiting for timur.b'),
            span(classes: 'room-fragment__dots', <Component>[Component.text('…')]),
          ]),
        ]),
        RoomCountdown(),
      ]),
    ]);
  }
}

/// `0:48` ticking down once a second while on screen in a visible tab;
/// after `0:00` it wraps back to `0:59`. Static under reduced motion.
final class RoomCountdown extends StatefulComponent {
  const RoomCountdown({super.key});

  @override
  State<RoomCountdown> createState() => _RoomCountdownState();
}

final class _RoomCountdownState extends State<RoomCountdown> {
  late GlobalNodeKey<web.HTMLElement> _elementKey;
  late int _seconds;
  VisibilityGate? _gate;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _elementKey = GlobalNodeKey<web.HTMLElement>();
    _seconds = 48;
    if (kIsWeb && !prefersReducedMotion()) context.binding.addPostFrameCallback(_watch);
  }

  void _watch() {
    final web.HTMLElement? element = _elementKey.currentNode;
    if (!mounted || element == null) return;
    final VisibilityGate gate = VisibilityGate(threshold: 0.15, onChanged: _onActiveChanged);
    _gate = gate;
    if (!gate.attach(element)) {
      gate.dispose();
      _gate = null;
    }
  }

  void _onActiveChanged(bool isActive) {
    _timer?.cancel();
    _timer = null;
    if (!isActive || !mounted) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (mounted) setState(() => _seconds = _seconds == 0 ? 59 : _seconds - 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gate?.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return span(
      key: _elementKey,
      classes: 'room-fragment__countdown',
      <Component>[Component.text('0:${_seconds.toString().padLeft(2, '0')}')],
    );
  }
}

@css
List<StyleRule> get roomCodeFragmentStyles => <StyleRule>[
  css('.room-fragment').styles(
    display: Display.flex,
    padding: const Padding.all(Unit.pixels(20)),
    radius: const BorderRadius.circular(Unit.pixels(12)),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(14)),
    backgroundColor: AppColors.surface,
  ),
  css('.room-fragment__head').styles(
    display: Display.flex,
    justifyContent: JustifyContent.spaceBetween,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(8)),
  ),
  css('.room-fragment__label')
      .combine(AppTextStyles.monoCaption)
      .combine(const Styles(color: AppColors.muted, letterSpacing: Unit.em(0.08), whiteSpace: WhiteSpace.noWrap)),
  css('.room-fragment__note').combine(AppTextStyles.bodyXs).combine(const Styles(color: AppColors.muted)),
  css('.room-fragment__code').styles(display: Display.flex, gap: const Gap.column(Unit.pixels(8))),
  css('.room-fragment__tile')
      .combine(AppTextStyles.monoSm)
      .combine(
        const Styles(
          display: Display.flex,
          height: Unit.pixels(48),
          border: Border.all(color: AppColors.border, width: Unit.pixels(1)),
          radius: BorderRadius.circular(Unit.pixels(10)),
          justifyContent: JustifyContent.center,
          alignItems: AlignItems.center,
          flex: Flex(grow: 1, shrink: 1, basis: Unit.zero),
          fontWeight: FontWeight.w600,
          backgroundColor: AppColors.white,
        ),
      ),
  css('.room-fragment__wait').styles(
    display: Display.flex,
    justifyContent: JustifyContent.spaceBetween,
    alignItems: AlignItems.center,
  ),
  css('.room-fragment__guest').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(10)),
  ),
  css('.room-fragment__waiting').combine(AppTextStyles.bodySm).combine(const Styles(fontWeight: FontWeight.w600)),
  css('.room-fragment__dots').styles(
    raw: const <String, String>{'animation': 'welcome-pulse 1.2s ease-in-out infinite alternate'},
  ),
  css.keyframes('welcome-pulse', <String, Styles>{
    'from': const Styles(opacity: 0.4),
    'to': const Styles(opacity: 1),
  }),
  css('.room-fragment__countdown')
      .combine(AppTextStyles.monoBodySm)
      .combine(
        const Styles(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          raw: <String, String>{'font-variant-numeric': 'tabular-nums'},
        ),
      ),
  css('.app-reveal--armed:not(.app-reveal--in) .room-fragment__tile').styles(
    opacity: 0,
    transform: Transform.scale(0.9),
  ),
  css('.app-reveal--in .room-fragment__tile').styles(
    raw: const <String, String>{'animation': 'welcome-tile-in 300ms ease both calc(200ms + var(--tile) * 100ms)'},
  ),
  css.keyframes('welcome-tile-in', <String, Styles>{
    'from': const Styles(opacity: 0, transform: Transform.scale(0.9)),
    'to': const Styles(opacity: 1, transform: Transform.scale(1)),
  }),
  css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), <StyleRule>[
    css('.app-reveal--in .room-fragment__tile').styles(raw: const <String, String>{'animation': 'none'}),
    css('.room-fragment__dots').styles(raw: const <String, String>{'animation': 'none'}),
  ]),
];
