import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_requests_page_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_requests_params_entity.dart';
import 'package:skill_battles/features/friends/domain/repository/friends_repository.dart';

final class GetFriendRequestsUsecase
    implements
        Usecase<
          Future<Either<Failure, FriendRequestsPageEntity>>,
          FriendRequestsParamsEntity
        > {
  const GetFriendRequestsUsecase(this._repository);

  final FriendsRepository _repository;

  @override
  Future<Either<Failure, FriendRequestsPageEntity>> call(
    FriendRequestsParamsEntity params,
  ) => _repository.getFriendRequests(params);
}
