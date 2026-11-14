// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'battle_result_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BattleResultModel _$BattleResultModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BattleResultModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'battleId',
          'disciplineCode',
          'format',
          'mode',
          'seasonId',
          'rulesVersion',
          'status',
          'reason',
          'winnerUserId',
          'myOutcome',
          'finishedAt',
          'overtimePlayed',
          'players',
        ],
      );
      final val = BattleResultModel(
        battleId: $checkedConvert('battleId', (v) => v as String),
        disciplineCode: $checkedConvert('disciplineCode', (v) => v as String),
        format: $checkedConvert(
          'format',
          (v) => $enumDecode(_$BattleFormatModelEnumMap, v),
        ),
        mode: $checkedConvert(
          'mode',
          (v) => $enumDecode(_$CompetitionModeModelEnumMap, v),
        ),
        seasonId: $checkedConvert('seasonId', (v) => v as String?),
        rulesVersion: $checkedConvert('rulesVersion', (v) => v as String),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$BattleStatusModelEnumMap, v),
        ),
        reason: $checkedConvert(
          'reason',
          (v) => $enumDecode(_$BattleReasonModelEnumMap, v),
        ),
        winnerUserId: $checkedConvert('winnerUserId', (v) => v as String?),
        myOutcome: $checkedConvert(
          'myOutcome',
          (v) => $enumDecode(_$BattleOutcomeModelEnumMap, v),
        ),
        finishedAt: $checkedConvert(
          'finishedAt',
          (v) => DateTime.parse(v as String),
        ),
        overtimePlayed: $checkedConvert('overtimePlayed', (v) => v as bool),
        players: $checkedConvert(
          'players',
          (v) => (v as List<dynamic>)
              .map((e) => ResultPlayerModel.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

const _$BattleFormatModelEnumMap = {BattleFormatModel.standard: 'STANDARD'};

const _$CompetitionModeModelEnumMap = {
  CompetitionModeModel.ranked: 'RANKED',
  CompetitionModeModel.private: 'PRIVATE',
};

const _$BattleStatusModelEnumMap = {
  BattleStatusModel.finished: 'FINISHED',
  BattleStatusModel.cancelled: 'CANCELLED',
};

const _$BattleReasonModelEnumMap = {
  BattleReasonModel.normal: 'NORMAL',
  BattleReasonModel.overtimeWin: 'OVERTIME_WIN',
  BattleReasonModel.surrender: 'SURRENDER',
  BattleReasonModel.disconnect: 'DISCONNECT',
  BattleReasonModel.readyTimeout: 'READY_TIMEOUT',
  BattleReasonModel.bothDisconnected: 'BOTH_DISCONNECTED',
  BattleReasonModel.serverInterruption: 'SERVER_INTERRUPTION',
  BattleReasonModel.quotaExhausted: 'QUOTA_EXHAUSTED',
};

const _$BattleOutcomeModelEnumMap = {
  BattleOutcomeModel.win: 'WIN',
  BattleOutcomeModel.loss: 'LOSS',
  BattleOutcomeModel.draw: 'DRAW',
  BattleOutcomeModel.cancelled: 'CANCELLED',
};
