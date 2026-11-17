import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

/// Turns the browser's right-click menu off on [child] while it is on
/// screen, so "Inspect", "Print" and "Save as" are not one click away on a
/// page with content that must stay in the app (a live battle round).
///
/// No extra DOM node: the `contextmenu` listener goes on the child's root
/// element, so the menu works again as soon as the child is removed.
final class AppContextMenuBlocker extends StatelessComponent {
  const AppContextMenuBlocker({required this.child, super.key});

  final Component child;

  @override
  Component build(BuildContext context) {
    return Component.wrapElement(
      events: <String, void Function(web.Event)>{'contextmenu': (web.Event event) => event.preventDefault()},
      child: child,
    );
  }
}
