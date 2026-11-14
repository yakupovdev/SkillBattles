import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';
import 'package:skill_battles/features/catalog/presentation/extensions/catalog_labels.dart';

/// Short discipline names for narrow table columns and meta lines
/// ("SAT R&W"), as the Paper tables write them.
extension DisciplineShortNames on List<DisciplineEntity> {
  String shortNameOf(String code) =>
      nameOf(code).replaceAll('Reading & Writing', 'R&W');
}
