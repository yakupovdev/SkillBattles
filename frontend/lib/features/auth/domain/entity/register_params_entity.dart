import 'package:equatable/equatable.dart';

/// Sign-up input. The birth fields are collected before the credentials;
/// [birthDay] only when the user turns 13 in the current ET month.
final class RegisterParamsEntity extends Equatable {
  const RegisterParamsEntity({
    required this.email,
    required this.password,
    required this.nickname,
    required this.birthYear,
    required this.birthMonth,
    this.birthDay,
  });

  final String email;
  final String password;
  final String nickname;
  final int birthYear;
  final int birthMonth;
  final int? birthDay;

  @override
  List<Object?> get props => <Object?>[
    email,
    password,
    nickname,
    birthYear,
    birthMonth,
    birthDay,
  ];
}
