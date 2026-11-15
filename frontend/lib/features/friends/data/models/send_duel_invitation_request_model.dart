import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/friends/domain/entity/send_duel_invitation_params_entity.dart';

part 'send_duel_invitation_request_model.g.dart';

/// Body of POST /duels/{duelId}/invitations.
@JsonSerializable(createFactory: false)
final class SendDuelInvitationRequestModel {
  const SendDuelInvitationRequestModel({
    required this.friendId,
    required this.requestId,
  });

  factory SendDuelInvitationRequestModel.fromEntity(
    SendDuelInvitationParamsEntity params,
  ) => SendDuelInvitationRequestModel(
    friendId: params.friendId,
    requestId: params.requestId,
  );

  Map<String, dynamic> toJson() => _$SendDuelInvitationRequestModelToJson(this);

  final String friendId;
  final String requestId;
}
