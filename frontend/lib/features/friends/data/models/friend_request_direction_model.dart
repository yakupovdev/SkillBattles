import 'package:skill_battles/features/friends/domain/entity/friend_request_direction.dart';

/// `direction` query value of GET /friend-requests.
enum FriendRequestDirectionModel {
  incoming('INCOMING'),
  outgoing('OUTGOING');

  const FriendRequestDirectionModel(this.wireName);

  final String wireName;

  factory FriendRequestDirectionModel.fromEntity(
    FriendRequestDirection direction,
  ) => switch (direction) {
    FriendRequestDirection.incoming => FriendRequestDirectionModel.incoming,
    FriendRequestDirection.outgoing => FriendRequestDirectionModel.outgoing,
  };
}
