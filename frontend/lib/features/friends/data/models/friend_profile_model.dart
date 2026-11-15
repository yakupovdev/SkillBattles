import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/public_player_model.dart';
import 'package:skill_battles/features/friends/data/models/friend_discipline_statistics_model.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_profile_entity.dart';

part 'friend_profile_model.g.dart';

/// FriendProfileResponse (server-redacted).
@JsonSerializable(checked: true, createToJson: false)
final class FriendProfileModel {
  const FriendProfileModel({
    required this.friend,
    required this.friendsSince,
    required this.disciplines,
  });

  factory FriendProfileModel.fromJson(Map<String, dynamic> json) =>
      _$FriendProfileModelFromJson(json);

  @JsonKey(required: true)
  final PublicPlayerModel friend;

  @JsonKey(required: true)
  final DateTime friendsSince;

  @JsonKey(required: true)
  final List<FriendDisciplineStatisticsModel> disciplines;

  FriendProfileEntity toEntity() => FriendProfileEntity(
    friend: friend.toEntity(),
    friendsSince: friendsSince,
    disciplines: disciplines
        .map((FriendDisciplineStatisticsModel stats) => stats.toEntity())
        .toList(growable: false),
  );
}
