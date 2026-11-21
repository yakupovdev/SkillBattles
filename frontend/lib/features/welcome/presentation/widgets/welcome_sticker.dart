import 'dart:async';
import 'dart:math';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/core/presentation/js/lottie_player.dart';
import 'package:skill_battles/core/presentation/utils/reduced_motion.dart';
import 'package:skill_battles/core/presentation/utils/visibility_gate.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_compositions_scope.dart';

/// A decorative battle sticker of the landing page.
///
/// Cross-feature dependency (accepted for the landing): the sticker
/// compositions, [StickerId] and the app-level [StickerCompositionsScope]
/// belong to the battle feature but are an app-wide resource.
///
/// It renders nothing until its composition is loaded (never the text
/// fallback of `StickerView`). Then, once it is at least half visible in a
/// visible tab, it pops in after [firstDelay] and plays once; it replays
/// from the first frame every 6-14 s while it stays visible, and at once on
/// mouse hover (at most once per play). It rests on its last frame between
/// plays. Under reduced motion it is the last frame only.
///
/// With [position] it is absolutely placed inside its (positioned) parent
/// and never affects the layout; without it, it sits in the normal flow.
final class WelcomeSticker extends StatefulComponent {
  const WelcomeSticker({
    required this.stickerId,
    required this.size,
    this.rotation = 0,
    this.firstDelay = Duration.zero,
    this.position,
    super.key,
  });

  final StickerId stickerId;

  /// Width and height, px.
  final double size;

  /// Tilt in degrees.
  final double rotation;

  /// Wait between becoming visible and the first play.
  final Duration firstDelay;

  /// Absolute placement inside the parent; `null` for the normal flow.
  final Position? position;

  @override
  State<WelcomeSticker> createState() => _WelcomeStickerState();
}

final class _WelcomeStickerState extends State<WelcomeSticker> {
  static final Random _random = Random();

  late GlobalNodeKey<web.HTMLElement> _elementKey;
  late bool _isStatic;
  late bool _isShown;
  late bool _isPopping;
  late bool _canReplayOnHover;
  late int _replayToken;
  VisibilityGate? _gate;
  Timer? _firstTimer;
  Timer? _replayTimer;

  @override
  void initState() {
    super.initState();
    _elementKey = GlobalNodeKey<web.HTMLElement>();
    _isStatic = !kIsWeb || prefersReducedMotion();
    // Reduced motion (and the server): the last frame, no entrance.
    _isShown = _isStatic;
    _isPopping = false;
    _canReplayOnHover = false;
    _replayToken = 0;
    if (kIsWeb) {
      StickerCompositionsScope.maybeOf(context, listen: false)?.ensureLoaded();
      if (!_isStatic) context.binding.addPostFrameCallback(_watch);
    }
  }

  void _watch() {
    final web.HTMLElement? element = _elementKey.currentNode;
    if (!mounted || element == null) return;
    final VisibilityGate gate = VisibilityGate(threshold: 0.5, onChanged: _onActiveChanged);
    _gate = gate;
    if (!gate.attach(element)) {
      gate.dispose();
      _gate = null;
      setState(() => _isShown = true);
    }
  }

  void _onActiveChanged(bool isActive) {
    if (!mounted) return;
    if (!isActive) {
      _firstTimer?.cancel();
      _replayTimer?.cancel();
      _firstTimer = null;
      _replayTimer = null;
      return;
    }
    if (!_isShown) {
      _firstTimer ??= Timer(component.firstDelay, _firstPlay);
    } else {
      _scheduleReplay();
    }
  }

  void _firstPlay() {
    _firstTimer = null;
    if (!mounted || _gate?.isActive != true) return;
    setState(() {
      _isShown = true;
      _isPopping = true;
      _canReplayOnHover = true;
    });
    _scheduleReplay();
  }

  void _scheduleReplay() {
    _replayTimer?.cancel();
    _replayTimer = Timer(Duration(milliseconds: 6000 + _random.nextInt(8001)), () {
      _replayTimer = null;
      if (_gate?.isActive == true) _replay();
    });
  }

  void _replay() {
    if (!mounted) return;
    setState(() {
      _replayToken++;
      _canReplayOnHover = true;
    });
    _scheduleReplay();
  }

  void _onPointerEnter(web.Event event) {
    if (_isStatic || !_isShown || !_canReplayOnHover) return;
    if ((event as web.PointerEvent).pointerType != 'mouse') return;
    _replay();
    // One hover replay per play: it is allowed again by the next play.
    _canReplayOnHover = false;
  }

  @override
  void dispose() {
    _gate?.dispose();
    _firstTimer?.cancel();
    _replayTimer?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final String? composition = StickerCompositionsScope.maybeOf(context)?.compositionOf(component.stickerId);
    final Position? position = component.position;
    return div(
      key: _elementKey,
      classes: <String>[
        'welcome-sticker',
        if (position != null) 'welcome-sticker--placed',
        if (_isPopping) 'welcome-sticker--pop',
      ].join(' '),
      styles: Styles(
        position: position,
        width: Unit.pixels(component.size),
        height: Unit.pixels(component.size),
        raw: <String, String>{'--rot': '${component.rotation}deg'},
      ),
      attributes: const <String, String>{'aria-hidden': 'true'},
      events: _isStatic ? null : <String, void Function(web.Event)>{'pointerenter': _onPointerEnter},
      <Component>[
        if (composition != null && _isShown)
          LottiePlayer(
            animationJson: composition,
            width: component.size,
            height: component.size,
            playOnce: !_isStatic,
            replayToken: _replayToken,
          ),
      ],
    );
  }
}

@css
List<StyleRule> get welcomeStickerStyles => <StyleRule>[
  css('.welcome-sticker').styles(
    flex: const Flex(shrink: 0),
    raw: const <String, String>{'transform': 'rotate(var(--rot, 0deg))'},
  ),
  css('.welcome-sticker--placed').styles(zIndex: const ZIndex(2)),
  css.keyframes('welcome-sticker-pop', <String, Styles>{
    'from': const Styles(
      opacity: 0,
      raw: <String, String>{'transform': 'rotate(var(--rot, 0deg)) scale(0.6)'},
    ),
    'to': const Styles(
      opacity: 1,
      raw: <String, String>{'transform': 'rotate(var(--rot, 0deg)) scale(1)'},
    ),
  }),
  css('.welcome-sticker--pop').styles(
    raw: const <String, String>{'animation': 'welcome-sticker-pop 400ms cubic-bezier(0.34, 1.56, 0.64, 1) both'},
  ),
  css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), <StyleRule>[
    css('.welcome-sticker--pop').styles(raw: const <String, String>{'animation': 'none'}),
  ]),
];
