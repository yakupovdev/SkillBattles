import 'package:equatable/equatable.dart';

/// The signed-in user's own friend code: 12 characters of
/// `ABCDEFGHJKMNPQRSTUVWXYZ23456789`, canonical (no hyphens). Never derived
/// locally and never shown for another player.
final class FriendCodeEntity extends Equatable {
  const FriendCodeEntity({required this.code});

  final String code;

  @override
  List<Object?> get props => <Object?>[code];
}
