import 'package:equatable/equatable.dart';

/// One Send intent: the same [requestId] is reused for every retry of the
/// same [duelId] + [friendId]; a new target or a new send gets a new one.
final class SendDuelInvitationParamsEntity extends Equatable {
  const SendDuelInvitationParamsEntity({
    required this.duelId,
    required this.friendId,
    required this.requestId,
  });

  final String duelId;

  /// The accepted friend's USER id.
  final String friendId;
  final String requestId;

  @override
  List<Object?> get props => <Object?>[duelId, friendId, requestId];
}
