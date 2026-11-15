import 'package:equatable/equatable.dart';

/// Identifies a friend by their USER id (not the relationship id).
final class FriendParamsEntity extends Equatable {
  const FriendParamsEntity({required this.friendId});

  final String friendId;

  @override
  List<Object?> get props => <Object?>[friendId];
}
