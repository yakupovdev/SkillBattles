// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relationship_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RelationshipModel _$RelationshipModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RelationshipModel', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'id',
      'requester',
      'recipient',
      'status',
      'createdAt',
      'updatedAt',
      'acceptedAt',
      'version',
    ],
  );
  final val = RelationshipModel(
    id: $checkedConvert('id', (v) => v as String),
    requester: $checkedConvert(
      'requester',
      (v) => PublicPlayerModel.fromJson(v as Map<String, dynamic>),
    ),
    recipient: $checkedConvert(
      'recipient',
      (v) => PublicPlayerModel.fromJson(v as Map<String, dynamic>),
    ),
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$RelationshipStatusModelEnumMap, v),
    ),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
    updatedAt: $checkedConvert('updatedAt', (v) => DateTime.parse(v as String)),
    acceptedAt: $checkedConvert(
      'acceptedAt',
      (v) => v == null ? null : DateTime.parse(v as String),
    ),
    version: $checkedConvert('version', (v) => (v as num).toInt()),
  );
  return val;
});

const _$RelationshipStatusModelEnumMap = {
  RelationshipStatusModel.pending: 'PENDING',
  RelationshipStatusModel.accepted: 'ACCEPTED',
  RelationshipStatusModel.declined: 'DECLINED',
  RelationshipStatusModel.cancelled: 'CANCELLED',
  RelationshipStatusModel.removed: 'REMOVED',
};
