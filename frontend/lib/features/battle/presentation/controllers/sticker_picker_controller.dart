import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

/// Local UI state of the sticker picker: whether it is open, and the trigger
/// it belongs to (focus target and anchor for the picker's caret).
///
/// Owned by `StickerPickerScope`.
final class StickerPickerController {
  StickerPickerController()
    : isOpen = ValueNotifier<bool>(false),
      triggerKey = GlobalNodeKey<web.HTMLElement>(debugLabel: 'StickerTrigger');

  final ValueNotifier<bool> isOpen;

  /// Key of the element around the trigger: Esc and a send return focus to
  /// the trigger inside it, and the picker's caret points at its centre.
  final GlobalNodeKey<web.HTMLElement> triggerKey;

  void toggle() => isOpen.value = !isOpen.value;

  void open() => isOpen.value = true;

  /// Closes the picker; [returnFocus] puts keyboard focus back on the
  /// trigger (Esc, a send), but not after an outside click.
  void close({bool returnFocus = false}) {
    if (!isOpen.value) return;
    isOpen.value = false;
    if (returnFocus) focusTrigger();
  }

  /// Moves keyboard focus to the trigger button.
  void focusTrigger() {
    final web.HTMLElement? box = triggerKey.currentNode;
    final web.HTMLElement? button = box?.querySelector('[role="button"]') as web.HTMLElement?;
    button?.focus();
  }

  /// Horizontal centre of the trigger in window px; `null` when it is not on
  /// screen.
  double? triggerCenterX() {
    final web.HTMLElement? box = triggerKey.currentNode;
    if (box == null) return null;
    final web.DOMRect rect = box.getBoundingClientRect();
    if (rect.width == 0) return null;
    return rect.left + rect.width / 2;
  }

  void dispose() => isOpen.dispose();
}
