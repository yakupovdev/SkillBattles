import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/page_info_entity.dart';
import 'package:skill_battles/features/history/domain/entity/history_item_entity.dart';

/// A page of history. For Free the server first keeps the latest
/// [historyLimit] matches overall and only then filters and sorts them.
final class HistoryPageEntity extends Equatable {
  const HistoryPageEntity({
    required this.items,
    required this.page,
    required this.historyLimit,
  });

  final List<HistoryItemEntity> items;
  final PageInfoEntity page;

  /// 10 for Free, `null` for Pro.
  final int? historyLimit;

  @override
  List<Object?> get props => <Object?>[items, page, historyLimit];
}
