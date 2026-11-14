// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'field_error_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FieldErrorModel _$FieldErrorModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FieldErrorModel', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['field', 'message']);
      final val = FieldErrorModel(
        field: $checkedConvert('field', (v) => v as String),
        message: $checkedConvert('message', (v) => v as String),
      );
      return val;
    });
