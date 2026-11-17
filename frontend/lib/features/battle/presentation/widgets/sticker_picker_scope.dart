import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/features/battle/presentation/controllers/sticker_picker_controller.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_compositions_scope.dart';

/// Owns the [StickerPickerController] of one battle screen so the trigger
/// (in the header) and the picker (in the overlay) share it. Also makes sure
/// the sticker compositions are loading.
final class StickerPickerScope extends StatefulComponent {
  const StickerPickerScope({required this.child, super.key});

  final Component child;

  /// The controller above [context]; it is a stable object, so asking for it
  /// never rebuilds the caller.
  static StickerPickerController? maybeOf(BuildContext context) {
    final _PickerInherited? inherited =
        context.getElementForInheritedComponentOfExactType<_PickerInherited>()?.component as _PickerInherited?;
    return inherited?.controller;
  }

  @override
  State<StickerPickerScope> createState() => _StickerPickerScopeState();
}

final class _StickerPickerScopeState extends State<StickerPickerScope> {
  late StickerPickerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = StickerPickerController();
    if (kIsWeb) StickerCompositionsScope.maybeOf(context, listen: false)?.ensureLoaded();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return _PickerInherited(controller: _controller, child: component.child);
  }
}

final class _PickerInherited extends InheritedComponent {
  const _PickerInherited({required this.controller, required super.child});

  final StickerPickerController controller;

  @override
  bool updateShouldNotify(_PickerInherited oldComponent) => controller != oldComponent.controller;
}
