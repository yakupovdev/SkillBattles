import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/domain/entity/season_entity.dart';

part 'season_model.g.dart';

/// ET season; boundaries are expressed as UTC.
@JsonSerializable(checked: true, createToJson: false)
final class SeasonModel {
  const SeasonModel({
    required this.id,
    required this.name,
    required this.startsAt,
    required this.endsAt,
    required this.timezone,
  });

  factory SeasonModel.fromJson(Map<String, dynamic> json) =>
      _$SeasonModelFromJson(json);

  @JsonKey(required: true)
  final String id;

  @JsonKey(required: true)
  final String name;

  @JsonKey(required: true)
  final DateTime startsAt;

  @JsonKey(required: true)
  final DateTime endsAt;

  @JsonKey(required: true)
  final String timezone;

  SeasonEntity toEntity() =>
      SeasonEntity(id: id, name: name, startsAt: startsAt, endsAt: endsAt);
}
