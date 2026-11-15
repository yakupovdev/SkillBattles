import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_avatar.dart';
import 'package:skill_battles/core/presentation/widgets/app_countdown_text.dart';
import 'package:skill_battles/core/presentation/widgets/app_deadline_track.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_entity.dart';

/// Guest slot of the host's waiting room while an invitation is PENDING
/// (Paper: "50 Private room — invitation pending"): `Waiting for {nickname}…`
/// with the countdown and the deadline track. Same box as the waiting row.
final class HostInvitationRow extends StatelessWidget {
  const HostInvitationRow({
    required this.invitation,
    this.clockOffset = Duration.zero,
    super.key,
  });

  final DuelInvitationEntity invitation;

  /// Server time minus local time.
  final Duration clockOffset;

  @override
  Widget build(BuildContext context) {
    final String nickname = invitation.recipient.nickname;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: <Widget>[
            Row(
              spacing: 14,
              children: <Widget>[
                AppAvatar(
                  nickname: nickname,
                  size: AppAvatarSize.md,
                  tone: AppAvatarTone.accent,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: <Widget>[
                      Text(
                        'Waiting for $nickname…',
                        style: AppTextStyles.bodyLg.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Invitation sent · the code still works',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: AppCountdownText(
                      target: invitation.expiresAt,
                      clockOffset: clockOffset,
                      style: AppTextStyles.monoBodySm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            AppDeadlineTrack(
              expiresAt: invitation.expiresAt,
              lifetime: invitation.expiresAt.difference(invitation.createdAt),
              clockOffset: clockOffset,
            ),
          ],
        ),
      ),
    );
  }
}
