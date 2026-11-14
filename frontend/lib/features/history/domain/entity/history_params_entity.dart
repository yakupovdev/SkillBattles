import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/battle_mode.dart';

final class HistoryParamsEntity extends Equatable {
  const HistoryParamsEntity({
    this.page = 0,
    this.size = 20,
    this.newestFirst = true,
    this.disciplineCode,
    this.mode,
  });

  final int page;
  final int size;
  final bool newestFirst;
  final String? disciplineCode;
  final BattleMode? mode;

  @override
  List<Object?> get props => <Object?>[
    page,
    size,
    newestFirst,
    disciplineCode,
    mode,
  ];
}
