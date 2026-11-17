import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/app/router/app_navigation.dart';

/// Opens a provider page (Stripe Checkout or Portal) in this tab, so the
/// provider returns to the app. In-app paths (development mocks) are routed
/// directly. Only https pages leave the app.
///
/// Completes with `true` when the navigation started, `false` when [url]
/// is neither an in-app path nor an https address.
Future<bool> openExternalUrl(BuildContext context, String url) async {
  if (url.startsWith('/') && !url.startsWith('//')) {
    context.go(url);
    return true;
  }
  final Uri? uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return false;
  web.window.location.assign(uri.toString());
  return true;
}
