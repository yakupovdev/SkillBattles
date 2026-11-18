import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/utils/feature_flags.dart';

/// Colors of a [ProBadge].
enum ProBadgeTone {
  /// Amber text on ink (lists, headers).
  ink(AppColors.proInk, AppColors.pro),

  /// Ink text on amber (account settings).
  amber(AppColors.pro, AppColors.proInk);

  const ProBadgeTone(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

/// The public PRO badge. It is only a badge: Pro never changes Elo,
/// matchmaking or scoring.
final class ProBadge extends StatelessComponent {
  const ProBadge({
    this.compact = false,
    this.tone = ProBadgeTone.ink,
    super.key,
  });

  final bool compact;
  final ProBadgeTone tone;

  @override
  Component build(BuildContext context) {
    if (!FeatureFlags.billing) return const Component.empty();
    return span(
      classes: compact ? 'pro-badge pro-badge--compact' : 'pro-badge',
      styles: Styles(
        color: tone.foreground,
        fontWeight: tone == ProBadgeTone.amber ? FontWeight.w700 : null,
        backgroundColor: tone.background,
      ),
      attributes: const <String, String>{'role': 'img', 'aria-label': 'Pro member'},
      const <Component>[
        span(attributes: <String, String>{'aria-hidden': 'true'}, <Component>[Component.text('PRO')]),
      ],
    );
  }
}

@css
List<StyleRule> get proBadgeStyles => <StyleRule>[
  css('.pro-badge')
      .styles(
        display: Display.inlineBlock,
        padding: const Padding.symmetric(horizontal: Unit.pixels(6), vertical: Unit.pixels(2)),
        radius: const BorderRadius.circular(Unit.pixels(4)),
        flex: const Flex(shrink: 0),
      )
      .combine(AppTextStyles.outcome)
      .combine(
        const Styles(
          fontSize: Unit.pixels(10),
          letterSpacing: Unit.pixels(0.6),
          lineHeight: Unit.pixels(14),
          whiteSpace: WhiteSpace.noWrap,
        ),
      ),
  css('.pro-badge--compact').styles(
    padding: const Padding.symmetric(horizontal: Unit.pixels(4), vertical: Unit.pixels(1)),
    fontSize: const Unit.pixels(9),
    lineHeight: const Unit.pixels(12),
  ),
];
