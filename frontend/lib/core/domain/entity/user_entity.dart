import 'package:equatable/equatable.dart';

/// The signed-in account (no birth or billing details).
final class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    required this.nickname,
    required this.createdAt,
    required this.isPro,
  });

  final String id;
  final String email;
  final String nickname;
  final DateTime createdAt;
  final bool isPro;

  @override
  List<Object?> get props => <Object?>[id, email, nickname, createdAt, isPro];
}
