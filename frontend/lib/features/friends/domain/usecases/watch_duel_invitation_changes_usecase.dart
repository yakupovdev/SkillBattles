import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_entity.dart';
import 'package:skill_battles/features/friends/domain/repository/friends_repository.dart';

/// Every known change of a room invitation (push or own command result).
/// May be duplicated or reordered: compare `version` per invitation id.
final class WatchDuelInvitationChangesUsecase
    implements Usecase<Stream<DuelInvitationEntity>, NoParams> {
  const WatchDuelInvitationChangesUsecase(this._repository);

  final FriendsRepository _repository;

  @override
  Stream<DuelInvitationEntity> call(NoParams params) =>
      _repository.watchDuelInvitationChanges();
}
