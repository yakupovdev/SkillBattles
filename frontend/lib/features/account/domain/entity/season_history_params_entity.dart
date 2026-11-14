import 'package:equatable/equatable.dart';

final class SeasonHistoryParamsEntity extends Equatable {
  const SeasonHistoryParamsEntity({
    this.page = 0,
    this.size = 20,
    this.disciplineCode,
  });

  final int page;
  final int size;
  final String? disciplineCode;

  @override
  List<Object?> get props => <Object?>[page, size, disciplineCode];
}
