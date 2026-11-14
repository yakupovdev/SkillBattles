import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/subscription/domain/entity/plan_interval.dart';

/// Billing interval.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum PlanIntervalModel {
  none,
  month,
  year;

  PlanInterval toEntity() => switch (this) {
    PlanIntervalModel.none => PlanInterval.none,
    PlanIntervalModel.month => PlanInterval.month,
    PlanIntervalModel.year => PlanInterval.year,
  };
}
