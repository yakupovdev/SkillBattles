import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/domain/entity/user_entity.dart';

part 'user_model.g.dart';

/// Own active profile.
@JsonSerializable(checked: true, createToJson: false)
final class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.nickname,
    required this.createdAt,
    required this.isPro,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  @JsonKey(required: true)
  final String id;

  @JsonKey(required: true)
  final String email;

  @JsonKey(required: true)
  final String nickname;

  @JsonKey(required: true)
  final DateTime createdAt;

  @JsonKey(required: true)
  final bool isPro;

  UserEntity toEntity() => UserEntity(
    id: id,
    email: email,
    nickname: nickname,
    createdAt: createdAt,
    isPro: isPro,
  );
}
