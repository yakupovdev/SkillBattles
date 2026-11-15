import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitations_snapshot_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_code_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_profile_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_requests_page_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_requests_params_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friends_page_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friends_page_params_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/send_duel_invitation_params_entity.dart';

/// Friend code, friendships, friend profiles and targeted room invitations.
abstract interface class FriendsRepository {
  Future<Either<Failure, FriendCodeEntity>> getFriendCode();

  Future<Either<Failure, FriendsPageEntity>> getFriends(
    FriendsPageParamsEntity params,
  );

  /// 404 `FRIEND_NOT_FOUND` once the friendship no longer exists.
  Future<Either<Failure, FriendProfileEntity>> getFriendProfile(
    String friendId,
  );

  /// 204; removing a non-friend is a no-op.
  Future<Either<Failure, Unit>> removeFriend(String friendId);

  /// 201 (new) and 200 (own pending request already exists) both succeed.
  /// [friendCode] is canonical (12 characters, no hyphens).
  Future<Either<Failure, RelationshipEntity>> sendFriendRequest(
    String friendCode,
  );

  /// PENDING requests only.
  Future<Either<Failure, FriendRequestsPageEntity>> getFriendRequests(
    FriendRequestsParamsEntity params,
  );

  /// Any status, either participant.
  Future<Either<Failure, RelationshipEntity>> getFriendRequest(
    String requestId,
  );

  Future<Either<Failure, RelationshipEntity>> acceptFriendRequest(
    String requestId,
  );

  Future<Either<Failure, RelationshipEntity>> declineFriendRequest(
    String requestId,
  );

  /// 204; requester only.
  Future<Either<Failure, Unit>> cancelFriendRequest(String requestId);

  /// 201 (new) and 200 (same requestId replay, any status) both succeed.
  Future<Either<Failure, DuelInvitationEntity>> sendDuelInvitation(
    SendDuelInvitationParamsEntity params,
  );

  /// Host only; at most one PENDING invitation, a terminal room may be empty.
  Future<Either<Failure, DuelInvitationsSnapshotEntity>> getRoomInvitations(
    String duelId,
  );

  /// Complete list of incoming PENDING invitations (expiresAt, id).
  Future<Either<Failure, DuelInvitationsSnapshotEntity>>
  getIncomingDuelInvitations();

  /// Host or recipient, terminal states included.
  Future<Either<Failure, DuelInvitationEntity>> getDuelInvitation(
    String invitationId,
  );

  /// ACCEPTED with `battleId`; a repeat returns the same state.
  Future<Either<Failure, DuelInvitationEntity>> acceptDuelInvitation(
    String invitationId,
  );

  /// The authoritative invitation; a non-accepted terminal state is
  /// returned unchanged.
  Future<Either<Failure, DuelInvitationEntity>> declineDuelInvitation(
    String invitationId,
  );

  /// 204; host only; never cancels the room.
  Future<Either<Failure, Unit>> withdrawDuelInvitation(String invitationId);

  /// FRIENDSHIP_CHANGED pushes and the records returned by this
  /// repository's own send/accept/decline calls, so every listener
  /// converges by id + version even when a push is lost.
  Stream<RelationshipEntity> watchFriendshipChanges();

  /// DUEL_INVITATION_CHANGED pushes and the invitations returned by this
  /// repository's own send/get/accept/decline calls.
  Stream<DuelInvitationEntity> watchDuelInvitationChanges();

  /// Id of the signed-in user (`null` when signed out), current value
  /// first, then every session change (token refreshes repeat the id).
  Stream<String?> watchSignedInUser();
}
