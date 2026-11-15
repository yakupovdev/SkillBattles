// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calibration_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalibrationModel _$CalibrationModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CalibrationModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'completedMatches',
          'matchesRemaining',
          'isCalibrating',
          'nextKFactor',
        ],
      );
      final val = CalibrationModel(
        completedMatches: $checkedConvert(
          'completedMatches',
          (v) => (v as num).toInt(),
        ),
        matchesRemaining: $checkedConvert(
          'matchesRemaining',
          (v) => (v as num).toInt(),
        ),
        isCalibrating: $checkedConvert('isCalibrating', (v) => v as bool),
        nextKFactor: $checkedConvert('nextKFactor', (v) => (v as num).toInt()),
      );
      return val;
    });
