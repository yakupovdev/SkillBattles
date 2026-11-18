import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/widgets/app_avatar.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/pro_badge.dart';
import 'package:skill_battles/features/friends/domain/entity/relationship_entity.dart';

/// Which request of a row is in flight.
enum FriendRequestRowAction { accepting, declining, cancelling }

/// One incoming (Accept / Decline) or outgoing (Cancel request) friend
/// request. The in-flight state is per row.
///
/// [now] is the clock of the relative time in the subtitle. A `null` callback
/// disables that button (use it for a mock row while loading).
final class FriendRequestRow extends StatelessComponent {
  const FriendRequestRow({
    required this.request,
    required this.now,
    this.action,
    this.hasFailed = false,
    this.onAccept,
    this.onDecline,
    this.onCancel,
    super.key,
  });

  final RelationshipEntity request;
  final DateTime now;
  final FriendRequestRowAction? action;

  /// The last attempt failed: show the inline error under the row.
  final bool hasFailed;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onCancel;

  @override
  Component build(BuildContext context) {
    final bool isIncoming = request.isIncoming;
    final bool isBusy = action != null;
    final String subtitle =
        '${isIncoming ? 'Wants to add you' : 'Request sent'} · '
        '${DisplayFormatters.relative(request.createdAt, now)}';
    return div(classes: 'friend-request-row', <Component>[
      div(classes: 'friend-request-row__main', <Component>[
        _Identity(
          nickname: request.otherPlayer.nickname,
          isPro: request.otherPlayer.isPro,
          subtitle: subtitle,
        ),
        if (isIncoming) ...<Component>[
          div(classes: 'friend-request-row__button', <Component>[
            AppButton(
              label: 'Accept',
              size: AppButtonSize.field,
              expand: true,
              isLoading: action == FriendRequestRowAction.accepting,
              onPressed: isBusy ? null : onAccept,
            ),
          ]),
          div(classes: 'friend-request-row__button', <Component>[
            AppButton(
              label: 'Decline',
              variant: AppButtonVariant.outline,
              size: AppButtonSize.field,
              expand: true,
              isLoading: action == FriendRequestRowAction.declining,
              onPressed: isBusy ? null : onDecline,
            ),
          ]),
        ] else
          div(classes: 'friend-request-row__button friend-request-row__button--wide', <Component>[
            AppButton(
              label: 'Cancel request',
              variant: AppButtonVariant.outline,
              size: AppButtonSize.field,
              expand: true,
              isLoading: action == FriendRequestRowAction.cancelling,
              onPressed: isBusy ? null : onCancel,
            ),
          ]),
      ]),
      if (hasFailed && !isBusy)
        const div(classes: 'friend-request-row__error', <Component>[
          AppInlineError("Couldn't update the friend request. Try again."),
        ]),
    ]);
  }
}

final class _Identity extends StatelessComponent {
  const _Identity({
    required this.nickname,
    required this.isPro,
    required this.subtitle,
  });

  final String nickname;
  final bool isPro;
  final String subtitle;

  @override
  Component build(BuildContext context) {
    return div(classes: 'friend-request-row__identity', <Component>[
      AppAvatar(nickname: nickname, tone: AppAvatarTone.accent),
      div(classes: 'friend-request-row__copy', <Component>[
        div(classes: 'friend-request-row__name-line', <Component>[
          span(classes: 'friend-request-row__nickname', <Component>[Component.text(nickname)]),
          if (isPro) const ProBadge(),
        ]),
        p(classes: 'friend-request-row__subtitle', <Component>[Component.text(subtitle)]),
      ]),
    ]);
  }
}

@css
List<StyleRule> get friendRequestRowStyles => <StyleRule>[
  css('.friend-request-row').styles(
    display: Display.flex,
    padding: const Padding.symmetric(vertical: Unit.pixels(12)),
    border: const Border.only(
      bottom: BorderSide(color: AppColors.divider, width: Unit.pixels(1)),
    ),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(8)),
  ),
  css('.friend-request-row__main').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(14)),
  ),
  css('.friend-request-row__button').styles(
    width: const Unit.pixels(112),
    flex: const Flex(shrink: 0),
  ),
  css('.friend-request-row__button--wide').styles(width: const Unit.pixels(160)),
  // The error lines up with the nickname: avatar (36) + gap (14).
  css('.friend-request-row__error').styles(padding: const Padding.only(left: Unit.pixels(50))),
  css('.friend-request-row__identity').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(14)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.friend-request-row__copy').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(2)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.friend-request-row__name-line').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    maxWidth: const Unit.percent(100),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(8)),
  ),
  css('.friend-request-row__nickname')
      .styles(
        minWidth: Unit.zero,
        overflow: Overflow.hidden,
        flex: const Flex(grow: 0, shrink: 1, basis: Unit.auto),
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.bodyLg)
      .combine(const Styles(fontWeight: FontWeight.w600)),
  css('.friend-request-row__subtitle')
      .styles(
        maxWidth: const Unit.percent(100),
        overflow: Overflow.hidden,
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.muted)),
];
