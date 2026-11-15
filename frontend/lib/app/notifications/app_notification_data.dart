import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/core/presentation/widgets/app_notification_toast.dart';

/// Most cards the overlay shows at once, across all sources.
const int maxVisibleNotificationPrompts = 3;

/// An actionable notification of any source, ready to draw as an
/// `AppNotificationCard`. A source adapter (`rematch_notifications.dart`)
/// builds these from its own kind of item; the overlay merges them.
final class AppNotificationPrompt {
  const AppNotificationPrompt({
    required this.id,
    required this.expiresAt,
    required this.avatarName,
    required this.title,
    required this.text,
    required this.primaryLabel,
    required this.secondaryLabel,
    this.emphasis,
    this.hasDeadline = true,
    this.deadlineLabel,
    this.doneText,
    this.lifetime = Duration.zero,
    this.clockOffset = Duration.zero,
    this.isExpired = false,
    this.expiredText,
    this.warningText,
    this.errorText,
    this.onPrimary,
    this.onSecondary,
    this.isPrimaryLoading = false,
    this.isSecondaryLoading = false,
    this.onHide,
  });

  /// Unique across sources (prefix it with the source, e.g. `rematch:<id>`);
  /// used as the widget key.
  final String id;

  /// Deadline; cards of all sources are sorted by it, soonest first. For a
  /// card without a countdown ([hasDeadline] false) it is only the sort key.
  final DateTime expiresAt;

  /// Whether the card draws the deadline row (a friend request does not).
  final bool hasDeadline;

  /// Replaces the countdown text (`—` once the deadline no longer applies).
  final String? deadlineLabel;

  /// Replaces the actions with a success line (an accepted friend request).
  final String? doneText;
  final String avatarName;
  final String title;
  final String? emphasis;
  final String text;
  final Duration lifetime;
  final Duration clockOffset;
  final bool isExpired;
  final String? expiredText;
  final String? warningText;
  final String? errorText;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;
  final bool isPrimaryLoading;
  final bool isSecondaryLoading;
  final VoidCallback? onHide;

  /// Merges the prompts of every source, sorted by deadline, and keeps at
  /// most [maxVisibleNotificationPrompts].
  static List<AppNotificationPrompt> mergeVisible(
    Iterable<List<AppNotificationPrompt>> sources,
  ) {
    final List<AppNotificationPrompt> all =
        <AppNotificationPrompt>[
          for (final List<AppNotificationPrompt> source in sources) ...source,
        ]..sort(
          (AppNotificationPrompt a, AppNotificationPrompt b) =>
              a.expiresAt.compareTo(b.expiresAt),
        );
    return all.take(maxVisibleNotificationPrompts).toList(growable: false);
  }
}

/// A transient message of any source, drawn as an `AppNotificationToast`.
final class AppNotificationToastData {
  const AppNotificationToastData({
    required this.id,
    required this.kind,
    required this.message,
  });

  /// Unique across sources and the session.
  final String id;
  final AppNotificationToastKind kind;
  final String message;
}
