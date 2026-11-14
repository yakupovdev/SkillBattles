// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_stats_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchStatsModel _$MatchStatsModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('MatchStatsModel', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'wins',
      'losses',
      'draws',
      'played',
      'winRatePercent',
      'currentWinStreak',
      'bestWinStreak',
      'accuracyPercent',
      'avgAnswerTimeMs',
      'questionCount',
    ],
  );
  final val = MatchStatsModel(
    wins: $checkedConvert('wins', (v) => (v as num).toInt()),
    losses: $checkedConvert('losses', (v) => (v as num).toInt()),
    draws: $checkedConvert('draws', (v) => (v as num).toInt()),
    played: $checkedConvert('played', (v) => (v as num).toInt()),
    winRatePercent: $checkedConvert(
      'winRatePercent',
      (v) => (v as num?)?.toDouble(),
    ),
    currentWinStreak: $checkedConvert(
      'currentWinStreak',
      (v) => (v as num).toInt(),
    ),
    bestWinStreak: $checkedConvert('bestWinStreak', (v) => (v as num).toInt()),
    accuracyPercent: $checkedConvert(
      'accuracyPercent',
      (v) => (v as num?)?.toDouble(),
    ),
    avgAnswerTimeMs: $checkedConvert(
      'avgAnswerTimeMs',
      (v) => (v as num?)?.toInt(),
    ),
    questionCount: $checkedConvert('questionCount', (v) => (v as num).toInt()),
  );
  return val;
});
