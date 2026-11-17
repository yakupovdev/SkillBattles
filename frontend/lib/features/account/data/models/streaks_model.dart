import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/account/domain/entity/streaks_entity.dart';

part 'streaks_model.g.dart';

/// Daily and weekly ET streaks.
@JsonSerializable(checked: true, createToJson: false)
final class StreaksModel {
  const StreaksModel({
    required this.timezone,
    required this.dailyCurrent,
    required this.dailyBest,
    required this.lastQualifiedDate,
    required this.weeklyCurrent,
    required this.weeklyBest,
    required this.currentWeekStart,
    required this.currentWeekActiveDays,
    required this.currentWeekTarget,
  });

  factory StreaksModel.fromJson(Map<String, dynamic> json) => _$StreaksModelFromJson(json);

  @JsonKey(required: true)
  final String timezone;

  @JsonKey(required: true)
  final int dailyCurrent;

  @JsonKey(required: true)
  final int dailyBest;

  @JsonKey(required: true)
  final DateTime? lastQualifiedDate;

  @JsonKey(required: true)
  final int weeklyCurrent;

  @JsonKey(required: true)
  final int weeklyBest;

  @JsonKey(required: true)
  final DateTime currentWeekStart;

  @JsonKey(required: true)
  final int currentWeekActiveDays;

  @JsonKey(required: true)
  final int currentWeekTarget;

  StreaksEntity toEntity() => StreaksEntity(
    dailyCurrent: dailyCurrent,
    dailyBest: dailyBest,
    lastQualifiedDate: lastQualifiedDate,
    weeklyCurrent: weeklyCurrent,
    weeklyBest: weeklyBest,
    currentWeekStart: currentWeekStart,
    currentWeekActiveDays: currentWeekActiveDays,
    currentWeekTarget: currentWeekTarget,
  );
}
