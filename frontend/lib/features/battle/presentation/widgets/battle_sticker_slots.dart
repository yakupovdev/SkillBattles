import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/features/battle/presentation/bloc/battle_stickers_bloc/battle_stickers_bloc.dart';
import 'package:skill_battles/features/battle/presentation/controllers/sticker_picker_controller.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_compositions_scope.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_picker_scope.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_trigger_button.dart';
import 'package:skill_battles/features/battle/presentation/widgets/stickers_hidden_indicator.dart';

/// Window widths the sticker widgets are laid out for. The layout is the
/// 880 px column with a gutter on each side (see `StickerOverlay`).
abstract final class StickerLayout {
  static const double minViewportWidth = 1280;
  static const double columnWidth = 880;
  static const double edgeInset = 16;

  /// Width of one side gutter for a window of [viewportWidth].
  static double gutterOf(double viewportWidth) =>
      math.max(0, viewportWidth - columnWidth) / 2;

  /// A box of [width] fits in the gutter with [edgeInset] on both sides.
  ///
  /// Never below [minViewportWidth]: there the page scrolls sideways inside
  /// a fixed-width canvas (`AppDesktopViewport`), while the overlay is laid
  /// out against the window, so its gutters no longer line up with the
  /// column.
  static bool fits(double viewportWidth, double width) =>
      viewportWidth >= minViewportWidth &&
      edgeInset + width + edgeInset <= gutterOf(viewportWidth);
}

typedef _TriggerData = (
  bool isConnected,
  bool isAllowed,
  DateTime? cooldown,
  bool isSending,
);

/// [StickerTriggerButton] wired to the sticker bloc and the picker scope;
/// rebuilds only when the trigger's own inputs change.
final class BattleStickerTrigger extends StatelessWidget {
  const BattleStickerTrigger({super.key});

  @override
  Widget build(BuildContext context) {
    final StickerPickerController? controller = StickerPickerScope.maybeOf(
      context,
    );
    if (controller == null) return const SizedBox.shrink();
    final bool isReady =
        StickerCompositionsScope.maybeOf(context)?.isReady ?? true;
    final bool fits = StickerLayout.fits(MediaQuery.sizeOf(context).width, 200);
    return BlocSelector<BattleStickersBloc, BattleStickersState, _TriggerData>(
      selector: (BattleStickersState state) => (
        state.connection == RealtimeStatus.connected,
        state.isPhaseAllowed && !state.serverClosed,
        state.cooldownUntil,
        state.isSending,
      ),
      builder: (BuildContext context, _TriggerData data) {
        final String? disabledMessage = !data.$2
            ? 'Stickers are not available now'
            : !data.$1
            ? 'Reconnecting…'
            : !isReady
            ? 'Loading stickers…'
            : !fits
            ? 'Window too narrow for stickers'
            : null;
        return KeyedSubtree(
          key: controller.triggerKey,
          child: ValueListenableBuilder<bool>(
            valueListenable: controller.isOpen,
            builder: (BuildContext context, bool isOpen, Widget? _) =>
                StickerTriggerButton(
                  isOpen: isOpen,
                  cooldownUntil: data.$3,
                  cooldown: BattleStickersBloc.cooldown,
                  disabledMessage: disabledMessage,
                  focusNode: controller.triggerFocus,
                  // While a send is in flight the trigger keeps its look
                  // and its keyboard focus (disabling it would drop the
                  // focus the picker just returned) but opens nothing: a
                  // second send would be refused anyway.
                  onTap: data.$4 ? () {} : controller.toggle,
                ),
          ),
        );
      },
    );
  }
}

/// The "stickers hidden" eye before the opponent's nickname; empty while
/// their stickers are shown.
final class BattleHiddenIndicator extends StatelessWidget {
  const BattleHiddenIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<BattleStickersBloc, BattleStickersState, bool>(
      selector: (BattleStickersState state) => state.opponentHidden,
      builder: (BuildContext context, bool isHidden) => isHidden
          ? const Padding(
              padding: EdgeInsets.only(right: 6),
              child: StickersHiddenIndicator(),
            )
          : const SizedBox.shrink(),
    );
  }
}
