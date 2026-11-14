import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/domain/entity/public_player_entity.dart';

part 'public_player_model.g.dart';

/// Public player identity.
@JsonSerializable(checked: true, createToJson: false)
final class PublicPlayerModel {
  const PublicPlayerModel({
    required this.id,
    required this.nickname,
    required this.isPro,
  });

  factory PublicPlayerModel.fromJson(Map<String, dynamic> json) =>
      _$PublicPlayerModelFromJson(json);

  @JsonKey(required: true)
  final String id;

  @JsonKey(required: true)
  final String nickname;

  @JsonKey(required: true)
  final bool isPro;

  PublicPlayerEntity toEntity() =>
      PublicPlayerEntity(id: id, nickname: nickname, isPro: isPro);
}
