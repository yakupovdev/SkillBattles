import 'package:skill_battles/core/utils/network/app_api.dart';

/// Launch configuration from `--dart-define`s.
///
/// - `API_BASE_URL` — REST base, e.g. `/api/v1` behind the same-origin proxy.
/// - `EVENTS_URL` — STOMP endpoint, e.g. `wss://app.example/ws/v1/events`.
/// - `DEV_MOCKS=true` — run against the in-app development mock backend
///   (clearly labelled; it never replaces an end-to-end check with the real
///   backend).
final class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.eventsUrl,
    required this.useDevMocks,
  });

  factory AppConfig.fromEnvironment() => const AppConfig(
    apiBaseUrl: AppApi.baseUrl,
    eventsUrl: AppApi.eventsUrl,
    useDevMocks: bool.fromEnvironment('DEV_MOCKS'),
  );

  final String apiBaseUrl;
  final String eventsUrl;
  final bool useDevMocks;

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
