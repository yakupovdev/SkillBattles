import 'package:equatable/equatable.dart';

final class SendFriendRequestParamsEntity extends Equatable {
  const SendFriendRequestParamsEntity({required this.friendCode});

  /// As typed; the use case trims it, removes hyphens and upper-cases it.
  final String friendCode;

  @override
  List<Object?> get props => <Object?>[friendCode];
}
