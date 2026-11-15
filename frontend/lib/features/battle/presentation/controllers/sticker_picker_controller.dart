import 'package:flutter/widgets.dart';

/// Local UI state of the sticker picker: whether it is open, and the trigger
/// it belongs to (focus target and anchor for the picker's caret).
///
/// Owned by `StickerPickerScope`.
final class StickerPickerController {
  StickerPickerController()
    : isOpen = ValueNotifier<bool>(false),
      triggerFocus = FocusNode(debugLabel: 'StickerTrigger'),
      triggerKey = GlobalKey(debugLabel: 'StickerTrigger');

  final ValueNotifier<bool> isOpen;

  /// Focus node of the trigger; Esc and a send return focus here.
  final FocusNode triggerFocus;

  /// Key of the trigger, to measure where the picker's caret points.
  final GlobalKey triggerKey;

  void toggle() => isOpen.value = !isOpen.value;

  void open() => isOpen.value = true;

  /// Closes the picker; [returnFocus] puts keyboard focus back on the
  /// trigger (Esc, a send), but not after an outside click.
  void close({bool returnFocus = false}) {
    if (!isOpen.value) return;
    isOpen.value = false;
    if (returnFocus) triggerFocus.requestFocus();
  }

  void dispose() {
    isOpen.dispose();
    triggerFocus.dispose();
  }
}
