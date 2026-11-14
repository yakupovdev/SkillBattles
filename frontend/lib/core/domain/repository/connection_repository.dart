import 'package:skill_battles/core/domain/entity/realtime_status.dart';

/// State of the personal event stream, so screens can re-read their
/// resource after every reconnect and show a reconnecting hint.
abstract interface class ConnectionRepository {
  RealtimeStatus get status;

  Stream<RealtimeStatus> watchStatus();
}
