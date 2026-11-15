import 'package:lottie/lottie.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_compositions_scope.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_labels.dart';

/// One sticker composition at [size].
///
/// An animated view plays the cached composition ONCE from 0 to 1 and holds
/// the last frame (never loops); give it a `ValueKey` of the message so a
/// re-send of the same sticker restarts it. The last frame is the resting
/// "settle" frame, so a static view (picker cells, reduced motion) shows
/// progress 1.0.
///
/// The decision is taken once, when the view first builds: a composition
/// that is still loading then is not picked up later (a stale sticker never
/// replays); the sticker name is shown instead, as for a broken asset.
final class StickerView extends StatefulWidget {
  const StickerView({
    required this.stickerId,
    required this.size,
    this.isAnimated = true,
    super.key,
  });

  final StickerId stickerId;
  final double size;
  final bool isAnimated;

  @override
  State<StickerView> createState() => _StickerViewState();
}

final class _StickerViewState extends State<StickerView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late LottieComposition? _composition;
  late bool _isSetUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _composition = null;
    _isSetUp = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isSetUp) return;
    _isSetUp = true;
    final LottieComposition? composition = StickerCompositionsScope.maybeOf(
      context,
      listen: false,
    )?.compositionOf(widget.stickerId);
    _composition = composition;
    if (composition == null) return;
    _controller.duration = composition.duration;
    if (widget.isAnimated && !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0);
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LottieComposition? composition = _composition;
    return SizedBox.square(
      dimension: widget.size,
      child: composition == null
          ? _StickerNameFallback(stickerId: widget.stickerId)
          : ExcludeSemantics(
              child: RepaintBoundary(
                child: Lottie(
                  composition: composition,
                  controller: _controller,
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.contain,
                ),
              ),
            ),
    );
  }
}

/// Local fallback: the sticker name as text.
final class _StickerNameFallback extends StatelessWidget {
  const _StickerNameFallback({required this.stickerId});

  final StickerId stickerId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        stickerId.label,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodyXs.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.inkSoft,
        ),
      ),
    );
  }
}
