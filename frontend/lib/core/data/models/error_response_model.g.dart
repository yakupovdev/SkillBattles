// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ErrorResponseModel _$ErrorResponseModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ErrorResponseModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['code', 'message', 'fieldErrors', 'resetsAt'],
      );
      final val = ErrorResponseModel(
        code: $checkedConvert('code', (v) => v as String),
        message: $checkedConvert('message', (v) => v as String),
        fieldErrors: $checkedConvert(
          'fieldErrors',
          (v) => (v as List<dynamic>)
              .map((e) => FieldErrorModel.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        resetsAt: $checkedConvert(
          'resetsAt',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
      );
      return val;
    });
