// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckoutModel _$CheckoutModelFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CheckoutModel', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['checkoutSessionId', 'url', 'expiresAt'],
  );
  final val = CheckoutModel(
    checkoutSessionId: $checkedConvert('checkoutSessionId', (v) => v as String),
    url: $checkedConvert('url', (v) => v as String),
    expiresAt: $checkedConvert('expiresAt', (v) => DateTime.parse(v as String)),
  );
  return val;
});
