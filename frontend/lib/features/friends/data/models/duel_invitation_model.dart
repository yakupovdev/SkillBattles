import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/battle_format_model.dart';
import 'package:skill_battles/core/data/models/public_player_model.dart';
import 'package:skill_battles/features/friends/data/models/duel_invitation_reason_model.dart';
import 'package:skill_battles/features/friends/data/models/duel_invitation_status_model.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_entity.dart';

part 'duel_invitation_model.g.dart';

/// DuelInvitationResponse.
@JsonSerializable(checked: true, createToJson: false)
final class DuelInvitationModel {
  const DuelInvitationModel({
    required this.id,
    required this.duelId,
    required this.host,
    required this.recipient,
    required this.disciplineCode,
    required this.format,
    required this.status,
    required this.reason,
    required this.createdAt,
    required this.expiresAt,
    required this.battleId,
    required this.version,
  });

  factory DuelInvitationModel.fromJson(Map<String, dynamic> json) =>
      _$DuelInvitationModelFromJson(json);

  @JsonKey(required: true)
  final String id;

  @JsonKey(required: true)
  final String duelId;

  @JsonKey(required: true)
  final PublicPlayerModel host;

  @JsonKey(required: true)
  final PublicPlayerModel recipient;

  @JsonKey(required: true)
  final String disciplineCode;

  @JsonKey(required: true)
  final BattleFormatModel format;

  @JsonKey(required: true)
  final DuelInvitationStatusModel status;

  @JsonKey(required: true)
  final DuelInvitationReasonModel? reason;

  @JsonKey(required: true)
  final DateTime createdAt;

  @JsonKey(required: true)
  final DateTime expiresAt;

  @JsonKey(required: true)
  final String? battleId;

  @JsonKey(required: true)
  final int version;

  /// [viewerId] is the signed-in user; it decides [DuelInvitationEntity.isIncoming].
  DuelInvitationEntity toEntity({required String viewerId}) =>
      DuelInvitationEntity(
        id: id,
        duelId: duelId,
        host: host.toEntity(),
        recipient: recipient.toEntity(),
        disciplineCode: disciplineCode,
        status: status.toEntity(),
        reason: reason?.toEntity(),
        createdAt: createdAt,
        expiresAt: expiresAt,
        battleId: battleId,
        version: version,
        isIncoming: recipient.id == viewerId,
      );
}
