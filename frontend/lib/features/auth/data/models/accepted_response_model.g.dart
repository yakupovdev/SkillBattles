// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accepted_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AcceptedResponseModel _$AcceptedResponseModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AcceptedResponseModel', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['message']);
  final val = AcceptedResponseModel(
    message: $checkedConvert('message', (v) => v as String),
  );
  return val;
});
