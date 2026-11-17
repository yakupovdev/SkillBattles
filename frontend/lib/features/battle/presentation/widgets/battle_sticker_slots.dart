import 'dart:math' as math;

import 'package:bloc_signals_jaspr/bloc_signals_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/js_interop.dart';
import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/features/battle/presentation/bloc/battle_stickers_bloc/battle_stickers_bloc.dart';
import 'package:skill_battles/features/battle/presentation/controllers/sticker_picker_controller.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_compositions_scope.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_picker_scope.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_trigger_button.dart';
import 'package:skill_battles/features/battle/presentation/widgets/stickers_hidden_indicator.dart';

/// Window widths the sticker components are laid out for. The layout is the
/// 880 px column with a gutter on each side (see `StickerOverlay`).
abstract final class StickerLayout {
  static const double minViewportWidth = 1280;
  static const double columnWidth = 880;
  static const double edgeInset = 16;

  /// Width of one side gutter for a window of [viewportWidth].
  static double gutterOf(double viewportWidth) => math.max(0, viewportWidth - columnWidth) / 2;

  /// A box of [width] fits in the gutter with [edgeInset] on both sides.
  ///
  /// Never below [minViewportWidth]: there the page scrolls sideways inside
  /// a fixed-width canvas (`AppDesktopViewport`), while the overlay is laid
  /// out against the window, so its gutters no longer line up with the
  /// column.
  static bool fits(double viewportWidth, double width) =>
      viewportWidth >= minViewportWidth && edgeInset + width + edgeInset <= gutterOf(viewportWidth);
}

/// Builds with the width of the browser window and rebuilds when it is
/// resized — what `MediaQuery.sizeOf(context).width` / `LayoutBuilder` gave
/// the sticker layout in Flutter.
final class StickerViewportWidth extends StatefulComponent {
  const StickerViewportWidth({required this.builder, super.key});

  final Component Function(BuildContext context, double viewportWidth) builder;

  @override
  State<StickerViewportWidth> createState() => _StickerViewportWidthState();
}

final class _StickerViewportWidthState extends State<StickerViewportWidth> {
  late double _width;
  web.EventListener? _listener;

  @override
  void initState() {
    super.initState();
    _width = _read();
    if (kIsWeb) {
      final web.EventListener listener = _onResize.toJS;
      _listener = listener;
      web.window.addEventListener('resize', listener);
    }
  }

  static double _read() => kIsWeb ? web.window.innerWidth.toDouble() : StickerLayout.minViewportWidth;

  void _onResize(web.Event _) {
    final double next = _read();
    if (next != _width && mounted) setState(() => _width = next);
  }

  @override
  void dispose() {
    final web.EventListener? listener = _listener;
    if (listener != null) web.window.removeEventListener('resize', listener);
    super.dispose();
  }

  @override
  Component build(BuildContext context) => component.builder(context, _width);
}

typedef _TriggerData = (bool isConnected, bool isAllowed, DateTime? cooldown, bool isSending);

/// [StickerTriggerButton] wired to the sticker bloc and the picker scope;
/// rebuilds only when the trigger's own inputs change.
final class BattleStickerTrigger extends StatelessComponent {
  const BattleStickerTrigger({super.key});

  @override
  Component build(BuildContext context) {
    final StickerPickerController? controller = StickerPickerScope.maybeOf(context);
    if (controller == null) return const Component.empty();
    final bool isReady = StickerCompositionsScope.maybeOf(context)?.isReady ?? true;
    return StickerViewportWidth(
      builder: (BuildContext context, double viewportWidth) => _Trigger(
        controller: controller,
        isReady: isReady,
        fits: StickerLayout.fits(viewportWidth, 200),
      ),
    );
  }
}

final class _Trigger extends StatelessComponent {
  const _Trigger({required this.controller, required this.isReady, required this.fits});

  final StickerPickerController controller;
  final bool isReady;
  final bool fits;

  @override
  Component build(BuildContext context) {
    return BlocSignalSelector<BattleStickersBloc, BattleStickersState, _TriggerData>(
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
        // The keyed element is the anchor of the picker's caret and holds
        // the button that Esc and a send focus again.
        return span(
          key: controller.triggerKey,
          classes: 'battle-sticker-trigger',
          <Component>[
            ValueListenableBuilder<bool>(
              listenable: controller.isOpen,
              builder: (BuildContext context, bool isOpen) => StickerTriggerButton(
                isOpen: isOpen,
                cooldownUntil: data.$3,
                cooldown: BattleStickersBloc.cooldown,
                disabledMessage: disabledMessage,
                // While a send is in flight the trigger keeps its look and
                // its keyboard focus (disabling it would drop the focus the
                // picker just returned) but opens nothing: a second send
                // would be refused anyway.
                onTap: data.$4 ? () {} : controller.toggle,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The "stickers hidden" eye before the opponent's nickname; empty while
/// their stickers are shown.
final class BattleHiddenIndicator extends StatelessComponent {
  const BattleHiddenIndicator({super.key});

  @override
  Component build(BuildContext context) {
    return BlocSignalSelector<BattleStickersBloc, BattleStickersState, bool>(
      selector: (BattleStickersState state) => state.opponentHidden,
      builder: (BuildContext context, bool isHidden) => isHidden
          ? const span(classes: 'battle-hidden-indicator', <Component>[StickersHiddenIndicator()])
          : const Component.empty(),
    );
  }
}

@css
List<StyleRule> get battleStickerSlotsStyles => <StyleRule>[
  css('.battle-sticker-trigger').styles(display: Display.inlineFlex, flex: const Flex(shrink: 0)),
  css('.battle-hidden-indicator').styles(
    display: Display.inlineFlex,
    padding: const Padding.only(right: Unit.pixels(6)),
    flex: const Flex(shrink: 0),
  ),
];
