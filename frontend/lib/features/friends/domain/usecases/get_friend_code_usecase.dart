import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_code_entity.dart';
import 'package:skill_battles/features/friends/domain/repository/friends_repository.dart';

final class GetFriendCodeUsecase
    implements Usecase<Future<Either<Failure, FriendCodeEntity>>, NoParams> {
  const GetFriendCodeUsecase(this._repository);

  final FriendsRepository _repository;

  @override
  Future<Either<Failure, FriendCodeEntity>> call(NoParams params) =>
      _repository.getFriendCode();
}
