import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/domain/entity/calibration_entity.dart';

part 'calibration_model.g.dart';

/// Calibration state of a discipline rating.
@JsonSerializable(checked: true, createToJson: false)
final class CalibrationModel {
  const CalibrationModel({
    required this.completedMatches,
    required this.matchesRemaining,
    required this.isCalibrating,
    required this.nextKFactor,
  });

  factory CalibrationModel.fromJson(Map<String, dynamic> json) =>
      _$CalibrationModelFromJson(json);

  @JsonKey(required: true)
  final int completedMatches;

  @JsonKey(required: true)
  final int matchesRemaining;

  @JsonKey(required: true)
  final bool isCalibrating;

  @JsonKey(required: true)
  final int nextKFactor;

  CalibrationEntity toEntity() => CalibrationEntity(
    completedMatches: completedMatches,
    matchesRemaining: matchesRemaining,
    isCalibrating: isCalibrating,
    nextKFactor: nextKFactor,
  );
}
