import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/battle_result/data/models/rematch_status_model.dart';
import 'package:skill_battles/features/battle_result/domain/entity/rematch_entity.dart';

part 'rematch_model.g.dart';

/// Rematch consent state.
@JsonSerializable(checked: true, createToJson: false)
final class RematchModel {
  const RematchModel({
    required this.sourceBattleId,
    required this.status,
    required this.requestedBy,
    required this.expiresAt,
    required this.battleId,
    required this.version,
  });

  factory RematchModel.fromJson(Map<String, dynamic> json) =>
      _$RematchModelFromJson(json);

  @JsonKey(required: true)
  final String sourceBattleId;

  @JsonKey(required: true)
  final RematchStatusModel status;

  @JsonKey(required: true)
  final List<String> requestedBy;

  @JsonKey(required: true)
  final DateTime expiresAt;

  @JsonKey(required: true)
  final String? battleId;

  @JsonKey(required: true)
  final int version;

  RematchEntity toEntity() => RematchEntity(
    sourceBattleId: sourceBattleId,
    status: status.toEntity(),
    requestedBy: List<String>.unmodifiable(requestedBy),
    expiresAt: expiresAt,
    battleId: battleId,
    version: version,
  );
}
