import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_labels.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_view.dart';

/// One 56 px cell of the picker grid. Shows the settle frame (never
/// autoplays); hover and keyboard focus look the same and are reported to
/// the picker for its footer. A `null` [onSelected] disables it.
///
/// Enter and Space send, like a click. The keyboard highlight follows
/// `:focus-visible`, so focus moved there by a mouse click shows nothing.
final class StickerCell extends StatefulComponent {
  const StickerCell({
    required this.stickerId,
    required this.onSelected,
    required this.onHighlightChanged,
    required this.onPressedChanged,
    this.nodeKey,
    super.key,
  });

  final StickerId stickerId;
  final VoidCallback? onSelected;

  /// Hover or keyboard focus started (true) or ended (false).
  final ValueChanged<bool> onHighlightChanged;
  final ValueChanged<bool> onPressedChanged;

  /// Key of the cell's element, to move focus to it.
  final GlobalNodeKey<web.HTMLElement>? nodeKey;

  @override
  State<StickerCell> createState() => _StickerCellState();
}

final class _StickerCellState extends State<StickerCell> {
  late bool _isHovered;
  late bool _isFocusVisible;
  late bool _isPressed;

  bool get _isHighlighted => _isHovered || _isFocusVisible;

  @override
  void initState() {
    super.initState();
    _isHovered = false;
    _isFocusVisible = false;
    _isPressed = false;
  }

  void _update({bool? hovered, bool? focusVisible, bool? pressed}) {
    final bool wasHighlighted = _isHighlighted;
    final bool wasPressed = _isPressed;
    setState(() {
      _isHovered = hovered ?? _isHovered;
      _isFocusVisible = focusVisible ?? _isFocusVisible;
      _isPressed = pressed ?? _isPressed;
    });
    if (wasHighlighted != _isHighlighted) component.onHighlightChanged(_isHighlighted);
    if (wasPressed != _isPressed) component.onPressedChanged(_isPressed);
  }

  @override
  void didUpdateComponent(StickerCell oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (component.onSelected == null && _isPressed) _update(pressed: false);
  }

  void _onFocus(web.Event event) {
    final web.Element? target = event.currentTarget as web.Element?;
    _update(focusVisible: target?.matches(':focus-visible') ?? true);
  }

  void _onKeyDown(web.Event event) {
    final String key = (event as web.KeyboardEvent).key;
    if (key != 'Enter' && key != ' ') return;
    event.preventDefault();
    component.onSelected?.call();
  }

  @override
  Component build(BuildContext context) {
    final VoidCallback? onSelected = component.onSelected;
    final bool enabled = onSelected != null;
    final bool isPressed = enabled && _isPressed;
    final bool isHighlighted = enabled && _isHighlighted;
    final double size = isPressed
        ? 38
        : isHighlighted
        ? 50
        : 44;
    return div(
      key: component.nodeKey,
      classes: <String>[
        'sticker-cell',
        if (isPressed) 'sticker-cell--pressed' else if (isHighlighted) 'sticker-cell--highlighted',
        if (!enabled) 'sticker-cell--disabled',
      ].join(' '),
      attributes: <String, String>{
        'role': 'button',
        'tabindex': enabled ? '0' : '-1',
        'aria-label': component.stickerId.semanticLabel,
        if (!enabled) 'aria-disabled': 'true',
      },
      events: <String, void Function(web.Event)>{
        'mouseenter': (web.Event _) => _update(hovered: true),
        'mouseleave': (web.Event _) => _update(hovered: false, pressed: false),
        'focus': _onFocus,
        'blur': (web.Event _) => _update(focusVisible: false),
        if (enabled) ...<String, void Function(web.Event)>{
          'pointerdown': (web.Event event) {
            if ((event as web.PointerEvent).button == 0) _update(pressed: true);
          },
          'pointerup': (web.Event _) => _update(pressed: false),
          'pointercancel': (web.Event _) => _update(pressed: false),
          'click': (web.Event _) => onSelected(),
          'keydown': _onKeyDown,
        },
      },
      <Component>[
        span(
          attributes: const <String, String>{'aria-hidden': 'true'},
          <Component>[
            StickerView(stickerId: component.stickerId, size: size, isAnimated: false),
          ],
        ),
      ],
    );
  }
}

@css
List<StyleRule> get stickerCellStyles => <StyleRule>[
  css('.sticker-cell').styles(
    display: Display.flex,
    width: const Unit.pixels(56),
    height: const Unit.pixels(56),
    boxSizing: BoxSizing.borderBox,
    border: Border.all(color: Colors.transparent, width: const Unit.pixels(1)),
    radius: const BorderRadius.circular(Unit.pixels(12)),
    cursor: Cursor.pointer,
    userSelect: UserSelect.none,
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
    flex: const Flex(shrink: 0),
    backgroundColor: Colors.transparent,
    raw: const <String, String>{'-webkit-tap-highlight-color': 'transparent'},
  ),
  // The highlight IS the focus indicator (as in the Paper states).
  css('.sticker-cell:focus-visible').styles(raw: const <String, String>{'outline': 'none'}),
  css('.sticker-cell--highlighted').styles(
    border: Border.all(color: AppColors.primaryLine, width: const Unit.pixels(1)),
    backgroundColor: AppColors.primarySurface,
  ),
  css('.sticker-cell--pressed').styles(
    border: Border.all(color: AppColors.primary, width: const Unit.pixels(1.5)),
    backgroundColor: AppColors.primaryTint,
  ),
  css('.sticker-cell--disabled').styles(cursor: Cursor.defaultCursor),
  css('.sticker-cell > span').styles(display: Display.flex),
];
