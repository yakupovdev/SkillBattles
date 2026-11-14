import 'package:equatable/equatable.dart';

/// Neutral birth input of the age screen.
final class AgeCheckParamsEntity extends Equatable {
  const AgeCheckParamsEntity({
    required this.birthYear,
    required this.birthMonth,
    this.birthDay,
  });

  final int birthYear;
  final int birthMonth;
  final int? birthDay;

  @override
  List<Object?> get props => <Object?>[birthYear, birthMonth, birthDay];
}
