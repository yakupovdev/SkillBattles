import 'package:equatable/equatable.dart';

import 'package:skill_battles/features/catalog/domain/entity/difficulty_schedule_entity.dart';
import 'package:skill_battles/features/catalog/domain/entity/difficulty_timing_entity.dart';

/// An active entry of `GET /battle-modes`. Codes are data (`SAT_MATH`,
/// `SAT_RW`, …), never a client enum; every single-choice discipline uses the
/// same battle renderer.
final class DisciplineEntity extends Equatable {
  const DisciplineEntity({
    required this.code,
    required this.displayName,
    required this.description,
    required this.questionCount,
    required this.baseQuestionSeconds,
    required this.timings,
    required this.schedules,
    required this.overtimeSeconds,
    required this.readyTimeoutSeconds,
    required this.countdownSeconds,
    required this.revealSeconds,
    required this.reconnectGraceSeconds,
    required this.contentAvailable,
  });

  final String code;
  final String displayName;
  final String description;

  /// Main rounds; a possible overtime round comes on top.
  final int questionCount;
  final int baseQuestionSeconds;
  final List<DifficultyTimingEntity> timings;
  final List<DifficultyScheduleEntity> schedules;
  final int overtimeSeconds;
  final int readyTimeoutSeconds;
  final int countdownSeconds;
  final int revealSeconds;
  final int reconnectGraceSeconds;
  final bool contentAvailable;

  int get minLimitSeconds => timings.isEmpty
      ? baseQuestionSeconds
      : timings
            .map((DifficultyTimingEntity t) => t.limitSeconds)
            .reduce((int a, int b) => a < b ? a : b);

  int get maxLimitSeconds => timings.isEmpty
      ? baseQuestionSeconds
      : timings
            .map((DifficultyTimingEntity t) => t.limitSeconds)
            .reduce((int a, int b) => a > b ? a : b);

  @override
  List<Object?> get props => <Object?>[
    code,
    displayName,
    description,
    questionCount,
    baseQuestionSeconds,
    timings,
    schedules,
    overtimeSeconds,
    readyTimeoutSeconds,
    countdownSeconds,
    revealSeconds,
    reconnectGraceSeconds,
    contentAvailable,
  ];
}
