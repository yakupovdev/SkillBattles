import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/entitlements_model.dart';
import 'package:skill_battles/features/account/data/models/discipline_stats_model.dart';
import 'package:skill_battles/features/account/data/models/streaks_model.dart';
import 'package:skill_battles/features/account/domain/entity/statistics_entity.dart';

part 'statistics_response_model.g.dart';

/// Full statistics of the account.
@JsonSerializable(checked: true, createToJson: false)
final class StatisticsResponseModel {
  const StatisticsResponseModel({
    required this.entitlements,
    required this.streaks,
    required this.disciplines,
  });

  factory StatisticsResponseModel.fromJson(Map<String, dynamic> json) => _$StatisticsResponseModelFromJson(json);

  @JsonKey(required: true)
  final EntitlementsModel entitlements;

  @JsonKey(required: true)
  final StreaksModel streaks;

  @JsonKey(required: true)
  final List<DisciplineStatsModel> disciplines;

  StatisticsEntity toEntity() => StatisticsEntity(
    entitlements: entitlements.toEntity(),
    streaks: streaks.toEntity(),
    disciplines: disciplines.map((DisciplineStatsModel stats) => stats.toEntity()).toList(growable: false),
  );
}
