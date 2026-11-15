import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_shadows.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_countdown_text.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';
import 'package:skill_battles/features/battle/presentation/widgets/mute_opponent_toggle.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_caret.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_cell.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_labels.dart';

/// The 200 px popover with the 3 x 3 sticker grid (Paper: "32 Battle
/// stickers — Component sheet", states A-D).
///
/// While [cooldownUntil] is set the grid is dimmed and not tappable and the
/// footer counts down. Esc calls [onClose]; focus starts on the first cell
/// (or on the panel when the cells are off).
final class StickerPicker extends StatefulWidget {
  const StickerPicker({
    required this.opponentNickname,
    required this.isOpponentHidden,
    required this.cooldownUntil,
    required this.caretCenter,
    required this.onSelected,
    required this.onToggleOpponentHidden,
    required this.onClose,
    super.key,
  });

  static const double width = 200;

  final String opponentNickname;
  final bool isOpponentHidden;
  final DateTime? cooldownUntil;

  /// Where the caret points, in px from the picker's left; clamped to
  /// 16-168.
  final double caretCenter;
  final ValueChanged<StickerId> onSelected;
  final VoidCallback onToggleOpponentHidden;
  final VoidCallback onClose;

  /// Grid order, row by row.
  static const List<List<StickerId>> rows = <List<StickerId>>[
    <StickerId>[StickerId.gg, StickerId.fire, StickerId.ez],
    <StickerId>[StickerId.lol, StickerId.tooSlow, StickerId.facepalm],
    <StickerId>[StickerId.hmm, StickerId.waitWhat, StickerId.crying],
  ];

  @override
  State<StickerPicker> createState() => _StickerPickerState();
}

final class _StickerPickerState extends State<StickerPicker> {
  late FocusNode _panelNode;
  late FocusNode _firstCellNode;
  late ValueNotifier<StickerId?> _highlighted;
  late ValueNotifier<StickerId?> _pressed;

  bool get _isCoolingDown => widget.cooldownUntil != null;

  @override
  void initState() {
    super.initState();
    _panelNode = FocusNode(debugLabel: 'StickerPicker', skipTraversal: true);
    _firstCellNode = FocusNode(debugLabel: 'StickerPickerFirstCell');
    _highlighted = ValueNotifier<StickerId?>(null);
    _pressed = ValueNotifier<StickerId?>(null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      (_isCoolingDown ? _panelNode : _firstCellNode).requestFocus();
    });
  }

  @override
  void dispose() {
    _panelNode.dispose();
    _firstCellNode.dispose();
    _highlighted.dispose();
    _pressed.dispose();
    super.dispose();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onClose();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _setNotifier(
    ValueNotifier<StickerId?> notifier,
    StickerId id, {
    required bool isOn,
  }) {
    if (isOn) {
      notifier.value = id;
    } else if (notifier.value == id) {
      notifier.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double caretLeft = widget.caretCenter.clamp(16, 168) - 8;
    final bool isCoolingDown = _isCoolingDown;
    return Focus(
      focusNode: _panelNode,
      onKeyEvent: _onKeyEvent,
      child: SizedBox(
        width: StickerPicker.width,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.overlay,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 4,
                  children: <Widget>[
                    _PickerHeader(
                      opponentNickname: widget.opponentNickname,
                      isOpponentHidden: widget.isOpponentHidden,
                      onToggleOpponentHidden: widget.onToggleOpponentHidden,
                    ),
                    Opacity(
                      opacity: isCoolingDown ? 0.4 : 1,
                      child: _GridKeyboard(
                        child: Column(
                          spacing: 8,
                          children: <Widget>[
                            for (final List<StickerId> row
                                in StickerPicker.rows)
                              Row(
                                spacing: 8,
                                children: <Widget>[
                                  for (final StickerId id in row)
                                    StickerCell(
                                      key: ValueKey<StickerId>(id),
                                      stickerId: id,
                                      focusNode: id == StickerId.gg
                                          ? _firstCellNode
                                          : null,
                                      onSelected: isCoolingDown
                                          ? null
                                          : () => widget.onSelected(id),
                                      onHighlightChanged: (bool isOn) =>
                                          _setNotifier(
                                            _highlighted,
                                            id,
                                            isOn: isOn,
                                          ),
                                      onPressedChanged: (bool isOn) =>
                                          _setNotifier(
                                            _pressed,
                                            id,
                                            isOn: isOn,
                                          ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    _PickerFooter(
                      cooldownUntil: widget.cooldownUntil,
                      highlighted: _highlighted,
                      pressed: _pressed,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -8,
              left: caretLeft,
              child: const StickerCaret(
                fill: AppColors.white,
                stroke: AppColors.border,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _PickerHeader extends StatelessWidget {
  const _PickerHeader({
    required this.opponentNickname,
    required this.isOpponentHidden,
    required this.onToggleOpponentHidden,
  });

  final String opponentNickname;
  final bool isOpponentHidden;
  final VoidCallback onToggleOpponentHidden;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          const Text('STICKERS', style: AppTextStyles.eyebrow),
          MuteOpponentToggle(
            isHidden: isOpponentHidden,
            opponentNickname: opponentNickname,
            onTap: onToggleOpponentHidden,
          ),
        ],
      ),
    );
  }
}

final class _PickerFooter extends StatelessWidget {
  const _PickerFooter({
    required this.cooldownUntil,
    required this.highlighted,
    required this.pressed,
  });

  final DateTime? cooldownUntil;
  final ValueListenable<StickerId?> highlighted;
  final ValueListenable<StickerId?> pressed;

  @override
  Widget build(BuildContext context) {
    final DateTime? until = cooldownUntil;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: until != null
            ? Row(
                spacing: 8,
                children: <Widget>[
                  const AppSvgIcon(
                    AppIcons.clock,
                    width: 14,
                    height: 14,
                    color: AppColors.primary,
                  ),
                  // Paper leaves exactly 144 px for the 20 mono glyphs;
                  // real glyph metrics can be 1-3 px wider, so shrink
                  // instead of overflowing the 200 px picker.
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: AppCountdownText(
                        target: until,
                        prefix: 'Next sticker in ',
                        style: AppTextStyles.outcome.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : ListenableBuilder(
                listenable: Listenable.merge(<Listenable>[
                  highlighted,
                  pressed,
                ]),
                builder: (BuildContext context, Widget? _) => _FooterText(
                  highlighted: highlighted.value,
                  pressed: pressed.value,
                ),
              ),
      ),
    );
  }
}

final class _FooterText extends StatelessWidget {
  const _FooterText({required this.highlighted, required this.pressed});

  final StickerId? highlighted;
  final StickerId? pressed;

  @override
  Widget build(BuildContext context) {
    const TextStyle base = TextStyle(color: AppColors.muted);
    final StickerId? sending = pressed;
    final StickerId? shown = highlighted;
    final InlineSpan span = sending != null
        ? TextSpan(
            text: 'Sending ${sending.label}…',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          )
        : shown != null
        ? TextSpan(
            children: <InlineSpan>[
              TextSpan(
                text: shown.label,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(text: ' · ${shown.category.label}'),
            ],
          )
        : const TextSpan(text: 'Tap a sticker to send');
    return Text.rich(span, style: AppTextStyles.bodyXs.merge(base));
  }
}

/// Arrow keys move focus inside the 3 x 3 grid. On the web the default
/// shortcuts map the arrows to scrolling, so they are remapped here, and
/// the group keeps directional moves among the cells.
final class _GridKeyboard extends StatelessWidget {
  const _GridKeyboard({required this.child});

  final Widget child;

  static const Map<ShortcutActivator, Intent> _arrows =
      <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(
          TraversalDirection.up,
        ),
        SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(
          TraversalDirection.down,
        ),
        SingleActivator(LogicalKeyboardKey.arrowLeft): DirectionalFocusIntent(
          TraversalDirection.left,
        ),
        SingleActivator(LogicalKeyboardKey.arrowRight): DirectionalFocusIntent(
          TraversalDirection.right,
        ),
      };

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _arrows,
      child: FocusTraversalGroup(child: child),
    );
  }
}
