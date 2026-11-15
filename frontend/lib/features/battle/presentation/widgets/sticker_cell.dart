import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_labels.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_view.dart';

/// One 56 px cell of the picker grid. Shows the settle frame (never
/// autoplays); hover and keyboard focus look the same and are reported to
/// the picker for its footer. A `null` [onSelected] disables it.
final class StickerCell extends StatefulWidget {
  const StickerCell({
    required this.stickerId,
    required this.onSelected,
    required this.onHighlightChanged,
    required this.onPressedChanged,
    this.focusNode,
    super.key,
  });

  final StickerId stickerId;
  final VoidCallback? onSelected;

  /// Hover or keyboard focus started (true) or ended (false).
  final ValueChanged<bool> onHighlightChanged;
  final ValueChanged<bool> onPressedChanged;
  final FocusNode? focusNode;

  @override
  State<StickerCell> createState() => _StickerCellState();
}

final class _StickerCellState extends State<StickerCell> {
  late bool _isHovered;
  late bool _isFocusVisible;
  late bool _isPressed;
  late Map<Type, Action<Intent>> _actions;

  bool get _isHighlighted => _isHovered || _isFocusVisible;

  @override
  void initState() {
    super.initState();
    _isHovered = false;
    _isFocusVisible = false;
    _isPressed = false;
    // On the web Enter maps to ButtonActivateIntent (not ActivateIntent),
    // so both are handled: Enter and Space send.
    _actions = <Type, Action<Intent>>{
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (ActivateIntent intent) {
          widget.onSelected?.call();
          return null;
        },
      ),
      ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
        onInvoke: (ButtonActivateIntent intent) {
          widget.onSelected?.call();
          return null;
        },
      ),
    };
  }

  void _update({bool? hovered, bool? focusVisible, bool? pressed}) {
    final bool wasHighlighted = _isHighlighted;
    final bool wasPressed = _isPressed;
    setState(() {
      _isHovered = hovered ?? _isHovered;
      _isFocusVisible = focusVisible ?? _isFocusVisible;
      _isPressed = pressed ?? _isPressed;
    });
    if (wasHighlighted != _isHighlighted) {
      widget.onHighlightChanged(_isHighlighted);
    }
    if (wasPressed != _isPressed) widget.onPressedChanged(_isPressed);
  }

  @override
  void didUpdateWidget(StickerCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onSelected == null && _isPressed) _update(pressed: false);
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onSelected != null;
    final bool isPressed = enabled && _isPressed;
    final bool isHighlighted = enabled && _isHighlighted;
    final Color fill = isPressed
        ? AppColors.primaryTint
        : isHighlighted
        ? AppColors.primarySurface
        : const Color(0x00000000);
    final Border? border = isPressed
        ? Border.all(color: AppColors.primary, width: 1.5)
        : isHighlighted
        ? Border.all(color: AppColors.primaryLine)
        : null;
    final double size = isPressed
        ? 38
        : isHighlighted
        ? 50
        : 44;
    return FocusableActionDetector(
      focusNode: widget.focusNode,
      enabled: enabled,
      actions: _actions,
      mouseCursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onShowHoverHighlight: (bool value) => _update(hovered: value),
      onShowFocusHighlight: (bool value) => _update(focusVisible: value),
      child: Semantics(
        button: true,
        enabled: enabled,
        label: widget.stickerId.semanticLabel,
        onTap: widget.onSelected,
        child: ExcludeSemantics(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: enabled ? (_) => _update(pressed: true) : null,
            onTapUp: (_) => _update(pressed: false),
            onTapCancel: () => _update(pressed: false),
            onTap: widget.onSelected,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(12),
                border: border,
              ),
              child: SizedBox.square(
                dimension: 56,
                child: Center(
                  child: StickerView(
                    stickerId: widget.stickerId,
                    size: size,
                    isAnimated: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
