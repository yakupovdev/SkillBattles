// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entitlements_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EntitlementsModel _$EntitlementsModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('EntitlementsModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'isPro',
          'version',
          'unlimitedRanked',
          'historyMatchLimit',
          'canViewCorrectAnswers',
          'canViewExplanations',
          'canViewAdvancedAnalytics',
          'canFilterMistakes',
        ],
      );
      final val = EntitlementsModel(
        isPro: $checkedConvert('isPro', (v) => v as bool),
        version: $checkedConvert('version', (v) => (v as num).toInt()),
        unlimitedRanked: $checkedConvert('unlimitedRanked', (v) => v as bool),
        historyMatchLimit: $checkedConvert(
          'historyMatchLimit',
          (v) => (v as num?)?.toInt(),
        ),
        canViewCorrectAnswers: $checkedConvert(
          'canViewCorrectAnswers',
          (v) => v as bool,
        ),
        canViewExplanations: $checkedConvert(
          'canViewExplanations',
          (v) => v as bool,
        ),
        canViewAdvancedAnalytics: $checkedConvert(
          'canViewAdvancedAnalytics',
          (v) => v as bool,
        ),
        canFilterMistakes: $checkedConvert(
          'canFilterMistakes',
          (v) => v as bool,
        ),
      );
      return val;
    });
