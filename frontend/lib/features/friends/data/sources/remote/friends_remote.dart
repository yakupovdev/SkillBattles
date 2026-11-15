import 'package:skill_battles/core/utils/network/api_client.dart';
import 'package:skill_battles/core/utils/network/app_api.dart';
import 'package:skill_battles/core/utils/network/json_object.dart';
import 'package:skill_battles/features/friends/data/models/duel_invitation_model.dart';
import 'package:skill_battles/features/friends/data/models/duel_invitations_snapshot_model.dart';
import 'package:skill_battles/features/friends/data/models/friend_code_model.dart';
import 'package:skill_battles/features/friends/data/models/friend_profile_model.dart';
import 'package:skill_battles/features/friends/data/models/friend_request_direction_model.dart';
import 'package:skill_battles/features/friends/data/models/friend_requests_page_model.dart';
import 'package:skill_battles/features/friends/data/models/friends_page_model.dart';
import 'package:skill_battles/features/friends/data/models/relationship_model.dart';
import 'package:skill_battles/features/friends/data/models/send_duel_invitation_request_model.dart';
import 'package:skill_battles/features/friends/data/models/send_friend_request_model.dart';

/// Friends and room-invitation endpoints. 200 and 201 both return the body;
/// 204 returns nothing and is not parsed.
abstract interface class FriendsRemote {
  Future<FriendCodeModel> getFriendCode();

  Future<FriendsPageModel> getFriends({int? page, int? size});

  Future<FriendProfileModel> getFriendProfile(String friendId);

  Future<void> removeFriend(String friendId);

  Future<RelationshipModel> sendFriendRequest(SendFriendRequestModel request);

  Future<FriendRequestsPageModel> getFriendRequests({
    FriendRequestDirectionModel? direction,
    int? page,
    int? size,
  });

  Future<RelationshipModel> getFriendRequest(String id);

  Future<RelationshipModel> acceptFriendRequest(String id);

  Future<RelationshipModel> declineFriendRequest(String id);

  Future<void> cancelFriendRequest(String id);

  Future<DuelInvitationModel> sendDuelInvitation(
    String duelId,
    SendDuelInvitationRequestModel request,
  );

  Future<DuelInvitationsSnapshotModel> getRoomInvitations(String duelId);

  Future<DuelInvitationsSnapshotModel> getIncomingDuelInvitations();

  Future<DuelInvitationModel> getDuelInvitation(String id);

  Future<DuelInvitationModel> acceptDuelInvitation(String id);

  Future<DuelInvitationModel> declineDuelInvitation(String id);

  Future<void> withdrawDuelInvitation(String id);
}

final class FriendsRemoteImpl implements FriendsRemote {
  const FriendsRemoteImpl(this._client);

  final ApiClient _client;

  @override
  Future<FriendCodeModel> getFriendCode() async {
    final Object? json = await _client.get(AppApi.meFriendCode);
    return FriendCodeModel.fromJson(asJsonObject(json));
  }

  @override
  Future<FriendsPageModel> getFriends({int? page, int? size}) async {
    final Object? json = await _client.get(
      AppApi.friends,
      queryParameters: <String, dynamic>{
        AppApi.pageKey: ?page,
        AppApi.sizeKey: ?size,
      },
    );
    return FriendsPageModel.fromJson(asJsonObject(json));
  }

  @override
  Future<FriendProfileModel> getFriendProfile(String friendId) async {
    final Object? json = await _client.get(AppApi.friend(friendId));
    return FriendProfileModel.fromJson(asJsonObject(json));
  }

  @override
  Future<void> removeFriend(String friendId) async {
    await _client.delete(AppApi.friend(friendId));
  }

  @override
  Future<RelationshipModel> sendFriendRequest(
    SendFriendRequestModel request,
  ) async {
    final Object? json = await _client.post(
      AppApi.friendRequests,
      data: request.toJson(),
    );
    return RelationshipModel.fromJson(asJsonObject(json));
  }

  @override
  Future<FriendRequestsPageModel> getFriendRequests({
    FriendRequestDirectionModel? direction,
    int? page,
    int? size,
  }) async {
    final Object? json = await _client.get(
      AppApi.friendRequests,
      queryParameters: <String, dynamic>{
        AppApi.directionKey: ?direction?.wireName,
        AppApi.pageKey: ?page,
        AppApi.sizeKey: ?size,
      },
    );
    return FriendRequestsPageModel.fromJson(asJsonObject(json));
  }

  @override
  Future<RelationshipModel> getFriendRequest(String id) async {
    final Object? json = await _client.get(AppApi.friendRequest(id));
    return RelationshipModel.fromJson(asJsonObject(json));
  }

  @override
  Future<RelationshipModel> acceptFriendRequest(String id) async {
    final Object? json = await _client.post(AppApi.friendRequestAccept(id));
    return RelationshipModel.fromJson(asJsonObject(json));
  }

  @override
  Future<RelationshipModel> declineFriendRequest(String id) async {
    final Object? json = await _client.post(AppApi.friendRequestDecline(id));
    return RelationshipModel.fromJson(asJsonObject(json));
  }

  @override
  Future<void> cancelFriendRequest(String id) async {
    await _client.delete(AppApi.friendRequest(id));
  }

  @override
  Future<DuelInvitationModel> sendDuelInvitation(
    String duelId,
    SendDuelInvitationRequestModel request,
  ) async {
    final Object? json = await _client.post(
      AppApi.duelInvitations(duelId),
      data: request.toJson(),
    );
    return DuelInvitationModel.fromJson(asJsonObject(json));
  }

  @override
  Future<DuelInvitationsSnapshotModel> getRoomInvitations(String duelId) async {
    final Object? json = await _client.get(AppApi.duelInvitations(duelId));
    return DuelInvitationsSnapshotModel.fromJson(asJsonObject(json));
  }

  @override
  Future<DuelInvitationsSnapshotModel> getIncomingDuelInvitations() async {
    final Object? json = await _client.get(AppApi.meDuelInvitations);
    return DuelInvitationsSnapshotModel.fromJson(asJsonObject(json));
  }

  @override
  Future<DuelInvitationModel> getDuelInvitation(String id) async {
    final Object? json = await _client.get(AppApi.duelInvitation(id));
    return DuelInvitationModel.fromJson(asJsonObject(json));
  }

  @override
  Future<DuelInvitationModel> acceptDuelInvitation(String id) async {
    final Object? json = await _client.post(AppApi.duelInvitationAccept(id));
    return DuelInvitationModel.fromJson(asJsonObject(json));
  }

  @override
  Future<DuelInvitationModel> declineDuelInvitation(String id) async {
    final Object? json = await _client.post(AppApi.duelInvitationDecline(id));
    return DuelInvitationModel.fromJson(asJsonObject(json));
  }

  @override
  Future<void> withdrawDuelInvitation(String id) async {
    await _client.delete(AppApi.duelInvitation(id));
  }
}
