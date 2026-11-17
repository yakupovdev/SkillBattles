import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/js_interop.dart';
import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/skeleton/skeletonizer.dart';
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
final class FriendCodeCard extends StatelessComponent {
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
  Component build(BuildContext context) {
    return AppCard(
      color: AppColors.white,
      classes: 'friend-code-card',
      child: Component.fragment(<Component>[
        Skeleton.keep(child: const AppEyebrow('Your friend code')),
        if (hasFailed) _LoadError(onRetry: onRetry) else _CodeAndCopy(code: code.code),
        Skeleton.keep(
          child: p(classes: 'friend-code-card__note', <Component>[
            Component.text(
              'Friends enter this code to send you a request. '
              'It is not a room code, and only you can see it.',
            ),
          ]),
        ),
      ]),
    );
  }
}

/// Writes [text] to the system clipboard.
Future<void> writeClipboardText(String text) => web.window.navigator.clipboard.writeText(text).toDart;

final class _LoadError extends StatelessComponent {
  const _LoadError({required this.onRetry});

  final VoidCallback? onRetry;

  @override
  Component build(BuildContext context) {
    return div(classes: 'friend-code-card__error', <Component>[
      const AppInlineError("Couldn't load your friend code."),
      AppButton(
        label: 'Try again',
        onPressed: onRetry,
        variant: AppButtonVariant.outline,
        size: AppButtonSize.field,
      ),
    ]);
  }
}

final class _CodeAndCopy extends StatelessComponent {
  const _CodeAndCopy({required this.code});

  final String code;

  @override
  Component build(BuildContext context) {
    return div(classes: 'friend-code-card__code-block', <Component>[
      p(
        classes: 'friend-code-card__code',
        attributes: <String, String>{'role': 'img', 'aria-label': 'Friend code ${code.split('').join(' ')}'},
        <Component>[Component.text(FriendCodeInput.grouped(code))],
      ),
      _CopyButton(code: code),
    ]);
  }
}

/// "Copy code", which reads "Copied" with a check for two seconds.
final class _CopyButton extends StatefulComponent {
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
    await writeClipboardText(component.code);
    if (!mounted) return;
    _timer?.cancel();
    setState(() => _isCopied = true);
    _timer = Timer(_copiedFor, () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  @override
  Component build(BuildContext context) {
    final bool isSkeleton = Skeletonizer.isEnabled(context);
    return div(
      classes: 'friend-code-card__copy',
      attributes: const <String, String>{'aria-live': 'polite'},
      <Component>[
        AppButton(
          label: _isCopied ? 'Copied' : 'Copy code',
          variant: AppButtonVariant.dark,
          size: AppButtonSize.medium,
          icon: _isCopied
              ? const AppSvgIcon(AppIcons.check, width: 16, height: 16)
              : const AppSvgIcon(AppIcons.copy, width: 16, height: 16),
          onPressed: isSkeleton ? null : _copy,
        ),
      ],
    );
  }
}

@css
List<StyleRule> get friendCodeCardStyles => <StyleRule>[
  css('.friend-code-card').styles(gap: const Gap.row(Unit.pixels(16))),
  css('.friend-code-card__note')
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.muted, lineHeight: Unit.pixels(18))),
  css('.friend-code-card__error').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(12)),
  ),
  css('.friend-code-card__error > .app-inline-error').styles(
    minWidth: Unit.zero,
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.friend-code-card__code-block').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(16)),
  ),
  css('.friend-code-card__code')
      .styles(
        maxWidth: const Unit.percent(100),
        overflow: Overflow.hidden,
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.monoLg)
      .combine(
        const Styles(
          color: AppColors.ink,
          fontSize: Unit.pixels(30),
          fontWeight: FontWeight.w600,
          letterSpacing: Unit.em(0.02),
          lineHeight: Unit.pixels(36),
        ),
      ),
  css('.friend-code-card__copy').styles(display: Display.flex),
];
