import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_countdown_text.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_notice.dart';

/// The result of an invitation the host should be told about (sheet 37).
final class HostInvitationNotice {
  const HostInvitationNotice({
    required this.message,
    this.tone = AppNoticeTone.info,
  });

  /// `{nickname} declined the invitation.`
  factory HostInvitationNotice.declined(String nickname) =>
      HostInvitationNotice(message: '$nickname declined the invitation.');

  static const HostInvitationNotice expired = HostInvitationNotice(
    message: 'This invitation expired.',
  );

  static const HostInvitationNotice friendRemoved = HostInvitationNotice(
    message: 'You are no longer friends with this player.',
    tone: AppNoticeTone.warning,
  );

  final String message;
  final AppNoticeTone tone;
}

/// The action slot under the players of the host's waiting room: `Invite
/// friend` or, while an invitation is pending, `Cancel invitation`, with an
/// optional [notice] and error underneath (Paper: sheet 37).
///
/// [hasPendingInvitation] switches the button; [isCancelling] shows its
/// spinner. [rateLimitedUntil] disables Invite until the instant passes and
/// shows `Too many invitations. Try again in 0:42.`
final class HostInvitationPanel extends StatefulComponent {
  const HostInvitationPanel({
    required this.hasPendingInvitation,
    required this.onInvite,
    required this.onCancelInvitation,
    this.isCancelling = false,
    this.notice,
    this.errorText,
    this.rateLimitedUntil,
    this.clockOffset = Duration.zero,
    super.key,
  });

  final bool hasPendingInvitation;
  final VoidCallback onInvite;
  final VoidCallback onCancelInvitation;
  final bool isCancelling;
  final HostInvitationNotice? notice;

  /// Failure under the button (`DUEL_INVITATION_ALREADY_PENDING`, cancel
  /// failed, …).
  final String? errorText;
  final DateTime? rateLimitedUntil;

  /// Server time minus local time.
  final Duration clockOffset;

  @override
  State<HostInvitationPanel> createState() => _HostInvitationPanelState();
}

final class _HostInvitationPanelState extends State<HostInvitationPanel> {
  late Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = null;
    _scheduleRateLimitEnd();
  }

  @override
  void didUpdateComponent(HostInvitationPanel oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.rateLimitedUntil != component.rateLimitedUntil) {
      _scheduleRateLimitEnd();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration? _remaining() {
    final DateTime? until = component.rateLimitedUntil;
    if (until == null) return null;
    final Duration left = until.difference(DateTime.now().add(component.clockOffset));
    return left > Duration.zero ? left : null;
  }

  /// Rebuilds once when the limit passes, which re-enables Invite.
  void _scheduleRateLimitEnd() {
    _timer?.cancel();
    _timer = null;
    final Duration? left = _remaining();
    if (left == null) return;
    _timer = Timer(left, () {
      if (mounted) setState(() {});
    });
  }

  @override
  Component build(BuildContext context) {
    final HostInvitationNotice? note = component.notice;
    final String? error = component.errorText;
    final DateTime? limitedUntil = _remaining() == null ? null : component.rateLimitedUntil;
    return div(classes: 'host-invitation-panel', <Component>[
      if (component.hasPendingInvitation)
        AppButton(
          label: 'Cancel invitation',
          variant: AppButtonVariant.outline,
          size: AppButtonSize.medium,
          expand: true,
          isLoading: component.isCancelling,
          onPressed: component.onCancelInvitation,
        )
      else
        AppButton(
          label: 'Invite friend',
          variant: AppButtonVariant.outline,
          size: AppButtonSize.medium,
          expand: true,
          onPressed: limitedUntil == null ? component.onInvite : null,
        ),
      if (note != null) AppNotice(message: note.message, tone: note.tone),
      if (limitedUntil != null) _RateLimitedError(until: limitedUntil, clockOffset: component.clockOffset),
      if (error != null) AppInlineError(error),
    ]);
  }
}

final class _RateLimitedError extends StatelessComponent {
  const _RateLimitedError({required this.until, required this.clockOffset});

  final DateTime until;
  final Duration clockOffset;

  @override
  Component build(BuildContext context) {
    return p(
      classes: 'host-invitation-panel__rate-limit',
      attributes: const <String, String>{'aria-live': 'polite'},
      <Component>[
        span(<Component>[Component.text('Too many invitations. Try again in ')]),
        AppCountdownText(
          target: until,
          clockOffset: clockOffset,
          style: AppTextStyles.monoBodySm.combine(
            const Styles(color: AppColors.danger, fontWeight: FontWeight.w600),
          ),
        ),
        span(<Component>[Component.text('.')]),
      ],
    );
  }
}

@css
List<StyleRule> get hostInvitationPanelStyles => <StyleRule>[
  css('.host-invitation-panel').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(10)),
  ),
  css('.host-invitation-panel__rate-limit')
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.danger, lineHeight: Unit.pixels(18))),
];
