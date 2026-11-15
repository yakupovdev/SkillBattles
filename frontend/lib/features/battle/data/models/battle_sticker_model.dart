import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/battle/domain/entity/incoming_sticker_entity.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';

part 'battle_sticker_model.g.dart';

/// `data` of a BATTLE_STICKER event (`BattleStickerData`).
@JsonSerializable(checked: true, createToJson: false)
final class BattleStickerModel {
  const BattleStickerModel({
    required this.battleId,
    required this.submissionId,
    required this.senderUserId,
    required this.stickerId,
    required this.sentAt,
  });

  factory BattleStickerModel.fromJson(Map<String, dynamic> json) =>
      _$BattleStickerModelFromJson(json);

  @JsonKey(required: true)
  final String battleId;

  @JsonKey(required: true)
  final String submissionId;

  @JsonKey(required: true)
  final String senderUserId;

  /// Deliberately a plain string, not a closed enum: an id a newer backend
  /// knows maps to [StickerId.unknown] instead of failing the event.
  @JsonKey(required: true)
  final String stickerId;

  @JsonKey(required: true)
  final DateTime sentAt;

  /// [eventId] and [sequence] (the envelope `version`) come from the
  /// envelope around this payload.
  IncomingStickerEntity toEntity({
    required String eventId,
    required int sequence,
  }) => IncomingStickerEntity(
    eventId: eventId,
    sequence: sequence,
    battleId: battleId,
    submissionId: submissionId,
    senderUserId: senderUserId,
    stickerId: StickerId.fromWire(stickerId),
    sentAt: sentAt,
  );
}
