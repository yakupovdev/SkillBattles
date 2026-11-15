import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/friends/domain/entity/friends_page_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friends_page_params_entity.dart';
import 'package:skill_battles/features/friends/domain/repository/friends_repository.dart';

final class GetFriendsUsecase
    implements
        Usecase<
          Future<Either<Failure, FriendsPageEntity>>,
          FriendsPageParamsEntity
        > {
  const GetFriendsUsecase(this._repository);

  final FriendsRepository _repository;

  @override
  Future<Either<Failure, FriendsPageEntity>> call(
    FriendsPageParamsEntity params,
  ) => _repository.getFriends(params);
}
