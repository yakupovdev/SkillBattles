import 'package:equatable/equatable.dart';

/// Public identity of another player; `isPro` is only the badge.
final class PublicPlayerEntity extends Equatable {
  const PublicPlayerEntity({
    required this.id,
    required this.nickname,
    required this.isPro,
  });

  final String id;
  final String nickname;
  final bool isPro;

  @override
  List<Object?> get props => <Object?>[id, nickname, isPro];
}
