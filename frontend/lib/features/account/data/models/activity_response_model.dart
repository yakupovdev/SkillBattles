import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/account/data/models/activity_resource_kind_model.dart';
import 'package:skill_battles/features/account/data/models/activity_type_model.dart';
import 'package:skill_battles/features/account/domain/entity/activity_entity.dart';

part 'activity_response_model.g.dart';

/// Own queue/room/non-terminal battle.
@JsonSerializable(checked: true, createToJson: false)
final class ActivityResponseModel {
  const ActivityResponseModel({
    required this.type,
    required this.resourceId,
    required this.battleId,
    required this.resourceKind,
  });

  factory ActivityResponseModel.fromJson(Map<String, dynamic> json) => _$ActivityResponseModelFromJson(json);

  @JsonKey(required: true)
  final ActivityTypeModel type;

  @JsonKey(required: true)
  final String? resourceId;

  @JsonKey(required: true)
  final String? battleId;

  @JsonKey(required: true)
  final ActivityResourceKindModel? resourceKind;

  ActivityEntity toEntity() => ActivityEntity(
    type: type.toEntity(),
    resourceId: resourceId,
    battleId: battleId,
    resourceKind: resourceKind?.toEntity(),
  );
}
