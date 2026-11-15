import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_receipt_entity.dart';

part 'sticker_receipt_model.g.dart';

/// Receipt of an accepted sticker send (`StickerSendResponse`).
@JsonSerializable(checked: true, createToJson: false)
final class StickerReceiptModel {
  const StickerReceiptModel({
    required this.battleId,
    required this.submissionId,
    required this.senderUserId,
    required this.stickerId,
    required this.sentAt,
    required this.nextAllowedAt,
  });

  factory StickerReceiptModel.fromJson(Map<String, dynamic> json) =>
      _$StickerReceiptModelFromJson(json);

  @JsonKey(required: true)
  final String battleId;

  @JsonKey(required: true)
  final String submissionId;

  @JsonKey(required: true)
  final String senderUserId;

  /// Wire id as sent by the server; mapped with [StickerId.fromWire].
  @JsonKey(required: true)
  final String stickerId;

  @JsonKey(required: true)
  final DateTime sentAt;

  @JsonKey(required: true)
  final DateTime nextAllowedAt;

  StickerReceiptEntity toEntity() => StickerReceiptEntity(
    battleId: battleId,
    submissionId: submissionId,
    senderUserId: senderUserId,
    stickerId: StickerId.fromWire(stickerId),
    sentAt: sentAt,
    nextAllowedAt: nextAllowedAt,
  );
}
