import 'dart:async';

import 'package:material_ui/material_ui.dart';

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
final class HostInvitationPanel extends StatefulWidget {
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
  void didUpdateWidget(HostInvitationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rateLimitedUntil != widget.rateLimitedUntil) {
      _scheduleRateLimitEnd();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration? _remaining() {
    final DateTime? until = widget.rateLimitedUntil;
    if (until == null) return null;
    final Duration left = until.difference(
      DateTime.now().add(widget.clockOffset),
    );
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
  Widget build(BuildContext context) {
    final HostInvitationNotice? note = widget.notice;
    final String? error = widget.errorText;
    final DateTime? limitedUntil = _remaining() == null
        ? null
        : widget.rateLimitedUntil;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: <Widget>[
        if (widget.hasPendingInvitation)
          AppButton(
            label: 'Cancel invitation',
            variant: AppButtonVariant.outline,
            size: AppButtonSize.medium,
            expand: true,
            isLoading: widget.isCancelling,
            onPressed: widget.onCancelInvitation,
          )
        else
          AppButton(
            label: 'Invite friend',
            variant: AppButtonVariant.outline,
            size: AppButtonSize.medium,
            expand: true,
            onPressed: limitedUntil == null ? widget.onInvite : null,
          ),
        if (note != null) AppNotice(message: note.message, tone: note.tone),
        if (limitedUntil != null)
          _RateLimitedError(
            until: limitedUntil,
            clockOffset: widget.clockOffset,
          ),
        if (error != null) AppInlineError(error),
      ],
    );
  }
}

final class _RateLimitedError extends StatelessWidget {
  const _RateLimitedError({required this.until, required this.clockOffset});

  final DateTime until;
  final Duration clockOffset;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTextStyles.bodySm.copyWith(
      color: AppColors.danger,
      height: 18 / 13,
    );
    return Semantics(
      liveRegion: true,
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            const TextSpan(text: 'Too many invitations. Try again in '),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: AppCountdownText(
                target: until,
                clockOffset: clockOffset,
                style: AppTextStyles.monoBodySm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger,
                ),
              ),
            ),
            const TextSpan(text: '.'),
          ],
        ),
        style: style,
      ),
    );
  }
}
