import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/send_friend_request_params_entity.dart';
import 'package:skill_battles/features/friends/domain/repository/friends_repository.dart';

/// Normalises the code like the server (outer whitespace trimmed, ASCII
/// hyphens removed, upper case) and checks its shape first, so a typo never
/// spends a rate-limited attempt.
final class SendFriendRequestUsecase
    implements
        Usecase<
          Future<Either<Failure, RelationshipEntity>>,
          SendFriendRequestParamsEntity
        > {
  const SendFriendRequestUsecase(this._repository);

  final FriendsRepository _repository;

  /// 12 characters without the ambiguous I, L, O, 0 and 1.
  static final RegExp _code = RegExp(
    r'^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{12}$',
  );

  @override
  Future<Either<Failure, RelationshipEntity>> call(
    SendFriendRequestParamsEntity params,
  ) async {
    final String code = params.friendCode
        .trim()
        .replaceAll('-', '')
        .toUpperCase();
    if (!_code.hasMatch(code)) {
      return const Left(
        ValidationFailure(message: 'Enter the 12-character friend code.'),
      );
    }
    return _repository.sendFriendRequest(code);
  }
}
