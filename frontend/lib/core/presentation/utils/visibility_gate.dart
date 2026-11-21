import 'package:universal_web/js_interop.dart';
import 'package:universal_web/web.dart' as web;

/// Tells whether an element is on screen AND the browser tab is visible.
///
/// Built on an `IntersectionObserver` (the element counts as visible once at
/// least [threshold] of it is inside the viewport, clipped by scrolling
/// ancestors too) and on the document's `visibilitychange` event. Use it to
/// run timers and animations only while the user can see them.
///
/// Browser only: create and [attach] it after the first frame, never on the
/// server. [dispose] disconnects the observer and removes the listener.
final class VisibilityGate {
  VisibilityGate({required this.threshold, required this.onChanged}) {
    _isIntersecting = false;
    _isDocumentVisible = web.document.visibilityState == 'visible';
    _isActive = false;
    _documentListener = _onDocumentVisibility.toJS;
    web.document.addEventListener('visibilitychange', _documentListener);
  }

  /// Share of the element (0..1) that must be visible.
  final double threshold;

  /// Called whenever [isActive] changes.
  final void Function(bool isActive) onChanged;

  late bool _isIntersecting;
  late bool _isDocumentVisible;
  late bool _isActive;
  late JSFunction _documentListener;
  web.IntersectionObserver? _observer;

  /// The element is visible enough and the tab is visible.
  bool get isActive => _isActive;

  /// Starts watching [element]. Returns `false` when the browser has no
  /// `IntersectionObserver`; the caller then shows its final state.
  bool attach(web.Element element) {
    _observer?.disconnect();
    try {
      final web.IntersectionObserver observer = web.IntersectionObserver(
        ((JSArray<web.IntersectionObserverEntry> entries, web.IntersectionObserver observer) {
          final List<web.IntersectionObserverEntry> list = entries.toDart;
          if (list.isEmpty) return;
          final web.IntersectionObserverEntry last = list.last;
          _isIntersecting = last.isIntersecting && last.intersectionRatio >= threshold - 0.01;
          _update();
        }).toJS,
        web.IntersectionObserverInit(threshold: threshold.toJS),
      );
      observer.observe(element);
      _observer = observer;
      return true;
    } on Object {
      return false;
    }
  }

  void _onDocumentVisibility(web.Event event) {
    _isDocumentVisible = web.document.visibilityState == 'visible';
    _update();
  }

  void _update() {
    final bool next = _isIntersecting && _isDocumentVisible;
    if (next == _isActive) return;
    _isActive = next;
    onChanged(next);
  }

  void dispose() {
    _observer?.disconnect();
    _observer = null;
    web.document.removeEventListener('visibilitychange', _documentListener);
  }
}
