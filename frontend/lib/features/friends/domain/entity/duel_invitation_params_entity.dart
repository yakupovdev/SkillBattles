import 'package:equatable/equatable.dart';

/// Identifies one room invitation by its invitation id.
final class DuelInvitationParamsEntity extends Equatable {
  const DuelInvitationParamsEntity({required this.invitationId});

  final String invitationId;

  @override
  List<Object?> get props => <Object?>[invitationId];
}
