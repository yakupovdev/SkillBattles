import 'package:equatable/equatable.dart';

import 'package:skill_battles/core/domain/entity/page_info_entity.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_entity.dart';

/// A page of PENDING requests of one direction (createdAt DESC, id ASC).
final class FriendRequestsPageEntity extends Equatable {
  const FriendRequestsPageEntity({required this.items, required this.page});

  final List<RelationshipEntity> items;
  final PageInfoEntity page;

  @override
  List<Object?> get props => <Object?>[items, page];
}
