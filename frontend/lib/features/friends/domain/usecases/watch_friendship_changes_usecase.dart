import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_entity.dart';
import 'package:skill_battles/features/friends/domain/repository/friends_repository.dart';

/// Every known change of a relationship (push or own command result). May
/// be duplicated or reordered: compare `version` per relationship id.
final class WatchFriendshipChangesUsecase
    implements Usecase<Stream<RelationshipEntity>, NoParams> {
  const WatchFriendshipChangesUsecase(this._repository);

  final FriendsRepository _repository;

  @override
  Stream<RelationshipEntity> call(NoParams params) =>
      _repository.watchFriendshipChanges();
}
