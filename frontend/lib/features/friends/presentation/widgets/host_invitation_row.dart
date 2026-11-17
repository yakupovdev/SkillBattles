import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_avatar.dart';
import 'package:skill_battles/core/presentation/widgets/app_countdown_text.dart';
import 'package:skill_battles/core/presentation/widgets/app_deadline_track.dart';
import 'package:skill_battles/features/friends/domain/entity/duel_invitation_entity.dart';

/// Guest slot of the host's waiting room while an invitation is PENDING
/// (Paper: "50 Private room — invitation pending"): `Waiting for {nickname}…`
/// with the countdown and the deadline track. Same box as the waiting row.
final class HostInvitationRow extends StatelessComponent {
  const HostInvitationRow({
    required this.invitation,
    this.clockOffset = Duration.zero,
    super.key,
  });

  final DuelInvitationEntity invitation;

  /// Server time minus local time.
  final Duration clockOffset;

  @override
  Component build(BuildContext context) {
    final String nickname = invitation.recipient.nickname;
    return div(classes: 'host-invitation-row', <Component>[
      div(classes: 'host-invitation-row__main', <Component>[
        AppAvatar(nickname: nickname, size: AppAvatarSize.md, tone: AppAvatarTone.accent),
        div(classes: 'host-invitation-row__copy', <Component>[
          p(classes: 'host-invitation-row__title', <Component>[Component.text('Waiting for $nickname…')]),
          p(classes: 'host-invitation-row__subtitle', <Component>[
            Component.text('Invitation sent · the code still works'),
          ]),
        ]),
        div(classes: 'host-invitation-row__countdown', <Component>[
          AppCountdownText(
            target: invitation.expiresAt,
            clockOffset: clockOffset,
            style: AppTextStyles.monoBodySm.combine(
              const Styles(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ]),
      ]),
      AppDeadlineTrack(
        expiresAt: invitation.expiresAt,
        lifetime: invitation.expiresAt.difference(invitation.createdAt),
        clockOffset: clockOffset,
      ),
    ]);
  }
}

@css
List<StyleRule> get hostInvitationRowStyles => <StyleRule>[
  css('.host-invitation-row').styles(
    display: Display.flex,
    padding: const Padding.all(Unit.pixels(15)),
    border: Border.all(color: AppColors.border, width: const Unit.pixels(1)),
    radius: const BorderRadius.circular(Unit.pixels(12)),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(14)),
  ),
  css('.host-invitation-row__main').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(14)),
  ),
  css('.host-invitation-row__copy').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(2)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.host-invitation-row__title')
      .styles(overflow: Overflow.hidden, textOverflow: TextOverflow.ellipsis, whiteSpace: WhiteSpace.noWrap)
      .combine(AppTextStyles.bodyLg)
      .combine(const Styles(fontWeight: FontWeight.w600)),
  css('.host-invitation-row__subtitle').combine(AppTextStyles.bodySm).combine(const Styles(color: AppColors.muted)),
  css('.host-invitation-row__countdown').styles(
    display: Display.flex,
    width: const Unit.pixels(72),
    justifyContent: JustifyContent.end,
    flex: const Flex(shrink: 0),
  ),
];
