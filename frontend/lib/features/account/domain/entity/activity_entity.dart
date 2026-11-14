import 'package:equatable/equatable.dart';

/// Kind of the account's single live activity.
enum ActivityType { none, queue, privateDuel, battle }

/// Resource behind [ActivityEntity.resourceId].
enum ActivityResourceKind { queueEntry, duel, rematch, battle }

/// The queue entry, code room, pending rematch or non-terminal battle to
/// recover after a reload.
final class ActivityEntity extends Equatable {
  const ActivityEntity({
    required this.type,
    required this.resourceId,
    required this.battleId,
    required this.resourceKind,
  });

  static const ActivityEntity none = ActivityEntity(
    type: ActivityType.none,
    resourceId: null,
    battleId: null,
    resourceKind: null,
  );

  final ActivityType type;

  /// For a pending rematch: the source battle id.
  final String? resourceId;
  final String? battleId;
  final ActivityResourceKind? resourceKind;

  bool get isNone => type == ActivityType.none;

  @override
  List<Object?> get props => <Object?>[
    type,
    resourceId,
    battleId,
    resourceKind,
  ];
}
