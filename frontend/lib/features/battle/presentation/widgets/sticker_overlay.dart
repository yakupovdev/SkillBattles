import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/features/battle/domain/entity/battle_phase.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';
import 'package:skill_battles/features/battle/presentation/bloc/battle_bloc/battle_bloc.dart';
import 'package:skill_battles/features/battle/presentation/bloc/battle_stickers_bloc/battle_stickers_bloc.dart';
import 'package:skill_battles/features/battle/presentation/controllers/sticker_picker_controller.dart';
import 'package:skill_battles/features/battle/presentation/widgets/battle_sticker_slots.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_bubble.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_picker.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_picker_scope.dart';

/// The sticker picker and both bubbles, laid over the battle screen in the
/// side gutters below the time bar. It never covers the 880 px column: a
/// box that does not fit the gutter is not shown.
///
/// Sits outside the battle body's builder, so a sticker never rebuilds the
/// question or the options; each part selects its own slice of the bloc.
final class StickerOverlay extends StatelessWidget {
  const StickerOverlay({super.key});

  /// 104 header + 12 gap, plus the 6 px time bar while a round is on.
  static const double topWithoutTimeBar = 116;
  static const double topWithTimeBar = 122;
  static const double _frameInset = 64;

  @override
  Widget build(BuildContext context) {
    final StickerPickerController? controller = StickerPickerScope.maybeOf(
      context,
    );
    return BlocListener<BattleStickersBloc, BattleStickersState>(
      // The picker cannot stay open once a send would be refused.
      listenWhen: (BattleStickersState previous, BattleStickersState current) =>
          previous.connection != current.connection ||
          previous.phase != current.phase ||
          previous.serverClosed != current.serverClosed,
      listener: (BuildContext context, BattleStickersState state) {
        final bool isOff =
            state.connection != RealtimeStatus.connected ||
            !state.isPhaseAllowed ||
            state.serverClosed;
        if (isOff) controller?.close();
      },
      child: BlocSelector<BattleStickersBloc, BattleStickersState, double>(
        selector: (BattleStickersState state) =>
            state.phase == BattlePhase.question ||
                state.phase == BattlePhase.reveal
            ? topWithTimeBar
            : topWithoutTimeBar,
        builder: (BuildContext context, double top) =>
            _OverlayFrame(top: top, controller: controller),
      ),
    );
  }
}

final class _OverlayFrame extends StatelessWidget {
  const _OverlayFrame({required this.top, required this.controller});

  final double top;
  final StickerPickerController? controller;

  /// Left offset of a box of [width]: aligned with the header block, or
  /// slid left to stay inside a narrow gutter.
  static double _inset(double viewportWidth, double width) {
    final double frame =
        math.max(0, (viewportWidth - 1440) / 2) + StickerOverlay._frameInset;
    final double gutter = StickerLayout.gutterOf(viewportWidth);
    if (frame + width + StickerLayout.edgeInset <= gutter) return frame;
    return math.max(
      StickerLayout.edgeInset,
      gutter - StickerLayout.edgeInset - width,
    );
  }

  @override
  Widget build(BuildContext context) {
    final StickerPickerController? controller = this.controller;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewportWidth = constraints.maxWidth;
        final bool bubblesFit = StickerLayout.fits(
          viewportWidth,
          StickerBubble.width,
        );
        final double bubbleInset = _inset(viewportWidth, StickerBubble.width);
        return Stack(
          children: <Widget>[
            if (bubblesFit) ...<Widget>[
              Positioned(
                left: bubbleInset,
                top: top,
                child: const _OwnBubble(),
              ),
              Positioned(
                right: bubbleInset,
                top: top,
                child: const _OpponentBubble(),
              ),
            ],
            if (controller != null &&
                StickerLayout.fits(viewportWidth, StickerPicker.width))
              _PickerLayer(
                controller: controller,
                left: _inset(viewportWidth, StickerPicker.width),
                top: top,
              ),
          ],
        );
      },
    );
  }
}

final class _OwnBubble extends StatelessWidget {
  const _OwnBubble();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      BattleStickersBloc,
      BattleStickersState,
      OwnStickerBubble?
    >(
      selector: (BattleStickersState state) => state.ownBubble,
      builder: (BuildContext context, OwnStickerBubble? bubble) =>
          StickerBubbleSwitcher(
            isCaretRight: false,
            child: bubble == null
                ? null
                : StickerBubble(
                    key: ValueKey<String>(bubble.submissionId),
                    variant: bubble.status == OwnStickerStatus.notSent
                        ? StickerBubbleVariant.notSent
                        : StickerBubbleVariant.outgoing,
                    stickerId: bubble.stickerId,
                    caption: 'You',
                  ),
          ),
    );
  }
}

final class _OpponentBubble extends StatelessWidget {
  const _OpponentBubble();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      BattleStickersBloc,
      BattleStickersState,
      OpponentStickerBubble?
    >(
      selector: (BattleStickersState state) => state.opponentBubble,
      builder: (BuildContext context, OpponentStickerBubble? bubble) =>
          StickerBubbleSwitcher(
            isCaretRight: true,
            child: bubble == null
                ? null
                : StickerBubble(
                    key: ValueKey<String>(bubble.eventId),
                    variant: StickerBubbleVariant.incoming,
                    stickerId: bubble.stickerId,
                    caption: context.select<BattleBloc, String>(
                      (BattleBloc bloc) =>
                          bloc.state.snapshot?.opponent.nickname ?? '',
                    ),
                  ),
          ),
    );
  }
}

/// Outside-click barrier plus the picker, while it is open.
final class _PickerLayer extends StatelessWidget {
  const _PickerLayer({
    required this.controller,
    required this.left,
    required this.top,
  });

  final StickerPickerController controller;
  final double left;
  final double top;

  /// Where the trigger's centre is, in px from the picker's left.
  double _caretCenter() {
    final RenderObject? box = controller.triggerKey.currentContext
        ?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return 32;
    return box.localToGlobal(box.size.center(Offset.zero)).dx - left;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.isOpen,
      builder: (BuildContext context, bool isOpen, Widget? _) {
        if (!isOpen) return const SizedBox.shrink();
        return Positioned.fill(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: controller.close,
                  onSecondaryTap: controller.close,
                ),
              ),
              Positioned(
                left: left,
                top: top,
                child: _BattlePicker(
                  caretCenter: _caretCenter(),
                  onClose: () => controller.close(returnFocus: true),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

typedef _PickerData = (DateTime? cooldown, bool isHidden);

/// [StickerPicker] wired to the sticker bloc.
final class _BattlePicker extends StatelessWidget {
  const _BattlePicker({required this.caretCenter, required this.onClose});

  final double caretCenter;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final String nickname = context.select<BattleBloc, String>(
      (BattleBloc bloc) => bloc.state.snapshot?.opponent.nickname ?? '',
    );
    return BlocSelector<BattleStickersBloc, BattleStickersState, _PickerData>(
      selector: (BattleStickersState state) =>
          (state.cooldownUntil, state.opponentHidden),
      builder: (BuildContext context, _PickerData data) => StickerPicker(
        opponentNickname: nickname,
        isOpponentHidden: data.$2,
        cooldownUntil: data.$1,
        caretCenter: caretCenter,
        onSelected: (StickerId id) {
          context.read<BattleStickersBloc>().add(
            BattleStickerSendRequested(id),
          );
          onClose();
        },
        onToggleOpponentHidden: () => context.read<BattleStickersBloc>().add(
          const BattleStickersOpponentHiddenToggled(),
        ),
        onClose: onClose,
      ),
    );
  }
}
