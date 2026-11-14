import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/core/presentation/widgets/app_notice.dart';
import 'package:skill_battles/features/account/domain/entity/activity_entity.dart';

/// Offers to resume the account's single live activity after a reload.
final class HomeActivityBanner extends StatelessWidget {
  const HomeActivityBanner({required this.activity, super.key});

  final ActivityEntity activity;

  @override
  Widget build(BuildContext context) {
    final String? resourceId = activity.resourceId;
    final String? battleId = activity.battleId ?? resourceId;
    final (String message, VoidCallback? onResume) = switch (activity) {
      ActivityEntity(type: ActivityType.battle) => (
        'You have a match in progress.',
        battleId == null ? null : () => context.goBattle(battleId),
      ),
      ActivityEntity(type: ActivityType.queue) => (
        "You're still searching for a ranked match.",
        () => context.goRankedSearch(entryId: resourceId),
      ),
      ActivityEntity(
        type: ActivityType.privateDuel,
        resourceKind: ActivityResourceKind.rematch,
      ) =>
        (
          'Your rematch request is waiting for the other player.',
          resourceId == null ? null : () => context.goBattleResult(resourceId),
        ),
      ActivityEntity(type: ActivityType.privateDuel) => (
        'Your private room is open.',
        () => context.goPrivateDuel(duelId: resourceId),
      ),
      ActivityEntity(type: ActivityType.none) => ('', null),
    };
    if (activity.isNone) return const SizedBox.shrink();
    return AppNotice(
      message: message,
      tone: AppNoticeTone.warning,
      actionLabel: 'Resume',
      onAction: onResume,
    );
  }
}
