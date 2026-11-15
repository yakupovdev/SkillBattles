// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FriendProfileModel _$FriendProfileModelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FriendProfileModel', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['friend', 'friendsSince', 'disciplines'],
      );
      final val = FriendProfileModel(
        friend: $checkedConvert(
          'friend',
          (v) => PublicPlayerModel.fromJson(v as Map<String, dynamic>),
        ),
        friendsSince: $checkedConvert(
          'friendsSince',
          (v) => DateTime.parse(v as String),
        ),
        disciplines: $checkedConvert(
          'disciplines',
          (v) => (v as List<dynamic>)
              .map(
                (e) => FriendDisciplineStatisticsModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
        ),
      );
      return val;
    });
