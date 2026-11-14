import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a provider page (Stripe Checkout or Portal) in this tab, so the
/// provider returns to the app. In-app paths (development mocks) are routed
/// directly. Only https pages leave the app.
Future<bool> openExternalUrl(BuildContext context, String url) async {
  if (url.startsWith('/')) {
    context.go(url);
    return true;
  }
  final Uri? uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https') return false;
  return launchUrl(uri, webOnlyWindowName: '_self');
}
