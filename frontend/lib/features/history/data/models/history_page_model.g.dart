// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_page_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HistoryPageModel _$HistoryPageModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('HistoryPageModel', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['data', 'pagination', 'historyLimit']);
  final val = HistoryPageModel(
    data: $checkedConvert(
      'data',
      (v) => (v as List<dynamic>)
          .map((e) => HistoryItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    pagination: $checkedConvert(
      'pagination',
      (v) => PaginationModel.fromJson(v as Map<String, dynamic>),
    ),
    historyLimit: $checkedConvert('historyLimit', (v) => (v as num?)?.toInt()),
  );
  return val;
});
