import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

/// Whether the visitor asked the system for less motion
/// (`prefers-reduced-motion: reduce`). Always `false` on the server.
bool prefersReducedMotion() => kIsWeb && web.window.matchMedia('(prefers-reduced-motion: reduce)').matches;
