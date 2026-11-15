import 'package:equatable/equatable.dart';

import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';

/// One sticker send intent. Keep [submissionId] for an immediate retry of
/// the same intent; a new tap gets a new id.
final class SendStickerParamsEntity extends Equatable {
  const SendStickerParamsEntity({
    required this.battleId,
    required this.stickerId,
    required this.submissionId,
  });

  final String battleId;
  final StickerId stickerId;
  final String submissionId;

  @override
  List<Object?> get props => <Object?>[battleId, stickerId, submissionId];
}
