import 'package:equatable/equatable.dart';

final class LoginParamsEntity extends Equatable {
  const LoginParamsEntity({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => <Object?>[email, password];
}
