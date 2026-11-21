import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/utils/reduced_motion.dart';
import 'package:skill_battles/core/presentation/utils/visibility_gate.dart';
import 'package:skill_battles/core/presentation/widgets/app_avatar.dart';
import 'package:skill_battles/core/presentation/widgets/app_count_up.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_layout.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_ring.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_sticker.dart';

/// What the preview card shows at one moment of its 10-second loop.
final class MiniBattleFrame {
  const MiniBattleFrame({
    required this.secondsLeft,
    required this.isOptionSelected,
    required this.hasOpponentAnswered,
    required this.isRatingCounted,
  });

  /// The frame of second [second] of the loop (0..9): a fresh round at 0,
  /// a countdown from 0:45, the answer locked in at 3, the opponent chip at
  /// 5, the rating change at 7.
  factory MiniBattleFrame.atSecond(int second) => MiniBattleFrame(
    secondsLeft: 45 - second,
    isOptionSelected: second >= 3,
    hasOpponentAnswered: second >= 5,
    isRatingCounted: second >= 7,
  );

  /// The designed Paper frame (second 8), also shown under reduced motion.
  static const MiniBattleFrame designed = MiniBattleFrame(
    secondsLeft: 42,
    isOptionSelected: true,
    hasOpponentAnswered: true,
    isRatingCounted: true,
  );

  final int secondsLeft;
  final bool isOptionSelected;
  final bool hasOpponentAnswered;
  final bool isRatingCounted;

  /// Fill of the round progress: 58 % at the designed 0:42, linear in time.
  double get progressPercent => 58 * secondsLeft / 42;
}

/// The blue panel of the hero: rings, the [MiniBattleCard], the
/// [RatingDeltaChip] and two stickers. Decorative (aria-hidden).
///
/// The card loops over 10 seconds, one step per second, only while the
/// panel is on screen and the tab is visible. Reduced motion (and the
/// server) show the designed frame.
final class HeroBattlePreview extends StatefulComponent {
  const HeroBattlePreview({super.key});

  @override
  State<HeroBattlePreview> createState() => _HeroBattlePreviewState();
}

final class _HeroBattlePreviewState extends State<HeroBattlePreview> {
  static const int _loopSeconds = 10;

  late GlobalNodeKey<web.HTMLElement> _panelKey;
  late bool _isLooping;
  late int _second;
  VisibilityGate? _gate;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _panelKey = GlobalNodeKey<web.HTMLElement>();
    _isLooping = kIsWeb && !prefersReducedMotion();
    _second = 0;
    if (_isLooping) context.binding.addPostFrameCallback(_watch);
  }

  void _watch() {
    final web.HTMLElement? panel = _panelKey.currentNode;
    if (!mounted || panel == null) return;
    final VisibilityGate gate = VisibilityGate(threshold: 0.15, onChanged: _onActiveChanged);
    _gate = gate;
    if (!gate.attach(panel)) {
      gate.dispose();
      _gate = null;
      setState(() => _isLooping = false);
    }
  }

  void _onActiveChanged(bool isActive) {
    _timer?.cancel();
    _timer = null;
    if (!isActive || !mounted) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (mounted) setState(() => _second = (_second + 1) % _loopSeconds);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gate?.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final MiniBattleFrame frame = _isLooping ? MiniBattleFrame.atSecond(_second) : MiniBattleFrame.designed;
    return div(
      classes: 'welcome-preview',
      attributes: const <String, String>{'aria-hidden': 'true'},
      <Component>[
        // The panel clips its rings; the fire sticker overhangs its corner
        // from this non-clipping wrapper.
        div(key: _panelKey, classes: 'welcome-preview__panel', <Component>[
          const WelcomeRing(
            size: 420,
            top: -120,
            right: -140,
            color: AppColors.onPrimaryRingOuter,
            periodSeconds: 6,
          ),
          const WelcomeRing(
            size: 260,
            top: -40,
            right: -60,
            color: AppColors.onPrimaryRingInner,
            periodSeconds: 6,
            isInner: true,
          ),
          MiniBattleCard(frame: frame),
          RatingDeltaChip(frame: frame),
          const WelcomeSticker(
            stickerId: StickerId.gg,
            size: 72,
            rotation: 8,
            firstDelay: Duration(milliseconds: 1500),
            position: Position.absolute(right: Unit.pixels(36), bottom: Unit.pixels(36)),
          ),
        ]),
        const WelcomeSticker(
          stickerId: StickerId.fire,
          size: 96,
          rotation: -10,
          firstDelay: Duration(milliseconds: 900),
          position: Position.absolute(left: Unit.pixels(-36), top: Unit.pixels(-32)),
        ),
      ],
    );
  }
}

/// A scaled-down copy of the live battle screen.
final class MiniBattleCard extends StatelessComponent {
  const MiniBattleCard({required this.frame, super.key});

  final MiniBattleFrame frame;

  static String _clock(int seconds) => '0:${seconds.toString().padLeft(2, '0')}';

  @override
  Component build(BuildContext context) {
    return div(classes: 'mini-card', <Component>[
      const _MiniHeader(),
      div(classes: 'mini-card__track', <Component>[
        div(
          classes: 'mini-card__fill',
          styles: Styles(width: Unit.percent(frame.progressPercent)),
          const <Component>[],
        ),
      ]),
      div(classes: 'mini-card__body', <Component>[
        div(classes: 'mini-card__row', <Component>[
          const span(classes: 'mini-card__topic', <Component>[Component.text('Percentages')]),
          span(classes: 'mini-card__timer', <Component>[Component.text(_clock(frame.secondsLeft))]),
        ]),
        const p(classes: 'mini-card__question', <Component>[
          Component.text(
            'A jacket costs \$80. It is discounted by 25%, then a 10% tax is added. What is the final price?',
          ),
        ]),
        div(classes: 'mini-card__options', <Component>[
          const _MiniOption(letter: 'A', value: '\$60.00', isSelected: false),
          _MiniOption(letter: 'B', value: '\$66.00', isSelected: frame.isOptionSelected),
          const _MiniOption(letter: 'C', value: '\$68.00', isSelected: false),
          const _MiniOption(letter: 'D', value: '\$72.00', isSelected: false),
        ]),
        div(classes: 'mini-card__status', <Component>[
          div(
            classes: frame.isOptionSelected ? 'mini-card__locked mini-card__on' : 'mini-card__locked',
            const <Component>[
              AppDot(color: AppColors.primary, size: 7),
              span(<Component>[Component.text('Answer locked in.')]),
            ],
          ),
          div(
            classes: frame.hasOpponentAnswered ? 'mini-card__answered mini-card__on' : 'mini-card__answered',
            const <Component>[
              AppSvgIcon(AppIcons.checkSmall, width: 10, height: 10),
              span(<Component>[Component.text('timur.b answered')]),
            ],
          ),
        ]),
      ]),
    ]);
  }
}

final class _MiniHeader extends StatelessComponent {
  const _MiniHeader();

  @override
  Component build(BuildContext context) {
    return div(classes: 'mini-card__header', <Component>[
      div(classes: 'mini-card__lane', const <Component>[
        AppAvatar(nickname: 'aliya_k', size: AppAvatarSize.sm),
        div(classes: 'mini-card__player', <Component>[
          span(classes: 'mini-card__name', <Component>[Component.text('aliya_k')]),
          span(classes: 'mini-card__rating mini-card__rating--you', <Component>[Component.text('1032')]),
        ]),
      ]),
      div(classes: 'mini-card__meter', <Component>[
        span(classes: 'mini-card__round', <Component>[Component.text('MATH · ROUND 3 OF 5')]),
        div(classes: 'mini-card__pips', const <Component>[
          _Pip(color: AppColors.ink),
          _Pip(color: AppColors.ink),
          _Pip(color: AppColors.primary),
          _Pip(color: AppColors.border),
          _Pip(color: AppColors.border),
        ]),
      ]),
      div(classes: 'mini-card__lane mini-card__lane--end', const <Component>[
        div(classes: 'mini-card__player mini-card__player--end', <Component>[
          span(classes: 'mini-card__name', <Component>[Component.text('timur.b')]),
          span(classes: 'mini-card__rating', <Component>[Component.text('1048')]),
        ]),
        AppAvatar(nickname: 'timur.b', size: AppAvatarSize.sm, tone: AppAvatarTone.accent),
      ]),
    ]);
  }
}

final class _Pip extends StatelessComponent {
  const _Pip({required this.color});

  final Color color;

  @override
  Component build(BuildContext context) {
    return span(
      classes: 'mini-card__pip',
      styles: Styles(backgroundColor: color),
      const <Component>[],
    );
  }
}

final class _MiniOption extends StatelessComponent {
  const _MiniOption({required this.letter, required this.value, required this.isSelected});

  final String letter;
  final String value;
  final bool isSelected;

  @override
  Component build(BuildContext context) {
    return div(classes: isSelected ? 'mini-option mini-option--selected' : 'mini-option', <Component>[
      span(classes: 'mini-option__letter', <Component>[Component.text(letter)]),
      span(classes: 'mini-option__value', <Component>[Component.text(value)]),
    ]);
  }
}

/// The tilted "MATH RATING 1032 → 1050 +18" chip over the panel's corner.
final class RatingDeltaChip extends StatelessComponent {
  const RatingDeltaChip({required this.frame, super.key});

  final MiniBattleFrame frame;

  @override
  Component build(BuildContext context) {
    return div(classes: 'rating-chip', <Component>[
      const span(classes: 'rating-chip__label', <Component>[Component.text('MATH RATING')]),
      const span(classes: 'rating-chip__old', <Component>[Component.text('1032')]),
      const AppSvgIcon(AppIcons.arrowSmall, width: 16, height: 16, color: AppColors.ink),
      span(classes: 'rating-chip__new', <Component>[
        AppCountUp(from: 1032, to: 1050, play: frame.isRatingCounted),
      ]),
      span(
        classes: frame.isRatingCounted ? 'rating-chip__delta rating-chip__delta--on' : 'rating-chip__delta',
        const <Component>[Component.text('+18')],
      ),
    ]);
  }
}

@css
List<StyleRule> get heroBattlePreviewStyles => <StyleRule>[
  css('.welcome-preview').styles(
    position: const Position.relative(),
    width: const Unit.pixels(552),
    height: const Unit.pixels(580),
    flex: const Flex(shrink: 0),
    raw: const <String, String>{'animation': 'welcome-slide-in 700ms $welcomeEase 200ms both'},
  ),
  css.keyframes('welcome-slide-in', <String, Styles>{
    'from': const Styles(opacity: 0, transform: Transform.translate(x: Unit.pixels(32))),
    'to': const Styles(opacity: 1, transform: Transform.none),
  }),
  css('.welcome-preview__panel').styles(
    position: const Position.relative(),
    width: const Unit.percent(100),
    height: const Unit.percent(100),
    padding: const Padding.only(top: Unit.pixels(64), left: Unit.pixels(40), right: Unit.pixels(40)),
    radius: const BorderRadius.circular(Unit.pixels(24)),
    backgroundColor: AppColors.primary,
    raw: const <String, String>{'overflow': 'clip'},
  ),
  css('.mini-card').styles(
    position: const Position.relative(),
    radius: const BorderRadius.circular(Unit.pixels(16)),
    overflow: Overflow.hidden,
    backgroundColor: AppColors.white,
    raw: <String, String>{
      'box-shadow': '0 24px 64px ${AppColors.dialogShadow.value}',
      'animation': 'welcome-card-rise 500ms $welcomeEase 350ms both',
      'font-variant-numeric': 'tabular-nums',
    },
  ),
  css.keyframes('welcome-card-rise', <String, Styles>{
    'from': const Styles(opacity: 0, transform: Transform.translate(y: Unit.pixels(24))),
    'to': const Styles(opacity: 1, transform: Transform.none),
  }),
  css('.mini-card__header').styles(
    display: Display.flex,
    padding: const Padding.symmetric(horizontal: Unit.pixels(20), vertical: Unit.pixels(18)),
    justifyContent: JustifyContent.spaceBetween,
    alignItems: AlignItems.center,
  ),
  css('.mini-card__lane').styles(
    display: Display.flex,
    width: const Unit.pixels(132),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(8)),
    flex: const Flex(shrink: 0),
  ),
  css('.mini-card__lane--end').styles(justifyContent: JustifyContent.end),
  css('.mini-card__player').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(2)),
  ),
  css('.mini-card__player--end').styles(alignItems: AlignItems.end),
  css('.mini-card__name').combine(AppTextStyles.bodySm).combine(const Styles(fontWeight: FontWeight.w600)),
  css('.mini-card__rating').combine(AppTextStyles.monoBodySm).combine(const Styles(fontWeight: FontWeight.w500)),
  css('.mini-card__rating--you').styles(color: AppColors.primary),
  css('.mini-card__meter').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.center,
    gap: const Gap.row(Unit.pixels(8)),
  ),
  css('.mini-card__round')
      .combine(AppTextStyles.monoCaption)
      .combine(const Styles(color: AppColors.muted, letterSpacing: Unit.em(0.08), whiteSpace: WhiteSpace.noWrap)),
  css('.mini-card__pips').styles(display: Display.flex, gap: const Gap.column(Unit.pixels(8))),
  css('.mini-card__pip').styles(
    width: const Unit.pixels(20),
    height: const Unit.pixels(4),
    radius: const BorderRadius.circular(Unit.pixels(2)),
  ),
  css('.mini-card__track').styles(height: const Unit.pixels(4), backgroundColor: AppColors.divider),
  css('.mini-card__fill').styles(
    height: const Unit.percent(100),
    backgroundColor: AppColors.primary,
    raw: const <String, String>{'transition': 'width 1s linear'},
  ),
  css('.mini-card__body').styles(
    display: Display.flex,
    padding: const Padding.only(
      top: Unit.pixels(22),
      left: Unit.pixels(20),
      right: Unit.pixels(20),
      bottom: Unit.pixels(20),
    ),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(16)),
  ),
  css('.mini-card__row').styles(
    display: Display.flex,
    justifyContent: JustifyContent.spaceBetween,
    alignItems: AlignItems.center,
  ),
  css('.mini-card__topic')
      .combine(AppTextStyles.bodyXs)
      .combine(
        const Styles(
          padding: Padding.symmetric(horizontal: Unit.pixels(8), vertical: Unit.pixels(4)),
          radius: BorderRadius.circular(Unit.pixels(6)),
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
          backgroundColor: AppColors.primaryTint,
        ),
      ),
  css('.mini-card__timer')
      .combine(AppTextStyles.monoSm)
      .combine(const Styles(fontSize: Unit.pixels(20), lineHeight: Unit.pixels(24))),
  css('.mini-card__question')
      .combine(AppTextStyles.headlineMd)
      .combine(const Styles(fontSize: Unit.pixels(19), letterSpacing: Unit.em(-0.01), lineHeight: Unit.pixels(26))),
  css('.mini-card__options').styles(
    display: Display.grid,
    gap: const Gap(row: Unit.pixels(8), column: Unit.pixels(8)),
    raw: const <String, String>{'grid-template-columns': '1fr 1fr'},
  ),
  css('.mini-option').styles(
    display: Display.flex,
    height: const Unit.pixels(44),
    padding: const Padding.symmetric(horizontal: Unit.pixels(12)),
    border: Border.all(color: AppColors.border, width: const Unit.pixels(1)),
    radius: const BorderRadius.circular(Unit.pixels(10)),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(10)),
    raw: const <String, String>{
      'transition': 'border-color 200ms ease, background-color 200ms ease, box-shadow 200ms ease',
    },
  ),
  css('.mini-option--selected').styles(
    border: Border.all(color: AppColors.primary, width: const Unit.pixels(1)),
    backgroundColor: AppColors.primarySurface,
    raw: <String, String>{'box-shadow': 'inset 0 0 0 0.5px ${AppColors.primary.value}'},
  ),
  css('.mini-option__letter')
      .combine(AppTextStyles.monoBodySm)
      .combine(
        const Styles(
          display: Display.flex,
          width: Unit.pixels(24),
          height: Unit.pixels(24),
          radius: BorderRadius.circular(Unit.pixels(6)),
          justifyContent: JustifyContent.center,
          alignItems: AlignItems.center,
          fontWeight: FontWeight.w600,
          backgroundColor: AppColors.surface,
          raw: <String, String>{'transition': 'background-color 200ms ease, color 200ms ease'},
        ),
      ),
  css('.mini-option--selected .mini-option__letter').styles(color: AppColors.white, backgroundColor: AppColors.primary),
  css('.mini-option__value').combine(AppTextStyles.bodyMd),
  css('.mini-card__status').styles(
    display: Display.flex,
    justifyContent: JustifyContent.spaceBetween,
    alignItems: AlignItems.center,
  ),
  css('.mini-card__locked')
      .combine(AppTextStyles.bodySm)
      .combine(
        const Styles(
          display: Display.flex,
          opacity: 0,
          alignItems: AlignItems.center,
          gap: Gap.column(Unit.pixels(8)),
          raw: <String, String>{'transition': 'opacity 300ms ease'},
        ),
      ),
  css('.mini-card__answered')
      .combine(AppTextStyles.bodyXs)
      .combine(
        Styles(
          display: Display.flex,
          padding: const Padding.symmetric(horizontal: Unit.pixels(8), vertical: Unit.pixels(3)),
          radius: const BorderRadius.circular(Unit.pixels(999)),
          opacity: 0,
          alignItems: AlignItems.center,
          gap: const Gap.column(Unit.pixels(4)),
          color: AppColors.success,
          fontWeight: FontWeight.w600,
          backgroundColor: AppColors.successSurface,
          raw: <String, String>{
            'transform': 'scale(0.8)',
            'transition': 'opacity 300ms ease, transform 300ms cubic-bezier(0.34, 1.56, 0.64, 1)',
          },
        ),
      ),
  css('.mini-card__on').styles(opacity: 1),
  css('.mini-card__answered.mini-card__on').styles(transform: Transform.scale(1)),
  css('.rating-chip').styles(
    display: Display.flex,
    position: const Position.absolute(left: Unit.pixels(48), bottom: Unit.pixels(44)),
    padding: const Padding.symmetric(horizontal: Unit.pixels(14), vertical: Unit.pixels(10)),
    radius: const BorderRadius.circular(Unit.pixels(12)),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(12)),
    backgroundColor: AppColors.white,
    raw: <String, String>{
      'box-shadow': '0 8px 24px ${AppColors.dialogShadow.value}',
      'transform': 'rotate(-3deg)',
      'animation': 'welcome-chip-pop 400ms cubic-bezier(0.34, 1.56, 0.64, 1) 850ms both',
      'font-variant-numeric': 'tabular-nums',
    },
  ),
  css.keyframes('welcome-chip-pop', <String, Styles>{
    'from': const Styles(opacity: 0, raw: <String, String>{'transform': 'rotate(-3deg) scale(0.8)'}),
    'to': const Styles(opacity: 1, raw: <String, String>{'transform': 'rotate(-3deg) scale(1)'}),
  }),
  css('.rating-chip__label')
      .combine(AppTextStyles.monoCaption)
      .combine(const Styles(color: AppColors.muted, letterSpacing: Unit.em(0.08), whiteSpace: WhiteSpace.noWrap)),
  css('.rating-chip__old')
      .combine(AppTextStyles.monoSm)
      .combine(const Styles(color: AppColors.faint, fontSize: Unit.pixels(18), lineHeight: Unit.pixels(22))),
  css('.rating-chip__new')
      .combine(AppTextStyles.monoSm)
      .combine(const Styles(fontSize: Unit.pixels(18), lineHeight: Unit.pixels(22))),
  css('.rating-chip__delta')
      .combine(AppTextStyles.monoBodySm)
      .combine(
        Styles(
          padding: const Padding.symmetric(horizontal: Unit.pixels(7), vertical: Unit.pixels(2)),
          radius: const BorderRadius.circular(Unit.pixels(6)),
          opacity: 0,
          color: AppColors.success,
          fontSize: const Unit.pixels(13),
          fontWeight: FontWeight.w600,
          lineHeight: const Unit.pixels(18),
          backgroundColor: AppColors.successSurface,
          raw: const <String, String>{
            'transform': 'scale(0.8)',
            'transition': 'opacity 300ms ease, transform 300ms cubic-bezier(0.34, 1.56, 0.64, 1)',
          },
        ),
      ),
  css('.rating-chip__delta--on').styles(
    opacity: 1,
    transform: Transform.scale(1),
    raw: const <String, String>{'transition-delay': '600ms'},
  ),
  css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), <StyleRule>[
    css('.welcome-preview').styles(raw: const <String, String>{'animation': 'none'}),
    css('.mini-card').styles(raw: const <String, String>{'animation': 'none'}),
    css('.rating-chip').styles(raw: const <String, String>{'animation': 'none'}),
    css('.mini-card__fill').styles(raw: const <String, String>{'transition': 'none'}),
  ]),
];
