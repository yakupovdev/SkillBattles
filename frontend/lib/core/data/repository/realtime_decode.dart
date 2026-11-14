import 'dart:developer' as developer;

import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/utils/realtime/realtime_envelope.dart';

/// Filters [events] to [type] (and [resourceId] when given) and parses the
/// payload; malformed payloads are logged and skipped.
Stream<T> decodeRealtime<T>(
  Stream<RealtimeEnvelope> events, {
  required RealtimeEventType type,
  required T Function(Map<String, dynamic> data) parse,
  bool Function(RealtimeEnvelope event)? where,
}) {
  return events
      .where(
        (RealtimeEnvelope event) =>
            event.type == type && (where == null || where(event)),
      )
      .expand((RealtimeEnvelope event) {
        try {
          return <T>[parse(event.data)];
        } on CheckedFromJsonException catch (error) {
          developer.log(
            'Malformed ${type.wireName} (${error.className}.${error.key})',
            name: 'realtime',
          );
          return <T>[];
        }
      });
}
