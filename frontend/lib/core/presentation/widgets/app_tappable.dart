import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';

/// Makes any piece of the design clickable the way a desktop user expects:
/// mouse click with a hand cursor, keyboard focus with Tab, activation with
/// Enter or Space, a visible focus ring drawn just outside the child, and
/// button semantics.
///
/// Use it for every custom tappable (cards, rows, links, tabs) instead of a
/// bare `GestureDetector`, which is unreachable from the keyboard.
/// A `null` [onTap] disables it.
final class AppTappable extends StatefulWidget {
  const AppTappable({
    required this.onTap,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.focusColor = AppColors.primary,
    this.isSelected,
    this.semanticLabel,
    this.semanticValue,
    this.focusNode,
    super.key,
  });

  final VoidCallback? onTap;
  final Widget child;

  /// Shape of the focus ring; match the child's corners.
  final BorderRadius borderRadius;

  /// Color of the focus ring; use a contrasting one on filled surfaces.
  final Color focusColor;

  /// Selection state for assistive technology (tabs, choices).
  final bool? isSelected;

  /// Replaces the child's own semantics when set (for composite cards).
  final String? semanticLabel;

  /// Extra state read after the label ("Correct", "Your answer").
  final String? semanticValue;

  /// Lets the owner move focus here (e.g. back to a trigger after a popover
  /// closes). The owner creates and disposes it.
  final FocusNode? focusNode;

  @override
  State<AppTappable> createState() => _AppTappableState();
}

final class _AppTappableState extends State<AppTappable> {
  late bool _showFocus;
  late Map<Type, Action<Intent>> _actions;

  @override
  void initState() {
    super.initState();
    _showFocus = false;
    // The web shortcuts map Enter to ButtonActivateIntent and Space to
    // ActivateIntent; handle both so Enter works in the browser too.
    _actions = <Type, Action<Intent>>{
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (ActivateIntent intent) {
          widget.onTap?.call();
          return null;
        },
      ),
      ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
        onInvoke: (ButtonActivateIntent intent) {
          widget.onTap?.call();
          return null;
        },
      ),
    };
  }

  void _onShowFocusHighlight(bool value) {
    if (value == _showFocus) return;
    setState(() => _showFocus = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onTap != null;
    final String? label = widget.semanticLabel;

    // The label replaces only the visual child's semantics; the Focus node
    // below stays in the tree so its focusable/focused flags are reported.
    final Widget visual = label == null
        ? widget.child
        : ExcludeSemantics(child: widget.child);

    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      selected: widget.isSelected,
      label: label,
      value: widget.semanticValue,
      onTap: widget.onTap,
      child: FocusableActionDetector(
        enabled: enabled,
        focusNode: widget.focusNode,
        actions: _actions,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: _onShowFocusHighlight,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          excludeFromSemantics: true,
          child: CustomPaint(
            foregroundPainter: _showFocus
                ? _FocusRingPainter(
                    color: widget.focusColor,
                    borderRadius: widget.borderRadius,
                  )
                : null,
            child: visual,
          ),
        ),
      ),
    );
  }
}

/// A 2 px ring drawn 3 px OUTSIDE the child, so it never coincides with the
/// child's own border (e.g. a selected card) and never covers text.
final class _FocusRingPainter extends CustomPainter {
  const _FocusRingPainter({required this.color, required this.borderRadius});

  static const double _gap = 3;
  static const double _width = 2;

  final Color color;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    const double offset = _gap + _width / 2;
    final RRect ring = borderRadius.toRRect(Offset.zero & size).inflate(offset);
    canvas.drawRRect(
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _width
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_FocusRingPainter oldDelegate) =>
      color != oldDelegate.color || borderRadius != oldDelegate.borderRadius;
}
