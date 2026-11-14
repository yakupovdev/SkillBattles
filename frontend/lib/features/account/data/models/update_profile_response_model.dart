import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/core/data/models/user_model.dart';
import 'package:skill_battles/features/account/domain/entity/update_profile_result_entity.dart';

part 'update_profile_response_model.g.dart';

/// Result of a profile update.
@JsonSerializable(checked: true, createToJson: false)
final class UpdateProfileResponseModel {
  const UpdateProfileResponseModel({
    required this.user,
    required this.passwordChanged,
    required this.reauthenticationRequired,
  });

  factory UpdateProfileResponseModel.fromJson(Map<String, dynamic> json) =>
      _$UpdateProfileResponseModelFromJson(json);

  @JsonKey(required: true)
  final UserModel user;

  @JsonKey(required: true)
  final bool passwordChanged;

  @JsonKey(required: true)
  final bool reauthenticationRequired;

  UpdateProfileResultEntity toEntity() => UpdateProfileResultEntity(
    user: user.toEntity(),
    passwordChanged: passwordChanged,
    reauthenticationRequired: reauthenticationRequired,
  );
}
