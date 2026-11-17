import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/core/presentation/widgets/app_notification_card.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_entity.dart';

/// Which answer to an incoming friend request is in flight.
enum FriendRequestCardAction { accepting, declining }

/// Overlay card of an incoming friend request (Paper: sheet 38). Same anatomy
/// as the rematch card without the deadline: friend requests never expire.
///
/// [isDone] replaces the actions with `You and {nickname} are now friends.`;
/// the owner removes the card after four seconds.
final class FriendRequestCard extends StatelessComponent {
  const FriendRequestCard({
    required this.request,
    this.action,
    this.hasFailed = false,
    this.isDone = false,
    this.onAccept,
    this.onDecline,
    this.onHide,
    super.key,
  });

  final RelationshipEntity request;
  final FriendRequestCardAction? action;
  final bool hasFailed;
  final bool isDone;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  /// Hides the card; the × is hidden (its slot kept) while a request is in
  /// flight.
  final VoidCallback? onHide;

  @override
  Component build(BuildContext context) {
    final String nickname = request.requester.nickname;
    final bool isBusy = action != null;
    return AppNotificationCard(
      avatarName: nickname,
      title: 'Friend request',
      emphasis: nickname,
      text: ' wants to add you as a friend.',
      primaryLabel: 'Accept',
      secondaryLabel: 'Decline',
      isPrimaryLoading: action == FriendRequestCardAction.accepting,
      isSecondaryLoading: action == FriendRequestCardAction.declining,
      onPrimary: isBusy ? null : onAccept,
      onSecondary: isBusy ? null : onDecline,
      onHide: isBusy ? null : onHide,
      errorText: hasFailed && !isBusy ? "Couldn't update the friend request. Try again." : null,
      doneText: isDone ? 'You and $nickname are now friends.' : null,
    );
  }
}
