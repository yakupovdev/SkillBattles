// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$CheckoutRequestModelToJson(
  CheckoutRequestModel instance,
) => <String, dynamic>{
  'planCode': _$PlanCodeModelEnumMap[instance.planCode]!,
  'requestId': instance.requestId,
};

const _$PlanCodeModelEnumMap = {
  PlanCodeModel.free: 'FREE',
  PlanCodeModel.proMonthly: 'PRO_MONTHLY',
  PlanCodeModel.proAnnual: 'PRO_ANNUAL',
};
