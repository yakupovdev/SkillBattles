import 'package:equatable/equatable.dart';

import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';

/// One BATTLE_STICKER event: a sticker the other participant sent.
final class IncomingStickerEntity extends Equatable {
  const IncomingStickerEntity({
    required this.eventId,
    required this.sequence,
    required this.battleId,
    required this.submissionId,
    required this.senderUserId,
    required this.stickerId,
    required this.sentAt,
  });

  final String eventId;

  /// The envelope `version`: a per-battle sticker sequence, independent of
  /// the battle version. Gaps are normal; it restarts with the backend.
  final int sequence;
  final String battleId;
  final String submissionId;
  final String senderUserId;

  /// [StickerId.unknown] for an id this client does not know.
  final StickerId stickerId;

  /// Server acceptance instant.
  final DateTime sentAt;

  @override
  List<Object?> get props => <Object?>[
    eventId,
    sequence,
    battleId,
    submissionId,
    senderUserId,
    stickerId,
    sentAt,
  ];
}
