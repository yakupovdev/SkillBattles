import 'package:equatable/equatable.dart';

final class PasswordResetRequestParamsEntity extends Equatable {
  const PasswordResetRequestParamsEntity({required this.email});

  final String email;

  @override
  List<Object?> get props => <Object?>[email];
}
