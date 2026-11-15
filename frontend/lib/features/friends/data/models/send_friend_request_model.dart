import 'package:json_annotation/json_annotation.dart';

part 'send_friend_request_model.g.dart';

/// Body of POST /friend-requests.
@JsonSerializable(createFactory: false)
final class SendFriendRequestModel {
  const SendFriendRequestModel({required this.friendCode});

  Map<String, dynamic> toJson() => _$SendFriendRequestModelToJson(this);

  final String friendCode;
}
