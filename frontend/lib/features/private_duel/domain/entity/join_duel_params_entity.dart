import 'package:equatable/equatable.dart';

final class JoinDuelParamsEntity extends Equatable {
  const JoinDuelParamsEntity({required this.code});

  /// As typed; the use case normalises whitespace and case.
  final String code;

  @override
  List<Object?> get props => <Object?>[code];
}
