import 'package:skill_battles/core/data/models/competition_mode_model.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/error/failure_mapper.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/history/data/models/history_page_model.dart';
import 'package:skill_battles/features/history/data/sources/remote/history_remote.dart';
import 'package:skill_battles/features/history/domain/entity/history_page_entity.dart';
import 'package:skill_battles/features/history/domain/entity/history_params_entity.dart';
import 'package:skill_battles/features/history/domain/repository/history_repository.dart';

/// Remote only: the visible window depends on the current plan.
final class HistoryRepositoryImpl implements HistoryRepository {
  const HistoryRepositoryImpl({required this._remote});

  final HistoryRemote _remote;

  static const String _sortDesc = 'createdAt,desc';
  static const String _sortAsc = 'createdAt,asc';

  @override
  Future<Either<Failure, HistoryPageEntity>> getHistory(
    HistoryParamsEntity params,
  ) async {
    try {
      final HistoryPageModel model = await _remote.getBattles(
        page: params.page,
        size: params.size,
        sort: params.newestFirst ? _sortDesc : _sortAsc,
        disciplineCode: params.disciplineCode,
        mode: params.mode == null
            ? null
            : CompetitionModeModel.fromEntity(params.mode!),
      );
      return Right(model.toEntity());
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }
}
