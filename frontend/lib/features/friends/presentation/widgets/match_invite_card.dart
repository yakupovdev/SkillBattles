import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/core/presentation/widgets/app_notification_card.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_entity.dart';

/// What a [MatchInviteCard] shows (Paper: sheet 38, states 1-7).
enum MatchInviteCardStatus {
  /// Both actions enabled, countdown running.
  idle,

  /// Accept in flight.
  accepting,

  /// Decline in flight.
  declining,

  /// The player's own activity blocks accepting; the invitation stays
  /// pending.
  busy,

  /// The invitation expired.
  expired,

  /// The room is gone (cancelled, filled, expired, 404 on accept).
  roomUnavailable,

  /// A network failure; both actions can be retried.
  networkError,

  /// 409 CONTENT_UNAVAILABLE on accept; the invitation stays pending.
  contentUnavailable,
}

/// Overlay card of an incoming private match invitation. Same anatomy as the
/// rematch card: header, deadline row, actions. No room code.
///
/// [disciplineName] is the catalogue display name. The expired look comes
/// from [status], never from the countdown reaching zero.
final class MatchInviteCard extends StatelessComponent {
  const MatchInviteCard({
    required this.invitation,
    required this.disciplineName,
    this.status = MatchInviteCardStatus.idle,
    this.clockOffset = Duration.zero,
    this.onAccept,
    this.onDecline,
    this.onHide,
    super.key,
  });

  final DuelInvitationEntity invitation;
  final String disciplineName;
  final MatchInviteCardStatus status;
  final Duration clockOffset;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onHide;

  /// Keeps the track fraction defined for a zero-length lifetime.
  static const Duration _minLifetime = Duration(seconds: 1);

  @override
  Component build(BuildContext context) {
    final String nickname = invitation.host.nickname;
    final MatchInviteCardStatus s = status;
    final bool isAccepting = s == MatchInviteCardStatus.accepting;
    final bool isDeclining = s == MatchInviteCardStatus.declining;
    final bool isClosed = s == MatchInviteCardStatus.expired || s == MatchInviteCardStatus.roomUnavailable;
    final bool isInFlight = isAccepting || isDeclining;
    final Duration lifetime = invitation.expiresAt.difference(
      invitation.createdAt,
    );
    return AppNotificationCard(
      avatarName: nickname,
      title: 'Match invitation',
      emphasis: nickname,
      text: ' invited you to a private $disciplineName match.',
      expiresAt: invitation.expiresAt,
      lifetime: lifetime < _minLifetime ? _minLifetime : lifetime,
      clockOffset: clockOffset,
      isExpired: isClosed,
      deadlineLabel: switch (s) {
        MatchInviteCardStatus.roomUnavailable => '—',
        MatchInviteCardStatus.expired => '0:00',
        _ => null,
      },
      expiredText: switch (s) {
        MatchInviteCardStatus.expired => 'This invitation expired.',
        MatchInviteCardStatus.roomUnavailable => 'This room is no longer available.',
        _ => null,
      },
      warningText: switch (s) {
        MatchInviteCardStatus.busy => 'Finish or leave your current activity before accepting.',
        MatchInviteCardStatus.contentUnavailable =>
          'Questions for this discipline are unavailable right now. '
              'Try again in a moment.',
        _ => null,
      },
      errorText: s == MatchInviteCardStatus.networkError ? "Couldn't update the invitation. Try again." : null,
      primaryLabel: 'Accept',
      secondaryLabel: 'Decline',
      isPrimaryLoading: isAccepting,
      isSecondaryLoading: isDeclining,
      onPrimary: isClosed || isInFlight || s == MatchInviteCardStatus.busy ? null : onAccept,
      onSecondary: isClosed || isInFlight ? null : onDecline,
      // The × is hidden (slot kept) while a request is in flight.
      onHide: isInFlight ? null : onHide,
    );
  }
}
