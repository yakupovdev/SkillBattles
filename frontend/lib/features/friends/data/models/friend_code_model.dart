import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/utils/error/app_exception.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_code_entity.dart';

part 'friend_code_model.g.dart';

/// The signed-in user's own friend code.
@JsonSerializable(checked: true, createToJson: false)
final class FriendCodeModel {
  const FriendCodeModel({required this.friendCode});

  factory FriendCodeModel.fromJson(Map<String, dynamic> json) =>
      _$FriendCodeModelFromJson(json);

  @JsonKey(required: true, fromJson: _canonicalCode)
  final String friendCode;

  FriendCodeEntity toEntity() => FriendCodeEntity(code: friendCode);
}

final RegExp _codePattern = RegExp(r'^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{12}$');

String _canonicalCode(Object? value) {
  if (value is String && _codePattern.hasMatch(value)) return value;
  throw const ParsingException('friendCode is not a canonical friend code.');
}
