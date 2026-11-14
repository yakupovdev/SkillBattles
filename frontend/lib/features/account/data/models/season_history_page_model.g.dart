// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'season_history_page_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SeasonHistoryPageModel _$SeasonHistoryPageModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SeasonHistoryPageModel', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['data', 'pagination']);
  final val = SeasonHistoryPageModel(
    data: $checkedConvert(
      'data',
      (v) => (v as List<dynamic>)
          .map((e) => SeasonPeakModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    pagination: $checkedConvert(
      'pagination',
      (v) => PaginationModel.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});
