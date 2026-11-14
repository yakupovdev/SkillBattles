// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portal_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PortalModel _$PortalModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PortalModel', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['url']);
      final val = PortalModel(url: $checkedConvert('url', (v) => v as String));
      return val;
    });
