import 'package:skill_battles/core/utils/network/app_api.dart';

/// Resolves an origin-relative media path the server returned (for example
/// `/media/questions/SAT_MATH/3f5a3602/<sha256>.png`) into the absolute URL
/// to load.
///
/// The path is resolved against [origin] when it is set, otherwise against
/// [base] (the page URL on web), so scheme, host, and custom port are kept.
/// It is never appended to `API_BASE_URL`. An already absolute URL is
/// returned as is.
String resolveMediaUrl(
  String path, {
  String origin = AppApi.mediaOrigin,
  Uri? base,
}) {
  final Uri target = Uri.parse(path);
  if (target.hasScheme) return target.toString();
  final Uri root = origin.isEmpty ? (base ?? Uri.base) : Uri.parse(origin);
  return root.resolveUri(target).toString();
}
