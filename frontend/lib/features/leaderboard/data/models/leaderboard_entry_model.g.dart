// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard_entry_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaderboardEntryModel _$LeaderboardEntryModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('LeaderboardEntryModel', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'position',
      'player',
      'rating',
      'rankCode',
      'isCalibrating',
    ],
  );
  final val = LeaderboardEntryModel(
    position: $checkedConvert('position', (v) => (v as num).toInt()),
    player: $checkedConvert(
      'player',
      (v) => PublicPlayerModel.fromJson(v as Map<String, dynamic>),
    ),
    rating: $checkedConvert('rating', (v) => (v as num).toInt()),
    rankCode: $checkedConvert('rankCode', (v) => v as String),
    isCalibrating: $checkedConvert('isCalibrating', (v) => v as bool),
  );
  return val;
});
