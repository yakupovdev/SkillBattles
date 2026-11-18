import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_shadows.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_caret.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_labels.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_view.dart';

/// Whose bubble it is; decides colors, caret side and caption.
enum StickerBubbleVariant { outgoing, incoming, notSent }

/// A 120 px bubble under a sender's avatar: the sticker plays once, with a
/// caption under it (Paper: "32 Battle stickers — Component sheet", E-G).
///
/// Give it a `ValueKey` of the message (submission or event id) so a
/// re-send restarts the animation. Expiry is owned by the bloc.
final class StickerBubble extends StatelessComponent {
  const StickerBubble({required this.variant, required this.stickerId, this.caption = '', super.key});

  static const double width = 120;

  final StickerBubbleVariant variant;
  final StickerId stickerId;

  /// `You`, the opponent's nickname; ignored for [StickerBubbleVariant.notSent].
  final String caption;

  @override
  Component build(BuildContext context) {
    final (Color fill, Color line, Color dot, Color text, String label) = switch (variant) {
      StickerBubbleVariant.outgoing => (
        AppColors.primarySurface,
        AppColors.primaryLine,
        AppColors.primary,
        AppColors.primary,
        caption,
      ),
      StickerBubbleVariant.incoming => (
        AppColors.accentSurface,
        AppColors.accentRowBorder,
        AppColors.accent,
        AppColors.accentText,
        caption,
      ),
      StickerBubbleVariant.notSent => (
        AppColors.white,
        AppColors.border,
        AppColors.danger,
        AppColors.dangerText,
        'Not sent',
      ),
    };
    final bool isIncoming = variant == StickerBubbleVariant.incoming;
    final bool isNotSent = variant == StickerBubbleVariant.notSent;
    final String semanticLabel = switch (variant) {
      StickerBubbleVariant.incoming => '$caption sent ${stickerId.label}',
      StickerBubbleVariant.outgoing => 'You sent ${stickerId.label}',
      StickerBubbleVariant.notSent => 'Sticker not sent',
    };
    return div(classes: 'sticker-bubble', <Component>[
      // Announced instead of the drawing (the incoming switcher is a polite
      // live region, see `StickerBubbleSwitcher`).
      span(classes: 'sticker-bubble__sr', <Component>[Component.text(semanticLabel)]),
      div(
        classes: 'sticker-bubble__box',
        styles: Styles(
          border: Border.all(color: line, width: const Unit.pixels(1)),
          backgroundColor: fill,
        ),
        attributes: const <String, String>{'aria-hidden': 'true'},
        <Component>[
          div(
            key: ValueKey<bool>(isNotSent),
            styles: Styles(opacity: isNotSent ? 0.4 : 1),
            <Component>[StickerView(stickerId: stickerId, size: 96, isAnimated: !isNotSent)],
          ),
          div(classes: 'sticker-bubble__caption', <Component>[
            span(
              classes: 'sticker-bubble__dot',
              styles: Styles(backgroundColor: dot),
              const <Component>[],
            ),
            span(classes: 'sticker-bubble__label', styles: Styles(color: text), <Component>[Component.text(label)]),
          ]),
        ],
      ),
      StickerCaret(fill: fill, stroke: line, left: isIncoming ? null : 16, right: isIncoming ? 16 : null),
    ]);
  }
}

/// Animates a [StickerBubble] in and out. [child] is the current bubble
/// (keyed by its message) or `null` when there is none; the bloc decides
/// when that happens.
///
/// Enter: scale 0.6 to 1 from the caret plus fade, 180 ms ease-out-back.
/// Exit: fade and 8 px up, 200 ms. With reduced motion both are plain fades
/// (120 ms). Like `AnimatedSwitcher`, the bubble already there when the
/// switcher first appears is not animated in.
final class StickerBubbleSwitcher extends StatefulComponent {
  const StickerBubbleSwitcher({required this.child, required this.isCaretRight, super.key});

  final StickerBubble? child;

  /// The caret is on the right (the opponent's bubble).
  final bool isCaretRight;

  @override
  State<StickerBubbleSwitcher> createState() => _StickerBubbleSwitcherState();
}

final class _StickerBubbleSwitcherState extends State<StickerBubbleSwitcher> {
  late StickerBubble? _current;
  late bool _animateCurrent;
  late List<_ExitingBubble> _exiting;
  late int _nextExitId;

  @override
  void initState() {
    super.initState();
    _current = component.child;
    _animateCurrent = false;
    _exiting = <_ExitingBubble>[];
    _nextExitId = 0;
  }

  static bool _isReduced() => kIsWeb && web.window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  @override
  void didUpdateComponent(StickerBubbleSwitcher oldComponent) {
    super.didUpdateComponent(oldComponent);
    final StickerBubble? next = component.child;
    final StickerBubble? previous = _current;
    if (next?.key == previous?.key) {
      _current = next;
      return;
    }
    if (previous != null) {
      final _ExitingBubble exiting = _ExitingBubble(id: _nextExitId++, bubble: previous);
      exiting.timer = Timer(Duration(milliseconds: _isReduced() ? 120 : 200), () {
        if (!mounted) return;
        setState(
          () => _exiting = <_ExitingBubble>[
            for (final _ExitingBubble item in _exiting)
              if (item != exiting) item,
          ],
        );
      });
      _exiting = <_ExitingBubble>[..._exiting, exiting];
    }
    _current = next;
    _animateCurrent = true;
  }

  @override
  void dispose() {
    for (final _ExitingBubble item in _exiting) {
      item.timer?.cancel();
    }
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final bool isReduced = _isReduced();
    final StickerBubble? current = _current;
    final String side = component.isCaretRight ? 'right' : 'left';
    return div(
      classes: 'sticker-bubble-switcher sticker-bubble-switcher--$side',
      attributes: component.isCaretRight ? const <String, String>{'aria-live': 'polite'} : null,
      <Component>[
        for (final _ExitingBubble item in _exiting)
          div(
            key: ValueKey<String>('exit-${item.id}'),
            classes: isReduced
                ? 'sticker-bubble-switcher__item sticker-bubble-switcher__item--fade-out'
                : 'sticker-bubble-switcher__item sticker-bubble-switcher__item--exit',
            attributes: const <String, String>{'aria-hidden': 'true'},
            <Component>[item.bubble],
          ),
        if (current != null)
          div(
            key: current.key,
            classes: <String>[
              'sticker-bubble-switcher__item',
              if (_animateCurrent)
                isReduced ? 'sticker-bubble-switcher__item--fade-in' : 'sticker-bubble-switcher__item--enter',
            ].join(' '),
            <Component>[current],
          ),
      ],
    );
  }
}

final class _ExitingBubble {
  _ExitingBubble({required this.id, required this.bubble});

  final int id;
  final StickerBubble bubble;
  Timer? timer;
}

@css
List<StyleRule> get stickerBubbleStyles => <StyleRule>[
  css('.sticker-bubble').styles(position: const Position.relative(), width: const Unit.pixels(StickerBubble.width)),
  css('.sticker-bubble__sr').styles(
    position: const Position.absolute(),
    width: const Unit.pixels(1),
    height: const Unit.pixels(1),
    overflow: Overflow.hidden,
    whiteSpace: WhiteSpace.noWrap,
    raw: const <String, String>{'clip': 'rect(0 0 0 0)', 'clip-path': 'inset(50%)'},
  ),
  css('.sticker-bubble__box').styles(
    display: Display.flex,
    padding: const Padding.fromLTRB(Unit.pixels(8), Unit.pixels(8), Unit.pixels(8), Unit.pixels(10)),
    radius: const BorderRadius.circular(Unit.pixels(18)),
    shadow: AppShadows.overlay,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.center,
    gap: const Gap.row(Unit.pixels(2)),
  ),
  css('.sticker-bubble__caption').styles(
    display: Display.flex,
    maxWidth: const Unit.percent(100),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(6)),
  ),
  css('.sticker-bubble__dot').styles(
    width: const Unit.pixels(6),
    height: const Unit.pixels(6),
    radius: const BorderRadius.circular(Unit.percent(50)),
    flex: const Flex(shrink: 0),
  ),
  css('.sticker-bubble__label')
      .styles(
        minWidth: Unit.zero,
        overflow: Overflow.hidden,
        textOverflow: TextOverflow.ellipsis,
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.bodyXs)
      .combine(const Styles(fontWeight: FontWeight.w600)),
  // All bubbles share one grid cell, like the Stack of `AnimatedSwitcher`.
  css('.sticker-bubble-switcher').styles(display: Display.grid),
  css('.sticker-bubble-switcher--left').styles(justifyItems: JustifyItems.start),
  css('.sticker-bubble-switcher--right').styles(justifyItems: JustifyItems.end),
  css('.sticker-bubble-switcher__item').styles(raw: const <String, String>{'grid-area': '1 / 1'}),
  css('.sticker-bubble-switcher--left .sticker-bubble-switcher__item').styles(
    raw: const <String, String>{'transform-origin': '13.5% 0'},
  ),
  css('.sticker-bubble-switcher--right .sticker-bubble-switcher__item').styles(
    raw: const <String, String>{'transform-origin': '86.5% 0'},
  ),
  css('.sticker-bubble-switcher__item--enter').styles(
    raw: const <String, String>{
      'animation':
          'sticker-bubble-fade-in 180ms cubic-bezier(0, 0, 0.58, 1) both, '
          'sticker-bubble-scale-in 180ms cubic-bezier(0.175, 0.885, 0.32, 1.275) both',
    },
  ),
  css('.sticker-bubble-switcher__item--exit').styles(
    raw: const <String, String>{
      'animation':
          'sticker-bubble-fade-out 200ms cubic-bezier(0, 0, 0.58, 1) both, '
          'sticker-bubble-rise-out 200ms linear both',
    },
  ),
  css('.sticker-bubble-switcher__item--fade-in').styles(
    raw: const <String, String>{'animation': 'sticker-bubble-fade-in 120ms cubic-bezier(0, 0, 0.58, 1) both'},
  ),
  css('.sticker-bubble-switcher__item--fade-out').styles(
    raw: const <String, String>{'animation': 'sticker-bubble-fade-out 120ms cubic-bezier(0, 0, 0.58, 1) both'},
  ),
  css.keyframes('sticker-bubble-fade-in', <String, Styles>{
    'from': const Styles(opacity: 0),
    'to': const Styles(opacity: 1),
  }),
  css.keyframes('sticker-bubble-scale-in', <String, Styles>{
    'from': const Styles(transform: Transform.scale(0.6)),
    'to': const Styles(transform: Transform.scale(1)),
  }),
  css.keyframes('sticker-bubble-fade-out', <String, Styles>{
    'from': const Styles(opacity: 1),
    'to': const Styles(opacity: 0),
  }),
  css.keyframes('sticker-bubble-rise-out', <String, Styles>{
    'from': const Styles(transform: Transform.translate(y: Unit.zero)),
    'to': const Styles(transform: Transform.translate(y: Unit.pixels(-8))),
  }),
];
