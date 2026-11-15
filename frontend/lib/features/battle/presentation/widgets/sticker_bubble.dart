import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_shadows.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_caret.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_labels.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_view.dart';

/// Whose bubble it is; decides colors, caret side and caption.
enum StickerBubbleVariant { outgoing, incoming, notSent }

/// A 120 px bubble under a sender's avatar: the sticker plays once, with a
/// caption under it (Paper: "32 Battle stickers — Component sheet", E-G).
///
/// Give it a `ValueKey` of the message (submission or event id) so a
/// re-send restarts the animation. Expiry is owned by the bloc.
final class StickerBubble extends StatelessWidget {
  const StickerBubble({
    required this.variant,
    required this.stickerId,
    this.caption = '',
    super.key,
  });

  static const double width = 120;

  final StickerBubbleVariant variant;
  final StickerId stickerId;

  /// `You`, the opponent's nickname; ignored for [StickerBubbleVariant.notSent].
  final String caption;

  @override
  Widget build(BuildContext context) {
    final (
      Color fill,
      Color line,
      Color dot,
      Color text,
      String label,
    ) = switch (variant) {
      StickerBubbleVariant.outgoing => (
        AppColors.primarySurface,
        AppColors.primaryLine,
        AppColors.primary,
        AppColors.primary,
        caption,
      ),
      StickerBubbleVariant.incoming => (
        AppColors.accentSurface,
        AppColors.accentRowBorder,
        AppColors.accent,
        AppColors.accentText,
        caption,
      ),
      StickerBubbleVariant.notSent => (
        AppColors.white,
        AppColors.border,
        AppColors.danger,
        AppColors.dangerText,
        'Not sent',
      ),
    };
    final bool isIncoming = variant == StickerBubbleVariant.incoming;
    final bool isNotSent = variant == StickerBubbleVariant.notSent;
    final Widget sticker = StickerView(
      key: ValueKey<bool>(isNotSent),
      stickerId: stickerId,
      size: 96,
      isAnimated: !isNotSent,
    );
    final Widget bubble = SizedBox(
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: line),
              boxShadow: AppShadows.overlay,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 2,
                children: <Widget>[
                  isNotSent ? Opacity(opacity: 0.4, child: sticker) : sticker,
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 6,
                    children: <Widget>[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: dot,
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox.square(dimension: 6),
                      ),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyXs.copyWith(
                            fontWeight: FontWeight.w600,
                            color: text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: -8,
            left: isIncoming ? null : 16,
            right: isIncoming ? 16 : null,
            child: StickerCaret(fill: fill, stroke: line),
          ),
        ],
      ),
    );
    return switch (variant) {
      // Announced once, politely, when it appears.
      StickerBubbleVariant.incoming => Semantics(
        liveRegion: true,
        label: '$caption sent ${stickerId.label}',
        excludeSemantics: true,
        child: bubble,
      ),
      StickerBubbleVariant.outgoing => Semantics(
        label: 'You sent ${stickerId.label}',
        excludeSemantics: true,
        child: bubble,
      ),
      StickerBubbleVariant.notSent => Semantics(
        label: 'Sticker not sent',
        excludeSemantics: true,
        child: bubble,
      ),
    };
  }
}

/// Animates a [StickerBubble] in and out. [child] is the current bubble
/// (keyed by its message) or `null` when there is none; the bloc decides
/// when that happens.
///
/// Enter: scale 0.6 to 1 from the caret plus fade, 180 ms ease-out-back.
/// Exit: fade and 8 px up, 200 ms. With reduced motion both are plain fades.
final class StickerBubbleSwitcher extends StatelessWidget {
  const StickerBubbleSwitcher({
    required this.child,
    required this.isCaretRight,
    super.key,
  });

  final StickerBubble? child;

  /// The caret is on the right (the opponent's bubble).
  final bool isCaretRight;

  @override
  Widget build(BuildContext context) {
    final bool isReduced = MediaQuery.disableAnimationsOf(context);
    final StickerBubble? current = child;
    final Key? currentKey = current?.key;
    return AnimatedSwitcher(
      duration: isReduced
          ? const Duration(milliseconds: 120)
          : const Duration(milliseconds: 180),
      reverseDuration: isReduced
          ? const Duration(milliseconds: 120)
          : const Duration(milliseconds: 200),
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) =>
          Stack(
            alignment: isCaretRight ? Alignment.topRight : Alignment.topLeft,
            clipBehavior: Clip.none,
            children: <Widget>[...previousChildren, ?currentChild],
          ),
      transitionBuilder: (Widget bubble, Animation<double> animation) {
        final bool isEntering = bubble.key == currentKey;
        final Animation<double> opacity = animation.drive(
          CurveTween(curve: isEntering ? Curves.easeOut : Curves.easeIn),
        );
        if (isReduced) return FadeTransition(opacity: opacity, child: bubble);
        if (isEntering) {
          return FadeTransition(
            opacity: opacity,
            child: ScaleTransition(
              scale: animation
                  .drive(CurveTween(curve: Curves.easeOutBack))
                  .drive(Tween<double>(begin: 0.6, end: 1)),
              alignment: Alignment(isCaretRight ? 0.73 : -0.73, -1),
              child: bubble,
            ),
          );
        }
        return FadeTransition(
          opacity: opacity,
          child: SlideTransition(
            position: animation.drive(
              Tween<Offset>(begin: const Offset(0, -8 / 132), end: Offset.zero),
            ),
            child: bubble,
          ),
        );
      },
      child: current ?? const SizedBox.shrink(key: ValueKey<String>('none')),
    );
  }
}
