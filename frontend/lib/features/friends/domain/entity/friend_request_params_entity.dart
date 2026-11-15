import 'package:equatable/equatable.dart';

/// Identifies one friend request by its relationship id.
final class FriendRequestParamsEntity extends Equatable {
  const FriendRequestParamsEntity({required this.requestId});

  final String requestId;

  @override
  List<Object?> get props => <Object?>[requestId];
}
