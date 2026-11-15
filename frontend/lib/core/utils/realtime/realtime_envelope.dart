import 'dart:convert';

/// Type of a personal realtime notification.
enum RealtimeEventType {
  queueChanged('QUEUE_CHANGED'),
  privateDuelChanged('PRIVATE_DUEL_CHANGED'),
  battleChanged('BATTLE_CHANGED'),
  rematchChanged('REMATCH_CHANGED'),
  accountChanged('ACCOUNT_CHANGED'),
  seasonChanged('SEASON_CHANGED'),
  friendshipChanged('FRIENDSHIP_CHANGED'),
  duelInvitationChanged('DUEL_INVITATION_CHANGED'),
  battleSticker('BATTLE_STICKER');

  const RealtimeEventType(this.wireName);

  final String wireName;

  static RealtimeEventType? fromWire(Object? value) {
    for (final RealtimeEventType type in values) {
      if (type.wireName == value) return type;
    }
    return null;
  }
}

/// Envelope of one STOMP MESSAGE. Events are short-lived notifications (may
/// be duplicated or lost); [version] is monotonic per [type] + [resourceId]
/// and must never be compared across resources.
final class RealtimeEnvelope {
  const RealtimeEnvelope({
    required this.eventId,
    required this.type,
    required this.resourceId,
    required this.version,
    required this.occurredAt,
    required this.data,
  });

  final String eventId;
  final RealtimeEventType type;

  /// Game resource UUID; user id for ACCOUNT_CHANGED; season code for
  /// SEASON_CHANGED; relationship id for FRIENDSHIP_CHANGED; invitation id
  /// for DUEL_INVITATION_CHANGED; battle id for BATTLE_STICKER (whose
  /// [version] is the battle's sticker sequence, not the battle version).
  final String resourceId;
  final int version;
  final DateTime occurredAt;

  /// The full personalised DTO of the event; parsed by the repository that
  /// owns the resource.
  final Map<String, dynamic> data;

  /// `null` for a body that is not a known, complete envelope.
  static RealtimeEnvelope? tryParse(String? body) {
    if (body == null || body.isEmpty) return null;
    final Object? json;
    try {
      json = jsonDecode(body);
    } on FormatException {
      return null;
    }
    if (json is! Map<String, dynamic>) return null;
    final RealtimeEventType? type = RealtimeEventType.fromWire(json['type']);
    final Object? eventId = json['eventId'];
    final Object? resourceId = json['resourceId'];
    final Object? version = json['version'];
    final Object? occurredAt = json['occurredAt'];
    final Object? data = json['data'];
    if (type == null ||
        eventId is! String ||
        resourceId is! String ||
        version is! int ||
        occurredAt is! String ||
        data is! Map<String, dynamic>) {
      return null;
    }
    final DateTime? occurred = DateTime.tryParse(occurredAt);
    if (occurred == null) return null;
    return RealtimeEnvelope(
      eventId: eventId,
      type: type,
      resourceId: resourceId,
      version: version,
      occurredAt: occurred,
      data: data,
    );
  }
}
