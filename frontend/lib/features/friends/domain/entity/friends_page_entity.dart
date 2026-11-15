import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/page_info_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_list_item_entity.dart';

/// A page of accepted friends (friendsSince DESC, relationshipId ASC).
final class FriendsPageEntity extends Equatable {
  const FriendsPageEntity({required this.items, required this.page});

  final List<FriendListItemEntity> items;
  final PageInfoEntity page;

  @override
  List<Object?> get props => <Object?>[items, page];
}
