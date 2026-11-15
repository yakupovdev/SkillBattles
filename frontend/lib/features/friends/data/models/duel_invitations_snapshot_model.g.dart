// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'duel_invitations_snapshot_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DuelInvitationsSnapshotModel _$DuelInvitationsSnapshotModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DuelInvitationsSnapshotModel', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['data', 'serverTime']);
  final val = DuelInvitationsSnapshotModel(
    data: $checkedConvert(
      'data',
      (v) => (v as List<dynamic>)
          .map((e) => DuelInvitationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    serverTime: $checkedConvert(
      'serverTime',
      (v) => DateTime.parse(v as String),
    ),
  );
  return val;
});
