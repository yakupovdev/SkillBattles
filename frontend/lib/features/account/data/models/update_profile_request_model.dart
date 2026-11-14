import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/account/domain/entity/update_profile_params_entity.dart';

part 'update_profile_request_model.g.dart';

/// Body of PATCH /users/me; absent fields stay unchanged.
@JsonSerializable(createFactory: false, includeIfNull: false)
final class UpdateProfileRequestModel {
  const UpdateProfileRequestModel({
    this.nickname,
    this.currentPassword,
    this.newPassword,
  });

  Map<String, dynamic> toJson() => _$UpdateProfileRequestModelToJson(this);

  final String? nickname;
  final String? currentPassword;
  final String? newPassword;

  factory UpdateProfileRequestModel.fromEntity(
    UpdateProfileParamsEntity params,
  ) => UpdateProfileRequestModel(
    nickname: params.nickname?.trim(),
    currentPassword: params.currentPassword,
    newPassword: params.newPassword,
  );
}
