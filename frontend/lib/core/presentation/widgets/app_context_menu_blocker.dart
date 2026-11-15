import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Turns the browser's right-click menu off while [child] is on screen (web
/// only; other platforms have no such menu), so "Inspect", "Print" and "Save
/// as" are not one click away on a page with content that must stay in the
/// app (a live battle round). Restores the menu when it is removed, unless it
/// was already off before.
final class AppContextMenuBlocker extends StatefulWidget {
  const AppContextMenuBlocker({required this.child, super.key});

  final Widget child;

  @override
  State<AppContextMenuBlocker> createState() => _AppContextMenuBlockerState();
}

final class _AppContextMenuBlockerState extends State<AppContextMenuBlocker> {
  late bool _restoreOnDispose;

  @override
  void initState() {
    super.initState();
    _restoreOnDispose = kIsWeb && BrowserContextMenu.enabled;
    if (_restoreOnDispose) unawaited(BrowserContextMenu.disableContextMenu());
  }

  @override
  void dispose() {
    if (_restoreOnDispose) unawaited(BrowserContextMenu.enableContextMenu());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
