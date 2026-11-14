import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/domain/entity/plan_code.dart';

/// Subscription plan code.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum PlanCodeModel {
  free,
  proMonthly,
  proAnnual;

  PlanCode toEntity() => switch (this) {
    PlanCodeModel.free => PlanCode.free,
    PlanCodeModel.proMonthly => PlanCode.proMonthly,
    PlanCodeModel.proAnnual => PlanCode.proAnnual,
  };

  static PlanCodeModel fromEntity(PlanCode code) => switch (code) {
    PlanCode.free => PlanCodeModel.free,
    PlanCode.proMonthly => PlanCodeModel.proMonthly,
    PlanCode.proAnnual => PlanCodeModel.proAnnual,
  };
}
