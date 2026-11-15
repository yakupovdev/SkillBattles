import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_request_params_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_entity.dart';
import 'package:skill_battles/features/friends/domain/repository/friends_repository.dart';

final class AcceptFriendRequestUsecase
    implements
        Usecase<
          Future<Either<Failure, RelationshipEntity>>,
          FriendRequestParamsEntity
        > {
  const AcceptFriendRequestUsecase(this._repository);

  final FriendsRepository _repository;

  @override
  Future<Either<Failure, RelationshipEntity>> call(
    FriendRequestParamsEntity params,
  ) => _repository.acceptFriendRequest(params.requestId);
}
