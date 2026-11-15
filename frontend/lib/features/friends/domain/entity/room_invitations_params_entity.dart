import 'package:equatable/equatable.dart';

/// The host's room whose outgoing invitation is restored.
final class RoomInvitationsParamsEntity extends Equatable {
  const RoomInvitationsParamsEntity({required this.duelId});

  final String duelId;

  @override
  List<Object?> get props => <Object?>[duelId];
}
