import 'package:equatable/equatable.dart';

/// The signed-in account's token pair and id (JWT `sub`).
final class SessionTokens extends Equatable {
  const SessionTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
  });

  final String accessToken;
  final String refreshToken;
  final String userId;

  // Tokens are secrets: never print them.
  @override
  String toString() => 'SessionTokens(userId: $userId)';

  @override
  List<Object?> get props => <Object?>[accessToken, refreshToken, userId];
}
