import 'dart:async';

import 'package:skill_battles/core/domain/entity/realtime_status.dart';
import 'package:skill_battles/core/utils/realtime/realtime_client.dart';
import 'package:skill_battles/core/utils/realtime/realtime_envelope.dart';
import 'package:skill_battles/core/utils/session/auth_session.dart';
import 'package:skill_battles/core/utils/session/session_tokens.dart';
import 'package:skill_battles/dev/mock_backend.dart';

/// DEVELOPMENT ONLY. Delivers [MockBackend] events as if they came over
/// STOMP; "connected" while signed in.
final class MockRealtimeClient implements RealtimeClient {
  MockRealtimeClient({required this._backend, required this._session});

  final MockBackend _backend;
  final AuthSession _session;
  final StreamController<RealtimeStatus> _statuses =
      StreamController<RealtimeStatus>.broadcast();
  StreamSubscription<SessionTokens?>? _subscription;
  RealtimeStatus _status = RealtimeStatus.disconnected;

  @override
  Stream<RealtimeEnvelope> get events => _backend.events;

  @override
  Stream<RealtimeStatus> get statusChanges => _statuses.stream;

  @override
  RealtimeStatus get status => _status;

  @override
  void start() {
    _subscription ??= _session.changes.listen(
      (SessionTokens? tokens) => _set(
        tokens == null ? RealtimeStatus.disconnected : RealtimeStatus.connected,
      ),
    );
    if (_session.isSignedIn) _set(RealtimeStatus.connected);
  }

  void _set(RealtimeStatus status) {
    if (status == _status) return;
    _status = status;
    _statuses.add(status);
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _statuses.close();
  }
}
