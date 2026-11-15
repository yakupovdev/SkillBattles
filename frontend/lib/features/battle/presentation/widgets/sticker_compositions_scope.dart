import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/features/battle/presentation/controllers/sticker_compositions.dart';

/// Owns the [StickerCompositions] for the whole app and provides it to the
/// sticker widgets. Placed once in `MaterialApp.router(builder:)`.
///
/// It does not start loading by itself: the signed-in shell
/// ([StickerCompositionsPreload]) and the battle screen call
/// `ensureLoaded`.
final class StickerCompositionsScope extends StatefulWidget {
  const StickerCompositionsScope({required this.child, this.loader, super.key});

  final Widget child;

  /// Replaces the asset loader (tests).
  final StickerCompositionLoader? loader;

  /// The compositions above [context], or `null` without a scope. With
  /// [listen] the widget rebuilds when loading finishes.
  static StickerCompositions? maybeOf(
    BuildContext context, {
    bool listen = true,
  }) {
    if (listen) {
      return context
          .dependOnInheritedWidgetOfExactType<_CompositionsInherited>()
          ?.notifier;
    }
    return context
        .getInheritedWidgetOfExactType<_CompositionsInherited>()
        ?.notifier;
  }

  @override
  State<StickerCompositionsScope> createState() =>
      _StickerCompositionsScopeState();
}

final class _StickerCompositionsScopeState
    extends State<StickerCompositionsScope> {
  late StickerCompositions _compositions;

  @override
  void initState() {
    super.initState();
    _compositions = StickerCompositions(loader: widget.loader);
  }

  @override
  void dispose() {
    _compositions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CompositionsInherited(notifier: _compositions, child: widget.child);
  }
}

final class _CompositionsInherited
    extends InheritedNotifier<StickerCompositions> {
  const _CompositionsInherited({required super.child, super.notifier});
}

/// Zero-size widget that starts loading the sticker compositions once the
/// signed-in app is on screen, so they are parsed before a battle begins.
final class StickerCompositionsPreload extends StatefulWidget {
  const StickerCompositionsPreload({super.key});

  @override
  State<StickerCompositionsPreload> createState() =>
      _StickerCompositionsPreloadState();
}

final class _StickerCompositionsPreloadState
    extends State<StickerCompositionsPreload> {
  @override
  void initState() {
    super.initState();
    StickerCompositionsScope.maybeOf(context, listen: false)?.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
