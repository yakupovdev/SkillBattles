import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/battle_result/domain/entity/report_entity.dart';

part 'report_response_model.g.dart';

/// Stored question report.
@JsonSerializable(checked: true, createToJson: false)
final class ReportResponseModel {
  const ReportResponseModel({
    required this.id,
    required this.battleId,
    required this.roundId,
    required this.status,
    required this.createdAt,
  });

  factory ReportResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ReportResponseModelFromJson(json);

  @JsonKey(required: true)
  final String id;

  @JsonKey(required: true)
  final String battleId;

  @JsonKey(required: true)
  final String roundId;

  @JsonKey(required: true)
  final String status;

  @JsonKey(required: true)
  final DateTime createdAt;

  ReportEntity toEntity() =>
      ReportEntity(id: id, roundId: roundId, createdAt: createdAt);
}
