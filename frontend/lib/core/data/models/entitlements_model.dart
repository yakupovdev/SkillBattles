import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/domain/entity/entitlements_entity.dart';

part 'entitlements_model.g.dart';

/// Authoritative current access rights.
@JsonSerializable(checked: true, createToJson: false)
final class EntitlementsModel {
  const EntitlementsModel({
    required this.isPro,
    required this.version,
    required this.unlimitedRanked,
    required this.historyMatchLimit,
    required this.canViewCorrectAnswers,
    required this.canViewExplanations,
    required this.canViewAdvancedAnalytics,
    required this.canFilterMistakes,
  });

  factory EntitlementsModel.fromJson(Map<String, dynamic> json) =>
      _$EntitlementsModelFromJson(json);

  @JsonKey(required: true)
  final bool isPro;

  @JsonKey(required: true)
  final int version;

  @JsonKey(required: true)
  final bool unlimitedRanked;

  @JsonKey(required: true)
  final int? historyMatchLimit;

  @JsonKey(required: true)
  final bool canViewCorrectAnswers;

  @JsonKey(required: true)
  final bool canViewExplanations;

  @JsonKey(required: true)
  final bool canViewAdvancedAnalytics;

  @JsonKey(required: true)
  final bool canFilterMistakes;

  EntitlementsEntity toEntity() => EntitlementsEntity(
    isPro: isPro,
    version: version,
    unlimitedRanked: unlimitedRanked,
    historyMatchLimit: historyMatchLimit,
    canViewCorrectAnswers: canViewCorrectAnswers,
    canViewExplanations: canViewExplanations,
    canViewAdvancedAnalytics: canViewAdvancedAnalytics,
    canFilterMistakes: canFilterMistakes,
  );
}
