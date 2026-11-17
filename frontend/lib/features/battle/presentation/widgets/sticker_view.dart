import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/js/lottie_player.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_compositions_scope.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_labels.dart';

/// One sticker composition at [size].
///
/// An animated view plays the cached composition ONCE from the first to the
/// last frame and holds it (never loops); give it a `ValueKey` of the
/// message so a re-send of the same sticker restarts it. The last frame is
/// the resting "settle" frame, so a static view (picker cells, reduced
/// motion) shows it at once.
///
/// The decision is taken once, when the view is first built: a composition
/// that is still loading then is not picked up later (a stale sticker never
/// replays); the sticker name is shown instead, as for a broken asset.
final class StickerView extends StatefulComponent {
  const StickerView({required this.stickerId, required this.size, this.isAnimated = true, super.key});

  final StickerId stickerId;
  final double size;
  final bool isAnimated;

  @override
  State<StickerView> createState() => _StickerViewState();
}

final class _StickerViewState extends State<StickerView> {
  late String? _composition;
  late bool _shouldAnimate;
  late bool _isSetUp;

  @override
  void initState() {
    super.initState();
    _composition = null;
    _shouldAnimate = false;
    _isSetUp = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isSetUp) return;
    _isSetUp = true;
    _composition = StickerCompositionsScope.maybeOf(context, listen: false)?.compositionOf(component.stickerId);
    _shouldAnimate = component.isAnimated && !_prefersReducedMotion();
  }

  static bool _prefersReducedMotion() => kIsWeb && web.window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  @override
  Component build(BuildContext context) {
    final String? composition = _composition;
    return div(
      classes: 'sticker-view',
      styles: Styles(width: Unit.pixels(component.size), height: Unit.pixels(component.size)),
      <Component>[
        if (composition == null)
          _StickerNameFallback(stickerId: component.stickerId)
        else
          LottiePlayer(
            animationJson: composition,
            width: component.size,
            height: component.size,
            playOnce: _shouldAnimate,
          ),
      ],
    );
  }
}

/// Local fallback: the sticker name as text.
final class _StickerNameFallback extends StatelessComponent {
  const _StickerNameFallback({required this.stickerId});

  final StickerId stickerId;

  @override
  Component build(BuildContext context) {
    return span(classes: 'sticker-view__name', <Component>[Component.text(stickerId.label)]);
  }
}

@css
List<StyleRule> get stickerViewStyles => <StyleRule>[
  css('.sticker-view').styles(
    display: Display.flex,
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
    flex: const Flex(shrink: 0),
  ),
  css('.sticker-view__name')
      .styles(
        overflow: Overflow.hidden,
        raw: const <String, String>{
          'display': '-webkit-box',
          '-webkit-line-clamp': '2',
          '-webkit-box-orient': 'vertical',
        },
      )
      .combine(AppTextStyles.bodyXs)
      .combine(const Styles(color: AppColors.inkSoft, textAlign: TextAlign.center, fontWeight: FontWeight.w600)),
];
