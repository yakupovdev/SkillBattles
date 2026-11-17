import 'dart:async';
import 'package:universal_web/js_interop.dart';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';

/// Modal dialogs and snack bars of the app — the web counterpart of
/// Flutter's `showDialog`, `Navigator.pop` and `ScaffoldMessenger`.
///
/// [AppOverlayHost] is placed once, inside the router (so dialog content
/// can navigate). Like Flutter dialogs, dialog content does NOT see the
/// blocs of the screen that opened it: pass them with
/// `BlocSignalProvider.value`.

/// Opens a modal dialog built by [builder] over a scrim. Completes with the
/// value given to [closeAppDialog], or `null` when dismissed (Esc or a
/// click on the scrim, if [barrierDismissible]).
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required Component Function(BuildContext dialogContext) builder,
  bool barrierDismissible = true,
  Color barrierColor = AppColors.scrim,
}) => _AppOverlayHostState.of(context)._push<T>(
  builder: builder,
  barrierDismissible: barrierDismissible,
  barrierColor: barrierColor,
);

/// Closes the dialog that contains [context] (or the topmost one) with
/// [result] — the counterpart of `Navigator.of(dialogContext).pop(result)`.
void closeAppDialog<T>(BuildContext context, [T? result]) {
  final _DialogEntry? entry = _DialogScope.maybeOf(context)?.entry;
  final _AppOverlayHostState host = _AppOverlayHostState.of(context);
  host._pop(entry ?? host._topmost, result);
}

/// Shows a short floating message at the bottom of the page.
void showAppSnackBar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 4),
}) => _AppOverlayHostState.of(context)._showSnackBar(message, duration);

/// Blocks dismissal by Esc and the scrim while [canDismiss] is false (a
/// request is in flight) — the counterpart of `PopScope(canPop:)`.
final class DialogDismissGuard extends StatefulComponent {
  const DialogDismissGuard({
    required this.canDismiss,
    required this.child,
    super.key,
  });

  final bool canDismiss;
  final Component child;

  @override
  State<DialogDismissGuard> createState() => _DialogDismissGuardState();
}

final class _DialogDismissGuardState extends State<DialogDismissGuard> {
  @override
  void initState() {
    super.initState();
    _apply();
  }

  @override
  void didUpdateComponent(DialogDismissGuard oldComponent) {
    super.didUpdateComponent(oldComponent);
    _apply();
  }

  @override
  void dispose() {
    _DialogScope.maybeOf(context)?.entry.guardBlocks = false;
    super.dispose();
  }

  void _apply() {
    _DialogScope.maybeOf(context)?.entry.guardBlocks = !component.canDismiss;
  }

  @override
  Component build(BuildContext context) => component.child;
}

final class _DialogEntry {
  _DialogEntry({
    required this.id,
    required this.builder,
    required this.barrierDismissible,
    required this.barrierColor,
    required this.completer,
  });

  final int id;
  final Component Function(BuildContext context) builder;
  final bool barrierDismissible;
  final Color barrierColor;
  final Completer<Object?> completer;
  bool guardBlocks = false;

  bool get canDismiss => barrierDismissible && !guardBlocks;
}

final class _SnackEntry {
  _SnackEntry({required this.id, required this.message});

  final int id;
  final String message;
}

final class AppOverlayHost extends StatefulComponent {
  const AppOverlayHost({required this.child, super.key});

  final Component child;

  @override
  State<AppOverlayHost> createState() => _AppOverlayHostState();
}

final class _AppOverlayHostState extends State<AppOverlayHost> {
  late List<_DialogEntry> _dialogs;
  late List<_SnackEntry> _snacks;
  late int _nextId;
  late List<Timer> _timers;
  web.EventListener? _keyListener;

  static _AppOverlayHostState of(BuildContext context) {
    final _OverlayScope? scope =
        context.getElementForInheritedComponentOfExactType<_OverlayScope>()
                ?.component
            as _OverlayScope?;
    if (scope == null) {
      throw StateError('AppOverlayHost is missing above $context.');
    }
    return scope.host;
  }

  _DialogEntry? get _topmost => _dialogs.isEmpty ? null : _dialogs.last;

  @override
  void initState() {
    super.initState();
    _dialogs = <_DialogEntry>[];
    _snacks = <_SnackEntry>[];
    _nextId = 0;
    _timers = <Timer>[];
    if (kIsWeb) {
      _keyListener = _onKeyDown.toJS;
      web.document.addEventListener('keydown', _keyListener);
    }
  }

  @override
  void dispose() {
    final web.EventListener? listener = _keyListener;
    if (listener != null) {
      web.document.removeEventListener('keydown', listener);
    }
    for (final Timer timer in _timers) {
      timer.cancel();
    }
    for (final _DialogEntry entry in _dialogs) {
      if (!entry.completer.isCompleted) entry.completer.complete(null);
    }
    super.dispose();
  }

  void _onKeyDown(web.Event event) {
    if ((event as web.KeyboardEvent).key != 'Escape') return;
    final _DialogEntry? top = _topmost;
    if (top == null || !top.canDismiss) return;
    event.preventDefault();
    _pop(top, null);
  }

  Future<T?> _push<T>({
    required Component Function(BuildContext context) builder,
    required bool barrierDismissible,
    required Color barrierColor,
  }) {
    final Completer<Object?> completer = Completer<Object?>();
    setState(() {
      _dialogs = <_DialogEntry>[
        ..._dialogs,
        _DialogEntry(
          id: _nextId++,
          builder: builder,
          barrierDismissible: barrierDismissible,
          barrierColor: barrierColor,
          completer: completer,
        ),
      ];
    });
    return completer.future.then((Object? value) => value is T ? value : null);
  }

  void _pop(_DialogEntry? entry, Object? result) {
    if (entry == null || !_dialogs.contains(entry)) return;
    setState(() {
      _dialogs = <_DialogEntry>[
        for (final _DialogEntry e in _dialogs)
          if (e != entry) e,
      ];
    });
    if (!entry.completer.isCompleted) entry.completer.complete(result);
  }

  void _showSnackBar(String message, Duration duration) {
    final _SnackEntry entry = _SnackEntry(id: _nextId++, message: message);
    // One message at a time, like ScaffoldMessenger.
    setState(() => _snacks = <_SnackEntry>[entry]);
    late final Timer timer;
    timer = Timer(duration, () {
      _timers.remove(timer);
      if (!mounted) return;
      setState(() {
        _snacks = <_SnackEntry>[
          for (final _SnackEntry e in _snacks)
            if (e != entry) e,
        ];
      });
    });
    _timers.add(timer);
  }

  @override
  Component build(BuildContext context) {
    return _OverlayScope(
      host: this,
      child: Component.fragment(<Component>[
        component.child,
        for (final _DialogEntry entry in _dialogs)
          _DialogScope(
            key: ValueKey<int>(entry.id),
            entry: entry,
            child: div(
              classes: 'app-dialog-barrier',
              styles: Styles(backgroundColor: entry.barrierColor),
              attributes: const <String, String>{'role': 'presentation'},
              events: <String, void Function(web.Event)>{
                'click': (web.Event event) {
                  if (event.target != event.currentTarget) return;
                  if (entry.canDismiss) _pop(entry, null);
                },
              },
              <Component>[
                div(
                  classes: 'app-dialog',
                  attributes: const <String, String>{
                    'role': 'dialog',
                    'aria-modal': 'true',
                  },
                  <Component>[Builder(builder: entry.builder)],
                ),
              ],
            ),
          ),
        if (_snacks.isNotEmpty)
          div(classes: 'app-snackbar-area', <Component>[
            for (final _SnackEntry snack in _snacks)
              div(
                key: ValueKey<int>(snack.id),
                classes: 'app-snackbar',
                attributes: const <String, String>{'role': 'status'},
                <Component>[Component.text(snack.message)],
              ),
          ]),
      ]),
    );
  }
}

final class _OverlayScope extends InheritedComponent {
  const _OverlayScope({required this.host, required super.child});

  final _AppOverlayHostState host;

  @override
  bool updateShouldNotify(_OverlayScope oldComponent) => false;
}

final class _DialogScope extends InheritedComponent {
  const _DialogScope({required this.entry, required super.child, super.key});

  final _DialogEntry entry;

  static _DialogScope? maybeOf(BuildContext context) =>
      context.getElementForInheritedComponentOfExactType<_DialogScope>()
              ?.component
          as _DialogScope?;

  @override
  bool updateShouldNotify(_DialogScope oldComponent) => false;
}

/// Styles of [AppOverlayHost].
@css
List<StyleRule> get appOverlayStyles => <StyleRule>[
  css('.app-dialog-barrier').styles(
    display: Display.flex,
    position: const Position.fixed(
      top: Unit.zero,
      left: Unit.zero,
      right: Unit.zero,
      bottom: Unit.zero,
    ),
    zIndex: const ZIndex(1000),
    padding: const Padding.all(Unit.pixels(24)),
    overflow: Overflow.auto,
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
  ),
  css('.app-dialog').styles(
    maxWidth: const Unit.percent(100),
    maxHeight: const Unit.percent(100),
  ),
  css('.app-snackbar-area').styles(
    display: Display.flex,
    position: const Position.fixed(
      left: Unit.zero,
      right: Unit.zero,
      bottom: Unit.pixels(24),
    ),
    zIndex: const ZIndex(1100),
    justifyContent: JustifyContent.center,
    pointerEvents: PointerEvents.none,
  ),
  css('.app-snackbar')
      .styles(
        width: const Unit.pixels(360),
        maxWidth: const Unit.expression('calc(100vw - 32px)'),
        padding: const Padding.symmetric(
          horizontal: Unit.pixels(16),
          vertical: Unit.pixels(14),
        ),
        boxSizing: BoxSizing.borderBox,
        radius: const BorderRadius.all(Radius.circular(Unit.pixels(10))),
        backgroundColor: AppColors.ink,
        pointerEvents: PointerEvents.auto,
      )
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(color: AppColors.white)),
];
