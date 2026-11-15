import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_card.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_code_entity.dart';
import 'package:skill_battles/features/friends/presentation/controllers/friend_code_input.dart';

/// The player's own friend code with a Copy button (Paper: "36 Friends —
/// Component sheet").
///
/// Put it under a `Skeletonizer` with mock data while the code loads; the
/// eyebrow and the explanation stay visible. When [hasFailed] the code and
/// the button are replaced by an error line and [onRetry].
final class FriendCodeCard extends StatelessWidget {
  const FriendCodeCard({
    required this.code,
    this.hasFailed = false,
    this.onRetry,
    super.key,
  });

  final FriendCodeEntity code;
  final bool hasFailed;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: <Widget>[
          const Skeleton.keep(child: AppEyebrow('Your friend code')),
          if (hasFailed)
            _LoadError(onRetry: onRetry)
          else
            _CodeAndCopy(code: code.code),
          Skeleton.keep(
            child: Text(
              'Friends enter this code to send you a request. '
              'It is not a room code, and only you can see it.',
              style: AppTextStyles.bodySm.copyWith(
                height: 18 / 13,
                color: AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 12,
      children: <Widget>[
        const Expanded(
          child: AppInlineError("Couldn't load your friend code."),
        ),
        AppButton(
          label: 'Try again',
          onPressed: onRetry,
          variant: AppButtonVariant.outline,
          size: AppButtonSize.field,
        ),
      ],
    );
  }
}

final class _CodeAndCopy extends StatelessWidget {
  const _CodeAndCopy({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: <Widget>[
        Semantics(
          label: 'Friend code ${code.split('').join(' ')}',
          excludeSemantics: true,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              FriendCodeInput.grouped(code),
              style: AppTextStyles.monoLg.copyWith(
                fontSize: 30,
                height: 36 / 30,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.02 * 30,
                color: AppColors.ink,
              ),
              maxLines: 1,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: _CopyButton(code: code),
        ),
      ],
    );
  }
}

/// "Copy code", which reads "Copied" with a check for two seconds.
final class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.code});

  final String code;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

final class _CopyButtonState extends State<_CopyButton> {
  static const Duration _copiedFor = Duration(seconds: 2);

  late bool _isCopied;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _isCopied = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    // The canonical 12 characters, not the grouped display text.
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    _timer?.cancel();
    setState(() => _isCopied = true);
    _timer = Timer(_copiedFor, () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isSkeleton = Skeletonizer.maybeOf(context)?.enabled ?? false;
    return Semantics(
      liveRegion: true,
      child: AppButton(
        label: _isCopied ? 'Copied' : 'Copy code',
        variant: AppButtonVariant.dark,
        size: AppButtonSize.medium,
        icon: _isCopied
            ? const AppSvgIcon(AppIcons.check, width: 16, height: 16)
            : const AppSvgIcon(AppIcons.copy, width: 16, height: 16),
        onPressed: isSkeleton ? null : _copy,
      ),
    );
  }
}
