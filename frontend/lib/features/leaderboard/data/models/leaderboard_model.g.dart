// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaderboardModel _$LeaderboardModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LeaderboardModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'disciplineCode',
          'season',
          'generatedAt',
          'top',
          'me',
        ],
      );
      final val = LeaderboardModel(
        disciplineCode: $checkedConvert('disciplineCode', (v) => v as String),
        season: $checkedConvert(
          'season',
          (v) => SeasonModel.fromJson(v as Map<String, dynamic>),
        ),
        generatedAt: $checkedConvert(
          'generatedAt',
          (v) => DateTime.parse(v as String),
        ),
        top: $checkedConvert(
          'top',
          (v) => (v as List<dynamic>)
              .map(
                (e) =>
                    LeaderboardEntryModel.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
        me: $checkedConvert(
          'me',
          (v) => v == null
              ? null
              : LeaderboardEntryModel.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });
