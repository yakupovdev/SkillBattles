import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/history/domain/entity/history_page_entity.dart';
import 'package:skill_battles/features/history/domain/entity/history_params_entity.dart';

abstract interface class HistoryRepository {
  Future<Either<Failure, HistoryPageEntity>> getHistory(
    HistoryParamsEntity params,
  );
}
