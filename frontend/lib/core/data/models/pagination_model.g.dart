// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pagination_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaginationModel _$PaginationModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PaginationModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['page', 'size', 'totalElements', 'totalPages'],
      );
      final val = PaginationModel(
        page: $checkedConvert('page', (v) => (v as num).toInt()),
        size: $checkedConvert('size', (v) => (v as num).toInt()),
        totalElements: $checkedConvert(
          'totalElements',
          (v) => (v as num).toInt(),
        ),
        totalPages: $checkedConvert('totalPages', (v) => (v as num).toInt()),
      );
      return val;
    });
