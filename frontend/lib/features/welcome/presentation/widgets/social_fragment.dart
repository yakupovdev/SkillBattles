import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_avatar.dart';
import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_sticker.dart';

/// Picture of two stickers and a rematch invitation. The invitation slides
/// up after the stickers start. The "Accept" pill is not a button: nothing
/// here is focusable.
final class SocialFragment extends StatelessComponent {
  const SocialFragment({super.key});

  @override
  Component build(BuildContext context) {
    return const div(classes: 'social-fragment', <Component>[
      div(classes: 'social-fragment__stickers', <Component>[
        _StickerTile(
          rotation: -4,
          sticker: WelcomeSticker(
            stickerId: StickerId.gg,
            size: 52,
            firstDelay: Duration(milliseconds: 1100),
          ),
        ),
        _StickerTile(
          rotation: 3,
          sticker: WelcomeSticker(
            stickerId: StickerId.fire,
            size: 52,
            firstDelay: Duration(milliseconds: 1500),
          ),
        ),
      ]),
      RematchInviteFragment(),
    ]);
  }
}

final class _StickerTile extends StatelessComponent {
  const _StickerTile({required this.rotation, required this.sticker});

  final double rotation;
  final WelcomeSticker sticker;

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'social-fragment__tile',
      styles: Styles(transform: Transform.rotate(Angle.deg(rotation))),
      <Component>[sticker],
    );
  }
}

/// A picture of the rematch card: "timur.b wants another round".
final class RematchInviteFragment extends StatelessComponent {
  const RematchInviteFragment({super.key});

  @override
  Component build(BuildContext context) {
    return const div(classes: 'rematch-fragment', <Component>[
      AppAvatar(nickname: 'timur.b', size: AppAvatarSize.sm, tone: AppAvatarTone.accent),
      div(classes: 'rematch-fragment__text', <Component>[
        span(classes: 'rematch-fragment__title', <Component>[Component.text('Rematch?')]),
        span(classes: 'rematch-fragment__subtitle', <Component>[Component.text('timur.b wants another round')]),
      ]),
      span(classes: 'rematch-fragment__accept', <Component>[Component.text('Accept')]),
    ]);
  }
}

@css
List<StyleRule> get socialFragmentStyles => <StyleRule>[
  css('.social-fragment').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(12)),
  ),
  css('.social-fragment__stickers').styles(display: Display.flex, gap: const Gap.column(Unit.pixels(12))),
  css('.social-fragment__tile').styles(
    display: Display.flex,
    position: const Position.relative(),
    width: const Unit.pixels(64),
    height: const Unit.pixels(64),
    radius: const BorderRadius.circular(Unit.pixels(14)),
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
    backgroundColor: AppColors.surface,
  ),
  css('.rematch-fragment').styles(
    display: Display.flex,
    padding: const Padding.all(Unit.pixels(14)),
    border: Border.all(color: AppColors.border, width: const Unit.pixels(1)),
    radius: const BorderRadius.circular(Unit.pixels(12)),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(12)),
    backgroundColor: AppColors.white,
    raw: <String, String>{'box-shadow': '0 1px 2px ${AppColors.shadow.value}'},
  ),
  css('.rematch-fragment__text').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(2)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.rematch-fragment__title').combine(AppTextStyles.bodyMd).combine(const Styles(fontWeight: FontWeight.w600)),
  css('.rematch-fragment__subtitle').combine(AppTextStyles.bodyXs).combine(const Styles(color: AppColors.muted)),
  css('.rematch-fragment__accept')
      .combine(AppTextStyles.bodySm)
      .combine(
        const Styles(
          display: Display.flex,
          height: Unit.pixels(36),
          padding: Padding.symmetric(horizontal: Unit.pixels(16)),
          radius: BorderRadius.circular(Unit.pixels(10)),
          alignItems: AlignItems.center,
          color: AppColors.white,
          fontWeight: FontWeight.w600,
          backgroundColor: AppColors.primary,
        ),
      ),
  css('.app-reveal--armed:not(.app-reveal--in) .rematch-fragment').styles(
    opacity: 0,
    transform: const Transform.translate(y: Unit.pixels(8)),
  ),
  css('.app-reveal--in .rematch-fragment').styles(
    raw: const <String, String>{'animation': 'welcome-slide-up 400ms cubic-bezier(0.2, 0.7, 0.2, 1) 1400ms both'},
  ),
  css.keyframes('welcome-slide-up', <String, Styles>{
    'from': const Styles(opacity: 0, transform: Transform.translate(y: Unit.pixels(8))),
    'to': const Styles(opacity: 1, transform: Transform.none),
  }),
  css.media(const MediaQuery.raw('(prefers-reduced-motion: reduce)'), <StyleRule>[
    css('.app-reveal--in .rematch-fragment').styles(raw: const <String, String>{'animation': 'none'}),
  ]),
];
