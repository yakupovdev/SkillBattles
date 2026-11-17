import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/features/battle/presentation/controllers/sticker_compositions.dart';

/// Owns the [StickerCompositions] for the whole app and provides it to the
/// sticker components. Placed once around the router (`SkillBattlesApp`).
///
/// It does not start loading by itself: the signed-in shell
/// ([StickerCompositionsPreload]) and the battle screen call
/// `ensureLoaded`.
final class StickerCompositionsScope extends StatefulComponent {
  const StickerCompositionsScope({required this.child, this.loader, super.key});

  final Component child;

  /// Replaces the asset loader (tests).
  final StickerCompositionLoader? loader;

  /// The compositions above [context], or `null` without a scope. With
  /// [listen] the component rebuilds when loading finishes.
  static StickerCompositions? maybeOf(BuildContext context, {bool listen = true}) {
    if (listen) {
      return context.dependOnInheritedComponentOfExactType<_CompositionsInherited>()?.compositions;
    }
    final _CompositionsInherited? inherited =
        context.getElementForInheritedComponentOfExactType<_CompositionsInherited>()?.component
            as _CompositionsInherited?;
    return inherited?.compositions;
  }

  @override
  State<StickerCompositionsScope> createState() => _StickerCompositionsScopeState();
}

final class _StickerCompositionsScopeState extends State<StickerCompositionsScope> {
  late StickerCompositions _compositions;
  late int _version;

  @override
  void initState() {
    super.initState();
    _version = 0;
    _compositions = StickerCompositions(loader: component.loader)..addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() => _version++);
  }

  @override
  void dispose() {
    _compositions
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return _CompositionsInherited(compositions: _compositions, version: _version, child: component.child);
  }
}

/// Notifies its dependents every time the compositions change (the
/// counterpart of Flutter's `InheritedNotifier`).
final class _CompositionsInherited extends InheritedComponent {
  const _CompositionsInherited({required this.compositions, required this.version, required super.child});

  final StickerCompositions compositions;
  final int version;

  @override
  bool updateShouldNotify(_CompositionsInherited oldComponent) =>
      compositions != oldComponent.compositions || version != oldComponent.version;
}

/// Zero-size component that starts loading the sticker compositions once
/// the signed-in app is on screen, so they are ready before a battle begins.
final class StickerCompositionsPreload extends StatefulComponent {
  const StickerCompositionsPreload({super.key});

  @override
  State<StickerCompositionsPreload> createState() => _StickerCompositionsPreloadState();
}

final class _StickerCompositionsPreloadState extends State<StickerCompositionsPreload> {
  @override
  void initState() {
    super.initState();
    if (kIsWeb) StickerCompositionsScope.maybeOf(context, listen: false)?.ensureLoaded();
  }

  @override
  Component build(BuildContext context) => const Component.empty();
}
