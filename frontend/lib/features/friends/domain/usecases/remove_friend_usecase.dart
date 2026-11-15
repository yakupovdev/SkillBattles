import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_params_entity.dart';
import 'package:skill_battles/features/friends/domain/repository/friends_repository.dart';

final class RemoveFriendUsecase
    implements Usecase<Future<Either<Failure, Unit>>, FriendParamsEntity> {
  const RemoveFriendUsecase(this._repository);

  final FriendsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(FriendParamsEntity params) =>
      _repository.removeFriend(params.friendId);
}
