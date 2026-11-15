import 'package:equatable/equatable.dart';

import 'package:skill_battles/features/friends/domain/entity/duel_invitation_entity.dart';

/// A complete (unpaged) list of invitations with the server clock.
final class DuelInvitationsSnapshotEntity extends Equatable {
  const DuelInvitationsSnapshotEntity({
    required this.invitations,
    required this.serverTime,
    required this.receivedAt,
  });

  final List<DuelInvitationEntity> invitations;
  final DateTime serverTime;

  /// Local time when the answer arrived.
  final DateTime receivedAt;

  /// Server time minus local time, for countdowns to `expiresAt`.
  Duration get clockOffset => serverTime.difference(receivedAt);

  @override
  List<Object?> get props => <Object?>[invitations, serverTime, receivedAt];
}
