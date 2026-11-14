// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_state_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountStateModel _$AccountStateModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AccountStateModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['user', 'subscription', 'limits', 'streaks'],
      );
      final val = AccountStateModel(
        user: $checkedConvert(
          'user',
          (v) => UserModel.fromJson(v as Map<String, dynamic>),
        ),
        subscription: $checkedConvert(
          'subscription',
          (v) => SubscriptionModel.fromJson(v as Map<String, dynamic>),
        ),
        limits: $checkedConvert(
          'limits',
          (v) => LimitsResponseModel.fromJson(v as Map<String, dynamic>),
        ),
        streaks: $checkedConvert(
          'streaks',
          (v) => StreaksModel.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });
