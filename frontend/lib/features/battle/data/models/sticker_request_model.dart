import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/battle/domain/entity/send_sticker_params_entity.dart';

part 'sticker_request_model.g.dart';

/// Body of POST /battles/{id}/stickers. Nothing else goes in it: the path
/// carries the battle, the JWT the sender.
@JsonSerializable(createFactory: false)
final class StickerRequestModel {
  const StickerRequestModel({
    required this.stickerId,
    required this.submissionId,
  });

  factory StickerRequestModel.fromEntity(SendStickerParamsEntity params) =>
      StickerRequestModel(
        stickerId: params.stickerId.wireId,
        submissionId: params.submissionId,
      );

  /// Exact wire id (`StickerId.wireId`).
  final String stickerId;
  final String submissionId;

  Map<String, dynamic> toJson() => _$StickerRequestModelToJson(this);
}
