import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/features/friends/domain/repository/friends_repository.dart';

/// The signed-in user's id (`null` when signed out): current value first,
/// then every session change. Repeats the same id on token refresh; a
/// different id means another account signed in.
final class WatchSignedInUserUsecase
    implements Usecase<Stream<String?>, NoParams> {
  const WatchSignedInUserUsecase(this._repository);

  final FriendsRepository _repository;

  @override
  Stream<String?> call(NoParams params) => _repository.watchSignedInUser();
}
