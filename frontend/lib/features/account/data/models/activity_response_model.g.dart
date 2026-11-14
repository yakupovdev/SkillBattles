// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActivityResponseModel _$ActivityResponseModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ActivityResponseModel', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['type', 'resourceId', 'battleId', 'resourceKind'],
  );
  final val = ActivityResponseModel(
    type: $checkedConvert(
      'type',
      (v) => $enumDecode(_$ActivityTypeModelEnumMap, v),
    ),
    resourceId: $checkedConvert('resourceId', (v) => v as String?),
    battleId: $checkedConvert('battleId', (v) => v as String?),
    resourceKind: $checkedConvert(
      'resourceKind',
      (v) => $enumDecodeNullable(_$ActivityResourceKindModelEnumMap, v),
    ),
  );
  return val;
});

const _$ActivityTypeModelEnumMap = {
  ActivityTypeModel.none: 'NONE',
  ActivityTypeModel.queue: 'QUEUE',
  ActivityTypeModel.privateDuel: 'PRIVATE_DUEL',
  ActivityTypeModel.battle: 'BATTLE',
};

const _$ActivityResourceKindModelEnumMap = {
  ActivityResourceKindModel.queueEntry: 'QUEUE_ENTRY',
  ActivityResourceKindModel.duel: 'DUEL',
  ActivityResourceKindModel.rematch: 'REMATCH',
  ActivityResourceKindModel.battle: 'BATTLE',
};
