// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rank_tier_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RankTierModel _$RankTierModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RankTierModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'code',
          'displayName',
          'leagueCode',
          'floorRating',
          'ceilingExclusive',
          'divisionNumber',
        ],
      );
      final val = RankTierModel(
        code: $checkedConvert('code', (v) => v as String),
        displayName: $checkedConvert('displayName', (v) => v as String),
        leagueCode: $checkedConvert('leagueCode', (v) => v as String),
        floorRating: $checkedConvert('floorRating', (v) => (v as num).toInt()),
        ceilingExclusive: $checkedConvert(
          'ceilingExclusive',
          (v) => (v as num?)?.toInt(),
        ),
        divisionNumber: $checkedConvert(
          'divisionNumber',
          (v) => (v as num?)?.toInt(),
        ),
      );
      return val;
    });
