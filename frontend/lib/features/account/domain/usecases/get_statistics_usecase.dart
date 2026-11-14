import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/account/domain/entity/statistics_entity.dart';
import 'package:skill_battles/features/account/domain/repository/account_repository.dart';

final class GetStatisticsUsecase
    implements Usecase<Future<Either<Failure, StatisticsEntity>>, NoParams> {
  const GetStatisticsUsecase(this._repository);

  final AccountRepository _repository;

  @override
  Future<Either<Failure, StatisticsEntity>> call(NoParams params) =>
      _repository.getStatistics();
}
