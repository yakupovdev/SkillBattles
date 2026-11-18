import 'package:test/test.dart';

import 'package:skill_battles/core/utils/realtime/realtime_envelope.dart';

void main() {
  test('a complete envelope is parsed', () {
    final RealtimeEnvelope? envelope = RealtimeEnvelope.tryParse(
      '{"eventId":"e1","type":"BATTLE_CHANGED","resourceId":"b1",'
      '"version":4,"occurredAt":"2026-11-14T12:00:00Z","data":{"id":"b1"}}',
    );

    expect(envelope, isNotNull);
    expect(envelope!.type, RealtimeEventType.battleChanged);
    expect(envelope.version, 4);
    expect(envelope.data['id'], 'b1');
  });

  test('unknown types, missing fields and bad JSON are ignored', () {
    expect(
      RealtimeEnvelope.tryParse(
        '{"eventId":"e1","type":"SOMETHING","resourceId":"b1","version":1,'
        '"occurredAt":"2026-11-14T12:00:00Z","data":{}}',
      ),
      isNull,
    );
    expect(RealtimeEnvelope.tryParse('{"type":"BATTLE_CHANGED"}'), isNull);
    expect(RealtimeEnvelope.tryParse('not json'), isNull);
    expect(RealtimeEnvelope.tryParse(null), isNull);
  });
}
