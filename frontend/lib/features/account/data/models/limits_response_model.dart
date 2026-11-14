import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/entitlements_model.dart';
import 'package:skill_battles/core/data/models/plan_code_model.dart';
import 'package:skill_battles/features/account/domain/entity/limits_entity.dart';

part 'limits_response_model.g.dart';

/// Authoritative ET usage and entitlements.
@JsonSerializable(checked: true, createToJson: false)
final class LimitsResponseModel {
  const LimitsResponseModel({
    required this.planCode,
    required this.timezone,
    required this.date,
    required this.freeRankedLimit,
    required this.rankedStartedToday,
    required this.freeRankedRemaining,
    required this.resetsAt,
    required this.canStartRanked,
    required this.entitlements,
  });

  factory LimitsResponseModel.fromJson(Map<String, dynamic> json) =>
      _$LimitsResponseModelFromJson(json);

  @JsonKey(required: true)
  final PlanCodeModel planCode;

  @JsonKey(required: true)
  final String timezone;

  @JsonKey(required: true)
  final DateTime date;

  @JsonKey(required: true)
  final int freeRankedLimit;

  @JsonKey(required: true)
  final int rankedStartedToday;

  @JsonKey(required: true)
  final int? freeRankedRemaining;

  @JsonKey(required: true)
  final DateTime resetsAt;

  @JsonKey(required: true)
  final bool canStartRanked;

  @JsonKey(required: true)
  final EntitlementsModel entitlements;

  LimitsEntity toEntity() => LimitsEntity(
    planCode: planCode.toEntity(),
    date: date,
    freeRankedLimit: freeRankedLimit,
    rankedStartedToday: rankedStartedToday,
    freeRankedRemaining: freeRankedRemaining,
    resetsAt: resetsAt,
    canStartRanked: canStartRanked,
    entitlements: entitlements.toEntity(),
  );
}
