// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'battle_snapshot_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BattleSnapshotModel _$BattleSnapshotModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BattleSnapshotModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'disciplineCode',
          'format',
          'mode',
          'rulesVersion',
          'seasonId',
          'phase',
          'version',
          'serverTime',
          'questionCount',
          'overtimePlayed',
          'readyDeadline',
          'countdownEndsAt',
          'nextRoundStartsAt',
          'players',
          'round',
          'result',
          'entitlements',
        ],
      );
      final val = BattleSnapshotModel(
        id: $checkedConvert('id', (v) => v as String),
        disciplineCode: $checkedConvert('disciplineCode', (v) => v as String),
        format: $checkedConvert(
          'format',
          (v) => $enumDecode(_$BattleFormatModelEnumMap, v),
        ),
        mode: $checkedConvert(
          'mode',
          (v) => $enumDecode(_$CompetitionModeModelEnumMap, v),
        ),
        rulesVersion: $checkedConvert('rulesVersion', (v) => v as String),
        seasonId: $checkedConvert('seasonId', (v) => v as String?),
        phase: $checkedConvert(
          'phase',
          (v) => $enumDecode(_$BattlePhaseModelEnumMap, v),
        ),
        version: $checkedConvert('version', (v) => (v as num).toInt()),
        serverTime: $checkedConvert(
          'serverTime',
          (v) => DateTime.parse(v as String),
        ),
        questionCount: $checkedConvert(
          'questionCount',
          (v) => (v as num).toInt(),
        ),
        overtimePlayed: $checkedConvert('overtimePlayed', (v) => v as bool),
        readyDeadline: $checkedConvert(
          'readyDeadline',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
        countdownEndsAt: $checkedConvert(
          'countdownEndsAt',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
        nextRoundStartsAt: $checkedConvert(
          'nextRoundStartsAt',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
        players: $checkedConvert(
          'players',
          (v) => (v as List<dynamic>)
              .map((e) => BattlePlayerModel.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        round: $checkedConvert(
          'round',
          (v) => v == null
              ? null
              : BattleRoundModel.fromJson(v as Map<String, dynamic>),
        ),
        result: $checkedConvert(
          'result',
          (v) => v == null
              ? null
              : BattleResultModel.fromJson(v as Map<String, dynamic>),
        ),
        entitlements: $checkedConvert(
          'entitlements',
          (v) => EntitlementsModel.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

const _$BattleFormatModelEnumMap = {BattleFormatModel.standard: 'STANDARD'};

const _$CompetitionModeModelEnumMap = {
  CompetitionModeModel.ranked: 'RANKED',
  CompetitionModeModel.private: 'PRIVATE',
};

const _$BattlePhaseModelEnumMap = {
  BattlePhaseModel.waitingReady: 'WAITING_READY',
  BattlePhaseModel.countdown: 'COUNTDOWN',
  BattlePhaseModel.question: 'QUESTION',
  BattlePhaseModel.reveal: 'REVEAL',
  BattlePhaseModel.finished: 'FINISHED',
  BattlePhaseModel.cancelled: 'CANCELLED',
};
