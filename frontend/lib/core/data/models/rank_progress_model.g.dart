// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rank_progress_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RankProgressModel _$RankProgressModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RankProgressModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'rankCode',
          'rankName',
          'leagueCode',
          'divisionRpCurrent',
          'divisionRpTarget',
          'floorRating',
          'ceilingExclusive',
        ],
      );
      final val = RankProgressModel(
        rankCode: $checkedConvert('rankCode', (v) => v as String),
        rankName: $checkedConvert('rankName', (v) => v as String),
        leagueCode: $checkedConvert('leagueCode', (v) => v as String),
        divisionRpCurrent: $checkedConvert(
          'divisionRpCurrent',
          (v) => (v as num).toInt(),
        ),
        divisionRpTarget: $checkedConvert(
          'divisionRpTarget',
          (v) => (v as num?)?.toInt(),
        ),
        floorRating: $checkedConvert('floorRating', (v) => (v as num).toInt()),
        ceilingExclusive: $checkedConvert(
          'ceilingExclusive',
          (v) => (v as num?)?.toInt(),
        ),
      );
      return val;
    });
