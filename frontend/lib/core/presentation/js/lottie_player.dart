import 'package:universal_web/js_interop.dart';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

/// Plays a Lottie animation with lottie-web (`web/vendor/lottie`, loaded by
/// `main.server.dart`) — the web counterpart of `package:lottie`.
///
/// [animationJson] is the raw text of a Lottie file; it is parsed for every
/// player because lottie-web mutates the data it is given. With [playOnce]
/// the animation plays from the first to the last frame and holds it;
/// otherwise it shows the last frame at once (reduced motion, replays).
/// When lottie-web is missing the box stays empty.
final class LottiePlayer extends StatefulComponent {
  const LottiePlayer({
    required this.animationJson,
    required this.width,
    required this.height,
    this.playOnce = true,
    this.loop = false,
    this.replayToken = 0,
    this.label,
    super.key,
  });

  final String animationJson;
  final double width;
  final double height;
  final bool playOnce;
  final bool loop;

  /// Changing this number replays the animation from the first frame
  /// without re-creating the player (no blank flash).
  final int replayToken;

  /// Accessible name; `null` hides the animation from assistive technology.
  final String? label;

  @override
  State<LottiePlayer> createState() => _LottiePlayerState();
}

final class _LottiePlayerState extends State<LottiePlayer> {
  late GlobalNodeKey<web.HTMLElement> _containerKey;
  _AnimationItem? _animation;

  @override
  void initState() {
    super.initState();
    _containerKey = GlobalNodeKey<web.HTMLElement>();
    if (kIsWeb) context.binding.addPostFrameCallback(_start);
  }

  @override
  void didUpdateComponent(LottiePlayer oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.animationJson != component.animationJson ||
        oldComponent.loop != component.loop ||
        oldComponent.playOnce != component.playOnce) {
      _stop();
      context.binding.addPostFrameCallback(_start);
    } else if (oldComponent.replayToken != component.replayToken) {
      _animation?.goToAndPlay(0, true);
    }
  }

  void _start() {
    if (!mounted) return;
    final web.HTMLElement? container = _containerKey.currentNode;
    final _Lottie? lottie = _lottieGlobal;
    if (container == null || lottie == null) return;
    final JSAny? data;
    try {
      data = _jsonParse(component.animationJson);
    } on Object {
      return;
    }
    if (data == null) return;
    final bool animate = component.playOnce || component.loop;
    final _AnimationItem item = lottie.loadAnimation(
      _LoadParams(
        container: container,
        renderer: 'svg',
        loop: component.loop,
        autoplay: animate,
        animationData: data,
      ),
    );
    if (!animate) item.goToAndStop(item.totalFrames - 1, true);
    _animation = item;
  }

  void _stop() {
    _animation?.destroy();
    _animation = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Component build(BuildContext context) => div(
    key: _containerKey,
    styles: Styles(
      width: Unit.pixels(component.width),
      height: Unit.pixels(component.height),
    ),
    attributes: component.label == null
        ? const <String, String>{'aria-hidden': 'true'}
        : <String, String>{'role': 'img', 'aria-label': component.label!},
    const <Component>[],
  );
}

@JS('lottie')
external _Lottie? get _lottieGlobal;

@JS('JSON.parse')
external JSAny? _jsonParse(String text);

extension type _Lottie._(JSObject _) implements JSObject {
  external _AnimationItem loadAnimation(_LoadParams params);
}

extension type _LoadParams._(JSObject _) implements JSObject {
  external factory _LoadParams({
    web.Element container,
    String renderer,
    bool loop,
    bool autoplay,
    JSAny animationData,
  });
}

extension type _AnimationItem._(JSObject _) implements JSObject {
  external num get totalFrames;
  external void goToAndStop(num value, bool isFrame);
  external void goToAndPlay(num value, bool isFrame);
  external void destroy();
}
