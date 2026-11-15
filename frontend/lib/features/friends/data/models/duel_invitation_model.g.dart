// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'duel_invitation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DuelInvitationModel _$DuelInvitationModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DuelInvitationModel', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'id',
      'duelId',
      'host',
      'recipient',
      'disciplineCode',
      'format',
      'status',
      'reason',
      'createdAt',
      'expiresAt',
      'battleId',
      'version',
    ],
  );
  final val = DuelInvitationModel(
    id: $checkedConvert('id', (v) => v as String),
    duelId: $checkedConvert('duelId', (v) => v as String),
    host: $checkedConvert(
      'host',
      (v) => PublicPlayerModel.fromJson(v as Map<String, dynamic>),
    ),
    recipient: $checkedConvert(
      'recipient',
      (v) => PublicPlayerModel.fromJson(v as Map<String, dynamic>),
    ),
    disciplineCode: $checkedConvert('disciplineCode', (v) => v as String),
    format: $checkedConvert(
      'format',
      (v) => $enumDecode(_$BattleFormatModelEnumMap, v),
    ),
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$DuelInvitationStatusModelEnumMap, v),
    ),
    reason: $checkedConvert(
      'reason',
      (v) => $enumDecodeNullable(_$DuelInvitationReasonModelEnumMap, v),
    ),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
    expiresAt: $checkedConvert('expiresAt', (v) => DateTime.parse(v as String)),
    battleId: $checkedConvert('battleId', (v) => v as String?),
    version: $checkedConvert('version', (v) => (v as num).toInt()),
  );
  return val;
});

const _$BattleFormatModelEnumMap = {BattleFormatModel.standard: 'STANDARD'};

const _$DuelInvitationStatusModelEnumMap = {
  DuelInvitationStatusModel.pending: 'PENDING',
  DuelInvitationStatusModel.accepted: 'ACCEPTED',
  DuelInvitationStatusModel.declined: 'DECLINED',
  DuelInvitationStatusModel.cancelled: 'CANCELLED',
  DuelInvitationStatusModel.expired: 'EXPIRED',
};

const _$DuelInvitationReasonModelEnumMap = {
  DuelInvitationReasonModel.senderCancelled: 'SENDER_CANCELLED',
  DuelInvitationReasonModel.duelCancelled: 'DUEL_CANCELLED',
  DuelInvitationReasonModel.duelFilled: 'DUEL_FILLED',
  DuelInvitationReasonModel.friendRemoved: 'FRIEND_REMOVED',
  DuelInvitationReasonModel.invitationExpired: 'INVITATION_EXPIRED',
  DuelInvitationReasonModel.duelExpired: 'DUEL_EXPIRED',
};
