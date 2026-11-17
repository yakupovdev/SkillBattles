import 'dart:math' as math;

import 'package:bloc_signals_jaspr/bloc_signals_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

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
/// Its root fills the battle screen and lets clicks through; only the
/// bubbles, the picker and its outside-click barrier take pointer events.
/// Sits outside the battle body's builder, so a sticker never rebuilds the
/// question or the options; each part selects its own slice of the bloc.
final class StickerOverlay extends StatelessComponent {
  const StickerOverlay({super.key});

  /// 104 header + 12 gap, plus the 6 px time bar while a round is on.
  static const double topWithoutTimeBar = 116;
  static const double topWithTimeBar = 122;
  static const double _frameInset = 64;

  @override
  Component build(BuildContext context) {
    final StickerPickerController? controller = StickerPickerScope.maybeOf(context);
    return BlocSignalListener<BattleStickersBloc, BattleStickersState>(
      // The picker cannot stay open once a send would be refused.
      listenWhen: (BattleStickersState previous, BattleStickersState current) =>
          previous.connection != current.connection ||
          previous.phase != current.phase ||
          previous.serverClosed != current.serverClosed,
      listener: (BuildContext context, BattleStickersState state) {
        final bool isOff = state.connection != RealtimeStatus.connected || !state.isPhaseAllowed || state.serverClosed;
        if (isOff) controller?.close();
      },
      child: BlocSignalSelector<BattleStickersBloc, BattleStickersState, double>(
        selector: (BattleStickersState state) =>
            state.phase == BattlePhase.question || state.phase == BattlePhase.reveal
            ? topWithTimeBar
            : topWithoutTimeBar,
        builder: (BuildContext context, double top) => StickerViewportWidth(
          builder: (BuildContext context, double viewportWidth) =>
              _OverlayFrame(top: top, viewportWidth: viewportWidth, controller: controller),
        ),
      ),
    );
  }
}

final class _OverlayFrame extends StatelessComponent {
  const _OverlayFrame({required this.top, required this.viewportWidth, required this.controller});

  final double top;
  final double viewportWidth;
  final StickerPickerController? controller;

  /// Left offset of a box of [width]: aligned with the header block, or
  /// slid left to stay inside a narrow gutter.
  static double _inset(double viewportWidth, double width) {
    final double frame = math.max(0, (viewportWidth - 1440) / 2) + StickerOverlay._frameInset;
    final double gutter = StickerLayout.gutterOf(viewportWidth);
    if (frame + width + StickerLayout.edgeInset <= gutter) return frame;
    return math.max(StickerLayout.edgeInset, gutter - StickerLayout.edgeInset - width);
  }

  @override
  Component build(BuildContext context) {
    final StickerPickerController? controller = this.controller;
    final bool bubblesFit = StickerLayout.fits(viewportWidth, StickerBubble.width);
    final double bubbleInset = _inset(viewportWidth, StickerBubble.width);
    return div(classes: 'sticker-overlay', <Component>[
      if (bubblesFit) ...<Component>[
        div(
          classes: 'sticker-overlay__slot',
          styles: Styles(
            position: Position.absolute(top: Unit.pixels(top), left: Unit.pixels(bubbleInset)),
          ),
          const <Component>[_OwnBubble()],
        ),
        div(
          classes: 'sticker-overlay__slot',
          styles: Styles(
            position: Position.absolute(top: Unit.pixels(top), right: Unit.pixels(bubbleInset)),
          ),
          const <Component>[_OpponentBubble()],
        ),
      ],
      if (controller != null && StickerLayout.fits(viewportWidth, StickerPicker.width))
        _PickerLayer(controller: controller, left: _inset(viewportWidth, StickerPicker.width), top: top),
    ]);
  }
}

final class _OwnBubble extends StatelessComponent {
  const _OwnBubble();

  @override
  Component build(BuildContext context) {
    return BlocSignalSelector<BattleStickersBloc, BattleStickersState, OwnStickerBubble?>(
      selector: (BattleStickersState state) => state.ownBubble,
      builder: (BuildContext context, OwnStickerBubble? bubble) => StickerBubbleSwitcher(
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

final class _OpponentBubble extends StatelessComponent {
  const _OpponentBubble();

  @override
  Component build(BuildContext context) {
    return BlocSignalSelector<BattleBloc, BattleState, String>(
      selector: (BattleState state) => state.snapshot?.opponent.nickname ?? '',
      builder: (BuildContext context, String nickname) =>
          BlocSignalSelector<BattleStickersBloc, BattleStickersState, OpponentStickerBubble?>(
            selector: (BattleStickersState state) => state.opponentBubble,
            builder: (BuildContext context, OpponentStickerBubble? bubble) => StickerBubbleSwitcher(
              isCaretRight: true,
              child: bubble == null
                  ? null
                  : StickerBubble(
                      key: ValueKey<String>(bubble.eventId),
                      variant: StickerBubbleVariant.incoming,
                      stickerId: bubble.stickerId,
                      caption: nickname,
                    ),
            ),
          ),
    );
  }
}

/// Outside-click barrier plus the picker, while it is open.
final class _PickerLayer extends StatelessComponent {
  const _PickerLayer({required this.controller, required this.left, required this.top});

  final StickerPickerController controller;
  final double left;
  final double top;

  /// Where the trigger's centre is, in px from the picker's left (the
  /// overlay starts at the window's left edge).
  double _caretCenter() {
    final double? center = controller.triggerCenterX();
    return center == null ? 32 : center - left;
  }

  @override
  Component build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      listenable: controller.isOpen,
      builder: (BuildContext context, bool isOpen) {
        if (!isOpen) return const Component.empty();
        return Component.fragment(<Component>[
          div(
            classes: 'sticker-overlay__barrier',
            events: <String, void Function(web.Event)>{
              'click': (web.Event _) => controller.close(),
              'contextmenu': (web.Event event) {
                event.preventDefault();
                controller.close();
              },
            },
            const <Component>[],
          ),
          div(
            classes: 'sticker-overlay__slot',
            styles: Styles(
              position: Position.absolute(top: Unit.pixels(top), left: Unit.pixels(left)),
            ),
            <Component>[
              _BattlePicker(caretCenter: _caretCenter(), onClose: () => controller.close(returnFocus: true)),
            ],
          ),
        ]);
      },
    );
  }
}

typedef _PickerData = (DateTime? cooldown, bool isHidden);

/// [StickerPicker] wired to the sticker bloc.
final class _BattlePicker extends StatelessComponent {
  const _BattlePicker({required this.caretCenter, required this.onClose});

  final double caretCenter;
  final VoidCallback onClose;

  @override
  Component build(BuildContext context) {
    return BlocSignalSelector<BattleBloc, BattleState, String>(
      selector: (BattleState state) => state.snapshot?.opponent.nickname ?? '',
      builder: (BuildContext context, String nickname) =>
          BlocSignalSelector<BattleStickersBloc, BattleStickersState, _PickerData>(
            selector: (BattleStickersState state) => (state.cooldownUntil, state.opponentHidden),
            builder: (BuildContext context, _PickerData data) => StickerPicker(
              opponentNickname: nickname,
              isOpponentHidden: data.$2,
              cooldownUntil: data.$1,
              caretCenter: caretCenter,
              onSelected: (StickerId id) {
                context.read<BattleStickersBloc>().add(BattleStickerSendRequested(id));
                onClose();
              },
              onToggleOpponentHidden: () =>
                  context.read<BattleStickersBloc>().add(const BattleStickersOpponentHiddenToggled()),
              onClose: onClose,
            ),
          ),
    );
  }
}

@css
List<StyleRule> get stickerOverlayStyles => <StyleRule>[
  css('.sticker-overlay').styles(
    position: const Position.absolute(top: Unit.zero, left: Unit.zero, right: Unit.zero, bottom: Unit.zero),
    overflow: Overflow.hidden,
    pointerEvents: PointerEvents.none,
  ),
  css('.sticker-overlay__slot').styles(pointerEvents: PointerEvents.auto),
  css('.sticker-overlay__barrier').styles(
    position: const Position.absolute(top: Unit.zero, left: Unit.zero, right: Unit.zero, bottom: Unit.zero),
    pointerEvents: PointerEvents.auto,
  ),
];
