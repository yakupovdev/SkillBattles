import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';
import 'package:skill_battles/features/catalog/domain/entity/rank_ladder_entity.dart';

/// Display names from the server catalogue, with a readable fallback when
/// the catalogue is not at hand.
extension DisciplineNames on List<DisciplineEntity> {
  String nameOf(String code) {
    for (final DisciplineEntity discipline in this) {
      if (discipline.code == code) return discipline.displayName;
    }
    return formatDisciplineCode(code);
  }
}

extension RankNames on RankLadderEntity? {
  String nameOf(String code) =>
      this?.byCode(code)?.displayName ?? formatRankCode(code);
}

extension DisciplineTiming on DisciplineEntity {
  /// `5 rounds · 36–72s each` (Paper: home discipline cards).
  String get roundsLabel {
    final int min = minLimitSeconds;
    final int max = maxLimitSeconds;
    final String seconds = min == max ? '${min}s' : '$min–${max}s';
    return '$questionCount rounds · $seconds each';
  }
}
