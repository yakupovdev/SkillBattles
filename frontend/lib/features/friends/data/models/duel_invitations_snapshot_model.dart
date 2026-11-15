import 'package:json_annotation/json_annotation.dart';

import 'package:skill_battles/features/friends/data/models/duel_invitation_model.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitations_snapshot_entity.dart';

part 'duel_invitations_snapshot_model.g.dart';

/// DuelInvitationsSnapshot: complete, unpaged, with the server clock.
@JsonSerializable(checked: true, createToJson: false)
final class DuelInvitationsSnapshotModel {
  const DuelInvitationsSnapshotModel({
    required this.data,
    required this.serverTime,
  });

  factory DuelInvitationsSnapshotModel.fromJson(Map<String, dynamic> json) =>
      _$DuelInvitationsSnapshotModelFromJson(json);

  @JsonKey(required: true)
  final List<DuelInvitationModel> data;

  @JsonKey(required: true)
  final DateTime serverTime;

  DuelInvitationsSnapshotEntity toEntity({
    required String viewerId,
    required DateTime receivedAt,
  }) => DuelInvitationsSnapshotEntity(
    invitations: data
        .map((DuelInvitationModel item) => item.toEntity(viewerId: viewerId))
        .toList(growable: false),
    serverTime: serverTime,
    receivedAt: receivedAt,
  );
}
