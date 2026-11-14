// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HistoryItemModel _$HistoryItemModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('HistoryItemModel', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'battleId',
      'disciplineCode',
      'format',
      'mode',
      'outcome',
      'reason',
      'opponent',
      'myScore',
      'opponentScore',
      'ratingDelta',
      'seasonId',
      'overtimePlayed',
      'createdAt',
      'finishedAt',
    ],
  );
  final val = HistoryItemModel(
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
    outcome: $checkedConvert(
      'outcome',
      (v) => $enumDecode(_$BattleOutcomeModelEnumMap, v),
    ),
    reason: $checkedConvert(
      'reason',
      (v) => $enumDecode(_$BattleReasonModelEnumMap, v),
    ),
    opponent: $checkedConvert(
      'opponent',
      (v) => PublicPlayerModel.fromJson(v as Map<String, dynamic>),
    ),
    myScore: $checkedConvert('myScore', (v) => (v as num).toInt()),
    opponentScore: $checkedConvert('opponentScore', (v) => (v as num).toInt()),
    ratingDelta: $checkedConvert('ratingDelta', (v) => (v as num).toInt()),
    seasonId: $checkedConvert('seasonId', (v) => v as String?),
    overtimePlayed: $checkedConvert('overtimePlayed', (v) => v as bool),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
    finishedAt: $checkedConvert(
      'finishedAt',
      (v) => DateTime.parse(v as String),
    ),
  );
  return val;
});

const _$BattleFormatModelEnumMap = {BattleFormatModel.standard: 'STANDARD'};

const _$CompetitionModeModelEnumMap = {
  CompetitionModeModel.ranked: 'RANKED',
  CompetitionModeModel.private: 'PRIVATE',
};

const _$BattleOutcomeModelEnumMap = {
  BattleOutcomeModel.win: 'WIN',
  BattleOutcomeModel.loss: 'LOSS',
  BattleOutcomeModel.draw: 'DRAW',
  BattleOutcomeModel.cancelled: 'CANCELLED',
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
