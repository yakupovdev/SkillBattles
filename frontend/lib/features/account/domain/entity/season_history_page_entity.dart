import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/page_info_entity.dart';
import 'package:skill_battles/features/account/domain/entity/season_peak_entity.dart';

final class SeasonHistoryPageEntity extends Equatable {
  const SeasonHistoryPageEntity({required this.items, required this.page});

  final List<SeasonPeakEntity> items;
  final PageInfoEntity page;

  @override
  List<Object?> get props => <Object?>[items, page];
}
