import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/battle_format_model.dart';
import 'package:skill_battles/features/catalog/data/models/difficulty_schedule_model.dart';
import 'package:skill_battles/features/catalog/data/models/difficulty_timing_model.dart';
import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';

part 'battle_mode_model.g.dart';

/// Entry of the dynamic discipline catalogue.
@JsonSerializable(checked: true, createToJson: false)
final class BattleModeModel {
  const BattleModeModel({
    required this.disciplineCode,
    required this.displayName,
    required this.description,
    required this.active,
    required this.format,
    required this.questionType,
    required this.optionsCount,
    required this.questionCount,
    required this.baseQuestionSeconds,
    required this.difficultyTimings,
    required this.difficultySchedules,
    required this.overtimeSeconds,
    required this.readyTimeoutSeconds,
    required this.countdownSeconds,
    required this.revealSeconds,
    required this.reconnectGraceSeconds,
    required this.contentAvailable,
  });

  factory BattleModeModel.fromJson(Map<String, dynamic> json) =>
      _$BattleModeModelFromJson(json);

  @JsonKey(required: true)
  final String disciplineCode;

  @JsonKey(required: true)
  final String displayName;

  @JsonKey(required: true)
  final String description;

  @JsonKey(required: true)
  final bool active;

  @JsonKey(required: true)
  final BattleFormatModel format;

  @JsonKey(required: true)
  final String questionType;

  @JsonKey(required: true)
  final int optionsCount;

  @JsonKey(required: true)
  final int questionCount;

  @JsonKey(required: true)
  final int baseQuestionSeconds;

  @JsonKey(required: true)
  final List<DifficultyTimingModel> difficultyTimings;

  @JsonKey(required: true)
  final List<DifficultyScheduleModel> difficultySchedules;

  @JsonKey(required: true)
  final int overtimeSeconds;

  @JsonKey(required: true)
  final int readyTimeoutSeconds;

  @JsonKey(required: true)
  final int countdownSeconds;

  @JsonKey(required: true)
  final int revealSeconds;

  @JsonKey(required: true)
  final int reconnectGraceSeconds;

  @JsonKey(required: true)
  final bool contentAvailable;

  DisciplineEntity toEntity() => DisciplineEntity(
    code: disciplineCode,
    displayName: displayName,
    description: description,
    questionCount: questionCount,
    baseQuestionSeconds: baseQuestionSeconds,
    timings: difficultyTimings
        .map((DifficultyTimingModel timing) => timing.toEntity())
        .toList(growable: false),
    schedules: difficultySchedules
        .map((DifficultyScheduleModel schedule) => schedule.toEntity())
        .toList(growable: false),
    overtimeSeconds: overtimeSeconds,
    readyTimeoutSeconds: readyTimeoutSeconds,
    countdownSeconds: countdownSeconds,
    revealSeconds: revealSeconds,
    reconnectGraceSeconds: reconnectGraceSeconds,
    contentAvailable: contentAvailable,
  );
}
