// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'season_peak_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SeasonPeakModel _$SeasonPeakModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SeasonPeakModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'season',
          'disciplineCode',
          'peakRating',
          'peakRankCode',
          'finalRating',
        ],
      );
      final val = SeasonPeakModel(
        season: $checkedConvert(
          'season',
          (v) => SeasonModel.fromJson(v as Map<String, dynamic>),
        ),
        disciplineCode: $checkedConvert('disciplineCode', (v) => v as String),
        peakRating: $checkedConvert('peakRating', (v) => (v as num).toInt()),
        peakRankCode: $checkedConvert('peakRankCode', (v) => v as String),
        finalRating: $checkedConvert('finalRating', (v) => (v as num).toInt()),
      );
      return val;
    });
