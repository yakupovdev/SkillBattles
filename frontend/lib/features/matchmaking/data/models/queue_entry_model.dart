import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/battle_format_model.dart';
import 'package:skill_battles/core/data/models/error_response_model.dart';
import 'package:skill_battles/features/matchmaking/data/models/queue_status_model.dart';
import 'package:skill_battles/features/matchmaking/domain/entity/queue_entry_entity.dart';

part 'queue_entry_model.g.dart';

/// Ranked queue entry.
@JsonSerializable(checked: true, createToJson: false)
final class QueueEntryModel {
  const QueueEntryModel({
    required this.id,
    required this.disciplineCode,
    required this.format,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.ratingWindow,
    required this.battleId,
    required this.version,
    required this.error,
  });

  factory QueueEntryModel.fromJson(Map<String, dynamic> json) =>
      _$QueueEntryModelFromJson(json);

  @JsonKey(required: true)
  final String id;

  @JsonKey(required: true)
  final String disciplineCode;

  @JsonKey(required: true)
  final BattleFormatModel format;

  @JsonKey(required: true)
  final QueueStatusModel status;

  @JsonKey(required: true)
  final DateTime createdAt;

  @JsonKey(required: true)
  final DateTime expiresAt;

  @JsonKey(required: true)
  final int ratingWindow;

  @JsonKey(required: true)
  final String? battleId;

  @JsonKey(required: true)
  final int version;

  @JsonKey(required: true)
  final ErrorResponseModel? error;

  QueueEntryEntity toEntity() => QueueEntryEntity(
    id: id,
    disciplineCode: disciplineCode,
    status: status.toEntity(),
    createdAt: createdAt,
    expiresAt: expiresAt,
    ratingWindow: ratingWindow,
    battleId: battleId,
    version: version,
    error: error?.toFailure(),
  );
}
