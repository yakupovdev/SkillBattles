import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/core/presentation/widgets/app_notification_toast.dart';

/// The friend and match-invitation toasts (Paper: sheet 38). Auto-hide after
/// four seconds is the owner's job.
enum FriendsToastVariant {
  /// To the requester when the recipient accepted.
  friendRequestAccepted(AppNotificationToastKind.success),

  /// To the invitee after Accept, and to the host when the friend accepts.
  invitationAccepted(AppNotificationToastKind.success),

  /// To the invitee when a hidden card expired.
  invitationExpired(AppNotificationToastKind.clock),

  /// To the invitee when the host cancelled.
  invitationCancelled(AppNotificationToastKind.info);

  const FriendsToastVariant(this.kind);

  final AppNotificationToastKind kind;

  /// The copy; [nickname] is only used by [friendRequestAccepted].
  String message({String? nickname}) => switch (this) {
    friendRequestAccepted =>
      nickname == null
          ? 'Your friend request was accepted.'
          : '$nickname accepted your friend request.',
    invitationAccepted => 'Invitation accepted. Opening the ready check…',
    invitationExpired => 'The match invitation expired.',
    invitationCancelled => 'The match invitation was cancelled.',
  };
}

/// A toast of one [FriendsToastVariant].
final class FriendsToast extends StatelessWidget {
  const FriendsToast({required this.variant, this.nickname, super.key});

  final FriendsToastVariant variant;
  final String? nickname;

  @override
  Widget build(BuildContext context) {
    return AppNotificationToast(
      kind: variant.kind,
      message: variant.message(nickname: nickname),
    );
  }
}
