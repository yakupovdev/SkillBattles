import 'package:equatable/equatable.dart';

import 'package:skill_battles/features/friends/domain/entity/friend_request_direction.dart';

/// Zero-based page of PENDING requests of one [direction]; [size] is 1..100.
final class FriendRequestsParamsEntity extends Equatable {
  const FriendRequestsParamsEntity({
    this.direction = FriendRequestDirection.incoming,
    this.page = 0,
    this.size = 20,
  });

  final FriendRequestDirection direction;
  final int page;
  final int size;

  @override
  List<Object?> get props => <Object?>[direction, page, size];
}
