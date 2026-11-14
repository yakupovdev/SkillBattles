// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'battle_player_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BattlePlayerModel _$BattlePlayerModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BattlePlayerModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'nickname',
          'isPro',
          'rating',
          'rankCode',
          'ready',
          'connected',
          'reconnectDeadline',
          'score',
          'correctCount',
          'streak',
          'answeredCurrentRound',
        ],
      );
      final val = BattlePlayerModel(
        id: $checkedConvert('id', (v) => v as String),
        nickname: $checkedConvert('nickname', (v) => v as String),
        isPro: $checkedConvert('isPro', (v) => v as bool),
        rating: $checkedConvert('rating', (v) => (v as num).toInt()),
        rankCode: $checkedConvert('rankCode', (v) => v as String),
        ready: $checkedConvert('ready', (v) => v as bool),
        connected: $checkedConvert('connected', (v) => v as bool),
        reconnectDeadline: $checkedConvert(
          'reconnectDeadline',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
        score: $checkedConvert('score', (v) => (v as num).toInt()),
        correctCount: $checkedConvert(
          'correctCount',
          (v) => (v as num).toInt(),
        ),
        streak: $checkedConvert('streak', (v) => (v as num).toInt()),
        answeredCurrentRound: $checkedConvert(
          'answeredCurrentRound',
          (v) => v as bool,
        ),
      );
      return val;
    });
