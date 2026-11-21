import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/features/battle/domain/entity/sticker_id.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/feature_card.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/leaderboard_fragment.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/rating_delta_fragment.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/review_row_fragment.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/room_code_fragment.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/social_fragment.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_layout.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_navigation.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_sticker.dart';

/// "Built for the head-to-head." — five feature cards in two rows.
final class FeaturesSection extends StatelessComponent {
  const FeaturesSection({super.key});

  @override
  Component build(BuildContext context) {
    return section(
      id: WelcomeAnchors.features,
      classes: 'welcome-container welcome-section welcome-features',
      attributes: const <String, String>{'tabindex': '-1'},
      const <Component>[
        WelcomeSectionHeader(
          eyebrow: 'Features',
          title: <Component>[Component.text('Built for the head-to-head.')],
          body: 'Play ranked to climb, or open a private room for a friend. Either way, you learn from every round.',
        ),
        FeatureGrid(),
      ],
    );
  }
}

/// Row 1: ranked (wider) and private duels. Row 2: review, leaderboards
/// and friends.
final class FeatureGrid extends StatelessComponent {
  const FeatureGrid({super.key});

  @override
  Component build(BuildContext context) {
    return const div(classes: 'welcome-feature-grid', <Component>[
      div(classes: 'welcome-feature-grid__row', <Component>[
        FeatureCard(
          index: 0,
          flex: 1.25,
          bodyMaxWidth: 440,
          title: 'Ranked matchmaking',
          body:
              'An opponent near your rating, in seconds. A separate Elo rating for each subject, both starting at '
              '1000 — and you see exactly how much it moved after every battle.',
          fragment: RatingDeltaFragment(),
        ),
        FeatureCard(
          index: 1,
          title: 'Private duels with friends',
          body:
              'Create a room, share the code or invite a friend from your list. Private duels are unranked, so '
              'play as many as you like.',
          fragment: RoomCodeFragment(),
        ),
      ]),
      div(classes: 'welcome-feature-grid__row', <Component>[
        FeatureCard(
          index: 0,
          title: 'Review every round',
          body:
              'After the battle, go through it round by round: the correct answer, what you picked, and why it '
              'works.',
          fragment: ReviewRowFragment(),
          sticker: WelcomeSticker(
            stickerId: StickerId.facepalm,
            size: 72,
            rotation: 9,
            firstDelay: Duration(milliseconds: 700),
            position: Position.absolute(right: Unit.pixels(-20), top: Unit.pixels(-28)),
          ),
        ),
        FeatureCard(
          index: 1,
          title: 'Leaderboards & stats',
          body: 'A leaderboard for each subject. Your profile keeps your stats, win streaks and battle history.',
          fragment: LeaderboardFragment(),
        ),
        FeatureCard(
          index: 2,
          title: 'Friends, rematches & stickers',
          body: 'Add friends, invite them to a duel, ask for a rematch — and throw a sticker mid-battle.',
          fragment: SocialFragment(),
        ),
      ]),
    ]);
  }
}

@css
List<StyleRule> get welcomeFeaturesStyles => <StyleRule>[
  css('.welcome-features').styles(
    display: Display.flex,
    padding: const Padding.symmetric(vertical: Unit.pixels(128)),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(48)),
  ),
  css('.welcome-feature-grid').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(24)),
  ),
  css('.welcome-feature-grid__row').styles(
    display: Display.flex,
    alignItems: AlignItems.stretch,
    gap: const Gap.column(Unit.pixels(24)),
  ),
];
