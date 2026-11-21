# Welcome (public landing page)

Paper file: **SkillBattles MVP**, new page **"v0.5 — Welcome"** (placed right after "v0.4 — Friends").

| Artboard | Purpose |
|---|---|
| `52 Welcome — landing` | The whole page, 1440 wide, `fit-content` height (3870 px): top bar, hero, facts strip, how it works, features, leagues, final CTA, footer |
| `53 Welcome — hover/focus states` | Rest / hover / keyboard focus of every interactive element on the page (white surface and blue panel) |

Base size: 1440 desktop web, like every artboard in the file (minimum window 1280). Content column is **1200 px, centered** (`max-width: 1200`, auto side margins; at 1280 that leaves 40 px gutters). Two bands are full-bleed (the 1440 top bar border and the ink Leagues band); their content is still the 1200 column.

## Purpose

Signed-out visitors land on the auth form today. The welcome page introduces SkillBattles first (like the chess.com / faceit home pages): what a battle is, what the product offers, the league ladder, and two ways in: **Create account** and **Log in**. It only uses product facts; no user counts, testimonials, prices, Pro or subscriptions.

## Route behaviour

- New screen `WelcomeScreen`, new enum value `AppRoutes.welcome('/welcome')`, added to `AppRoutes.public`. Route title `SkillBattles — live 1v1 SAT battles`.
- **Decided:** every protected route opened without a session (`/`, `/leaderboard`, `/friends/...`, `/result/...`, …) redirects to `/welcome` (it used to redirect to `/auth`). Signing out therefore lands on the welcome page too. The auth routes stay public as before.
- Signed-in users never see it: `/welcome` while signed in redirects to Home (`AppRoutes.home`).
- The page makes **no data requests**: it is static. There are no loading, empty, or error states and no `Skeletonizer`. No BLoC/Cubit is needed (navigation and local animation state only).

### CTA targets

| Element | Target |
|---|---|
| `Create account` (top bar), `Create account & play` (hero), `Create account & play` (final CTA) | Auth screen with the **Create account** tab selected |
| `Log in` (top bar), `Log in` (hero), `Already have an account? Log in` (final CTA) | Auth screen with the **Log in** tab selected |
| `How it works` / `Features` / `Leagues` (top bar) | Smooth-scroll to the section (`#how-it-works`, `#features`, `#leagues`); reduced motion: jump without animation. The section top lands 24 px below the sticky top bar (`scroll-margin-top: 96px`) |
| Logo (top bar) | Scroll to top |

**Decided:** the auth screen reads the tab from a query parameter `AppRoutes.authModeParam = 'mode'`: `/auth?mode=signup` opens **Create account**, anything else (or no parameter) opens **Log in**, so existing links keep working. Navigate with `context.goNamed(AppRoutes.auth.name, queryParams: {...})` (or the project's equivalent), never with a literal path.

**Decided:** the top bar is sticky (`position: sticky; top: 0` inside the page scroll container), white, with its 1 px bottom border; once the page is scrolled more than 8 px it also gets the `shadow` drop shadow (0 1 2) — 200 ms fade.

## Page structure

```
WelcomeScreen                                   white page, Column, sections centered
├── WelcomeTopBar                               72 high, 1 px border bottom, content 1200
├── WelcomeHero                                 Row(space-between, center, gap 48), padding 80 0 96
│   ├── HeroCopy (600)                          Column(gap 32)
│   │   ├── AppEyebrow
│   │   ├── HeroHeadline (h1)
│   │   ├── HeroSubline
│   │   └── HeroActions                         Column(gap 16): Row(gap 12) buttons + footnote
│   └── HeroBattlePreview (552 x 580)           decorative, aria-hidden
├── WelcomeFactsStrip                           4 x FactItem
├── HowItWorksSection  #how-it-works            padding-top 112, Column(gap 48)
│   ├── SectionHeader
│   └── BattleSteps                             Row(gap 24) of 4 BattleStep
├── FeaturesSection  #features                  padding 128 0, Column(gap 48)
│   ├── SectionHeader
│   └── FeatureGrid                             Column(gap 24)
│       ├── Row(gap 24): FeatureCard Ranked (flex 1.25) + FeatureCard Private duels (flex 1)
│       └── Row(gap 24): FeatureCard Review + FeatureCard Leaderboards + FeatureCard Friends (flex 1 each)
├── LeaguesSection  #leagues                    full-bleed ink band, padding 112 0 96, content Column(gap 56)
│   ├── SectionHeader (on ink)
│   ├── LeagueLadder                            Row(end-aligned) of 11 LeagueStep, 1 px onDarkLine bottom border
│   └── CalibrationNote
├── FinalCtaSection                             padding 112 0
│   └── FinalCtaPanel                           blue panel, radius 24, padding 80 72, rings
└── WelcomeFooter                               88 high, 1 px border top
```

`SectionHeader` (shared by the three white/ink sections): `Row(space-between, align end, gap 48)`: left `Column(gap 12)` (width 640) = `AppEyebrow` + h2; right paragraph width 380, `bodyLg`-size 15/22 `muted` (on ink: `onDarkMuted`).

### 1. Top bar — `WelcomeTopBar`

Not `AppTopBar` (that one has tabs and the account); same anatomy as its left side.

- Height 72, `white`, bottom border 1 px `border`. Content 1200, `Row(space-between, center)`.
- Left `Row(gap 48)`:
  - `AppLogo`: logo mark 28 (blue tile, white + amber chevrons) + `SkillBattles` `titleSm` (Space Grotesk 18/22 bold) ink, gap 10. Same as "14 Home v0.3".
  - Anchor links `Row(gap 32)`: `How it works`, `Features`, `Leagues` — `AppTextLink`, Inter 14/18 w500 `muted`; 48 px hit height.
- Right `Row(gap 12)`:
  - `AppButton(variant: outline, size: small) "Log in"` (44 high, radius 10, padding 18, 14/18 w600, 1.5 px ink).
  - `AppButton(variant: dark, size: small) "Create account"`.

### 2. Hero — `WelcomeHero`

Left, `HeroCopy` (width 600, `Column(gap 32)`):

| Element | Copy | Style |
|---|---|---|
| `AppEyebrow` | `SAT MATH · SAT READING & WRITING · LIVE 1V1` | `eyebrow` (JetBrains Mono 12/16, +0.08em, `muted`) |
| `HeroHeadline` (h1, 3 lines) | `Five minutes.` / `One opponent.` / `Sharper mind.` | `displayLg` 88/84 bold −0.04em, ink; the third line `primary` (amber is kept for the blue panels, where it has contrast) |
| `HeroSubline` (width 520) | `Live one-on-one battles on SAT questions. You and your opponent get the same five questions on the same clock — then a full review of every round.` | `bodyXl` 18/28, `inkSoft` |
| Buttons `Row(gap 12)` | `AppButton(primary, large) "Create account & play"` with `trailingIcon: AppSvgIcon(AppIcons.arrowRight, 18, white)`; `AppButton(outline, large) "Log in"` | large = 52 high, radius 12, padding 28, `buttonLg` 15/18 w600 |
| `HeroFootnote` | `Free to play · Ages 13+ · Both ratings start at 1000` | `bodySm` 13/16 `muted` |

Right, `HeroBattlePreview` (decorative, `aria-hidden="true"`, not interactive, no hover):

- Panel 552 x 580, `primary`, radius 24, `overflow: clip`, padding 64 40 0 (content top-aligned).
- Two rings (absolute, like the auth hero): 420 circle, 2 px `onPrimaryRingOuter`, right −140 top −120; 260 circle, 2 px `onPrimaryRingInner`, right −60 top −40.
- `MiniBattleCard` (472 wide, `white`, radius 16, shadow 0 24 64 `dialogShadow`, clip) — a scaled-down copy of "05 Live Battle":
  - `MiniBattleHeader` `Row(space-between, center)`, padding 18 20: you (`AppAvatar` 36 primary "A", `aliya_k` Inter 13/16 w600, rating `1032` mono 12/16 w500 `primary`) — round meter (`MATH · ROUND 3 OF 5` `monoCaption` 11/14 +0.08em `muted`, five 20 x 4 radius 2 pips: ink, ink, primary, border, border; gap 8) — opponent mirrored (`timur.b`, `1048` ink, avatar 36 accent "T" ink letter). Each player block is a fixed 132 lane.
  - `RoundProgress`: 4 high, track `divider`, fill `primary` 58 %.
  - `MiniQuestion` `Column(gap 16)`, padding 22 20 20:
    - Row: topic tag `Percentages` (Inter 12/16 w500 `primary` on `primaryTint`, radius 6, padding 4 8) + timer `0:42` (mono 20/24 w500 ink).
    - Question: `A jacket costs $80. It is discounted by 25%, then a 10% tax is added. What is the final price?` Space Grotesk 19/26 w600 −0.01em ink.
    - 2 x 2 answer grid, gaps 8: options 44 high, radius 10, 1 px `border`, padding 0 12, letter tile 24 (radius 6, `surface`, mono 12/16 w600) + value Inter 14/18. `B · $66.00` selected: 1.5 px `primary`, `primarySurface`, letter tile `primary` with white letter. Others: `A $60.00`, `C $68.00`, `D $72.00`.
    - Status row: 7 px `primary` dot + `Answer locked in.` (Inter 13/16 ink) — right: chip `timur.b answered` (check 10 `success` + Inter 12/16 w600 `success` on `successSurface`, pill, padding 3 8).
- `RatingDeltaChip` (absolute, left 48, bottom 44, rotated −3°): white, radius 12, padding 10 14, shadow 0 8 24 `dialogShadow`, `Row(gap 12)`: `MATH RATING` (monoCaption +0.08em `muted`), `1032` (mono 18/22 w500 `faint`), `AppIcons.arrowSmall` 16 ink, `1050` (mono 18/22 w500 ink), delta tag `+18` (mono 13/18 w600 `success` on `successSurface`, radius 6, padding 2 7). The −3° tilt is a CSS `transform: rotate(-3deg)`; it is the only rotated element besides the sticker tiles.

### 3. Facts strip — `WelcomeFactsStrip`

1200 wide, 1 px `border` top and bottom. Four `FactItem`s (flex 1), `Column(gap 6)`, padding 28 0 (items 2–4: left padding 32 and 1 px `border` left divider).

| Number (`monoXl` 44/48 w500 −0.02em) | Caption (`eyebrow` 12/16 +0.08em `muted`) |
|---|---|
| `5` ink | `ROUNDS PER BATTLE` |
| `2` ink | `SAT DISCIPLINES` |
| `27` ink | `LEAGUE TIERS TO CLIMB` |
| `1000` `primary` | `STARTING RATING` |

Semantics: a list (`ul`/`li`), each item read as "5 rounds per battle".

### 4. How a battle works — `HowItWorksSection` (`id="how-it-works"`)

- Eyebrow `HOW A BATTLE WORKS`; h2 `Pick. Match. Play. Review.` (`headlineLg` 40/44 bold −0.03em); side paragraph `Pick a subject, get an opponent near your level, and play. Every battle ends with what you got right, what you missed, and why.`
- `BattleSteps` `Row(gap 24)`, four `BattleStep`s (flex 1, `Column(gap 12)`, padding-top 20, **2 px ink top border**):
  - number `monoBodySm` 13/16 w600 +0.04em `primary`
  - title h3 `titleMd` 20/24 bold −0.01em ink
  - body 15/22 `muted`

| # | Title | Body |
|---|---|---|
| `01` | `Pick a subject` | `SAT Math or SAT Reading & Writing. Each one has its own rating.` |
| `02` | `Get matched` | `Ranked search finds an opponent near your rating. Or open a private room for a friend.` |
| `03` | `Play five rounds` | `Same questions, same clock. A correct answer scores more the faster you give it.` |
| `04` | `Review every round` | `See your rating change, then the correct answer and an explanation for each question.` |

### 5. Features — `FeaturesSection` (`id="features"`)

- Eyebrow `FEATURES`; h2 `Built for the head-to-head.`; side paragraph `Play ranked to climb, or open a private room for a friend. Either way, you learn from every round.`
- `FeatureCard` (new, presentational): `AppCard(color: white, border: 1 px border, radius 16, padding 28)`, `Column(space-between, gap 28)`: text block `Column(gap 8)` = h3 `titleLg` (Space Grotesk 22/28 bold, −0.01em) + body 15/22 `muted`; then the fragment. The fragments are **decorative** (`aria-hidden`), not interactive, no hover, and show fixed sample data (they are not mock data for a skeleton). Cards in a row share the tallest height (flex stretch).

| Card | Title | Body | Fragment |
|---|---|---|---|
| Ranked (flex 1.25; body width 440) | `Ranked matchmaking` | `An opponent near your rating, in seconds. A separate Elo rating for each subject, both starting at 1000 — and you see exactly how much it moved after every battle.` | `RatingDeltaFragment`: `surface` tile, radius 12, padding 8 20; two 56-high rows (1 px `border` between): left `SAT Math` (Inter 14/18 w600) / `Win vs timur.b` (12/16 `muted`); right `1032` (mono 18/22 w500 `faint`) → `arrowSmall` 16 ink → `1050` (mono 18/22 ink) + 52-wide delta tag `+18` (`success` on `successSurface`). Row 2: `SAT Reading & Writing` / `Loss vs dana_writes`, `1004 → 992`, tag `−12` (`dangerText` on `dangerSurface`). The tag lane is fixed 52 so both rows align. |
| Private (flex 1) | `Private duels with friends` | `Create a room, share the code or invite a friend from your list. Private duels are unranked, so play as many as you like.` | `RoomCodeFragment`: `surface` tile, radius 12, padding 20, `Column(gap 14)`: `ROOM CODE` (monoCaption +0.08em `muted`) + `Unranked · no rating change` (12/16 `muted`); six code tiles (flex 1, 48 high, white, 1 px `border`, radius 10, mono 22/28 w600) `K 7 Q 2 M 8`; row avatar 32 accent "T" + `Waiting for timur.b…` (13/16 w600) and countdown `0:48` (`monoBodySm` w600 `primary`). Built from the "48–50 Private room" pieces. |
| Review | `Review every round` | `After the battle, go through it round by round: the correct answer, what you picked, and why it works.` | `ReviewRowFragment`: the expanded review row of "07 Result & Review": white, 1.5 px ink border, radius 12, padding 18, `Column(gap 12)`: `03` (mono 13/18 `muted`) + `Jacket $80, −25%, then +10% tax…` (Inter 14/18 w600); chips `Correct: B · $66.00` (`success` on `successSurface`) and `You: A · $60.00` (`dangerText` on `dangerSurface`), Inter 12/16 w500, radius 6, padding 3 8; explanation `25% off leaves $60. Tax is added to the discounted price: $60 × 1.10 = $66.` (13/19 `inkSoft`). Chips and explanation indented 30 (to the text lane). |
| Leaderboards | `Leaderboards & stats` | `A leaderboard for each subject. Your profile keeps your stats, win streaks and battle history.` | `LeaderboardFragment`: three 48-high rows, 1 px `divider` bottom: rank lane 24 (mono 14/18 w500; `01` in `accent`, others ink), avatar 28, name Inter 14/18 w500 (flex), Elo mono 14/18 w500 right: `mira.solves 2,048` (ink avatar "M"), `kairat99 1,962` (primary "K"), `dana_writes 1,874` (accent "D", ink letter). Then `StreakLine` (padding-top 14): `AppIcons.flame` 12 x 14 + `5 wins in a row · best 7` (13/16 `accentText`, first part w600). Same rows as "20 Leaderboard" without the Pro badge and rank column. |
| Friends | `Friends, rematches & stickers` | `Add friends, invite them to a duel, ask for a rematch — and throw a sticker mid-battle.` | `SocialFragment` `Column(gap 12)`: two sticker tiles (64, `surface`, radius 14, rotated −4° and +3°) with the `gg` and `fire` battle stickers at 52; `RematchInviteFragment`: 1 px `border`, radius 12, padding 14, shadow 0 1 2 `shadow`: avatar 36 accent "T", `Rematch?` (14/18 w600) / `timur.b wants another round` (12/16 `muted`), a static 36-high `primary` pill `Accept` (13/16 w600 white, radius 10). It is a picture of the rematch card, not a button: it is not focusable. |

Stickers: render the existing Lottie files `web/assets/stickers/gg.json` and `web/assets/stickers/fire.json` as `WelcomeSticker`s — see "Stickers everywhere".

### 6. Leagues — `LeaguesSection` (`id="leagues"`)

Full-bleed band, background `ink`, padding 112 0 96, content 1200 `Column(gap 56)`.

- Header: eyebrow `LEAGUES · ONE LADDER PER SUBJECT` (`eyebrow` in `onDarkSubtle` #FFFFFF99); h2 (`displayMd` 56/60 bold −0.035em, 2 lines) `Climb 27 tiers.` white / `Bronze to Legend.` `accent`; side paragraph (`onDarkMuted`) `Eight leagues with three divisions each, then Master, Grandmaster and Legend. Win ranked battles to move up; your league shows on the leaderboard.`
- `LeagueLadder`: `Row(align end)` of 11 `LeagueStep` (flex 1, `Column(center, gap 16)`, padding-bottom 24), 1 px `onDarkLine` bottom border. Emblem sizes grow left to right so the row reads as a climb:

| League | Asset | Size | Caption (mono 11/14 +0.06em `onDarkFaint` #FFFFFF80) |
|---|---|---|---|
| Bronze | `web/assets/leagues/bronze_3.svg` | 52 | `I · II · III` |
| Iron | `iron_3.svg` | 56 | `I · II · III` |
| Silver | `silver_3.svg` | 60 | `I · II · III` |
| Gold | `gold_3.svg` | 64 | `I · II · III` |
| Platinum | `platinum_3.svg` | 68 | `I · II · III` |
| Diamond | `diamond_3.svg` | 72 | `I · II · III` |
| Emerald | `emerald_3.svg` | 78 | `I · II · III` |
| Brilliant | `brilliant_3.svg` | 84 | `I · II · III` |
| Master | `master.svg` | 92 | `ONE TIER` |
| Grandmaster | `grandmaster.svg` | 100 | `ONE TIER` |
| Legend | `legend.svg` | 108 | `THE TOP` |

  League name Inter 14/18 w600 white (`Legend` in `accent`). Use `LeagueEmblem` (or `AppSvgIcon` without a color) with the explicit size; 8 x 3 + 3 = 27 tiers.
- `CalibrationNote` `Row(gap 10, center)`: the existing `×2 ELO` chip of the home discipline card (mono 11/14 w600 +0.04em white on `primary`, radius 6, padding 3 8) + `While you calibrate — your first 5 ranked battles in each subject — rating changes are doubled.` (Inter 14/20 `onDarkMuted`).

Semantics: the ladder is an ordered list (`ol`) of league names, lowest first; emblems have empty `alt` (the name is the text).

### 7. Final CTA — `FinalCtaPanel`

Section padding 112 0. Panel 1200, `primary`, radius 24, padding 80 72, `Column(gap 32)`, clip; rings (absolute) 420 at right −40 top −60 (`onPrimaryRingOuter`) and 260 at right 40 top 20 (`onPrimaryRingInner`), 2 px.

- h2 (`displayMd` 56/60 bold −0.035em, 2 lines): `Your first battle is` white / `one click away.` `accent`.
- Paragraph (width 520, `bodyXl` 18/28, `onPrimaryBody`): `Create an account, pick SAT Math or Reading & Writing, and play right away. Both ratings start at 1000.`
- Actions `Row(gap 24, center)`: `AppButton(accent, large) "Create account & play"` (ink label, no icon) + text `Already have an account? ` (15/20 `onPrimaryBody`) followed by the link `Log in` (15/20 w600 white, underlined) — only `Log in` is the link (`AppTextLink` with `focusColor: white`), hit area 48 high.

### 8. Footer — `WelcomeFooter`

Full width, 1 px `border` top; content 1200, height 88, `Row(space-between, center)`:
- Left `Row(gap 20)`: logo mark 22 + `SkillBattles` Space Grotesk 15/20 bold ink (gap 8), then `© 2026 SkillBattles` (`bodySm` `muted`).
- Right `Row(gap 16)`: `Free to play` (`bodySm` `muted`) + age badge `13+` (mono 11/14 w600 +0.04em `inkSoft`, 1 px `borderStrong`, radius 6, padding 3 8; `aria-label="Ages 13 and up"`).

No legal links are drawn (none exist in the app; open question 4).

## Hover and focus (artboard 53)

All from existing widgets; nothing new.

| Element | Hover | Pressed | Keyboard focus |
|---|---|---|---|
| `AppButton` (primary / dark / outline / accent) | label-colour wash 6 % (`.app-button::after`) | 10 % | 24 % wash, no outline |
| Top-bar anchor links | `muted` → `ink` | — | ink + `AppTappable` ring (2 px `primary`, offset 3, radius 4) |
| Final CTA `Log in` link | white → `accent` | — | `AppTappable` ring in **white** (`focusColor: AppColors.white`) |
| Logo | none | — | `AppTappable` ring |

Artboard 53 draws the washes as flattened colours for preview only (e.g. primary hover ≈ #3755F3, focus ≈ #5B71F5); the app keeps the existing overlay, not new colours. The hero preview, feature fragments, facts and ladder have no hover.

Focus order: logo → How it works → Features → Leagues → Log in → Create account → hero Create account & play → hero Log in → final Create account & play → final Log in. Anchor targets get `tabindex="-1"` so focus moves to the section after an anchor jump.

## Accessibility

- One `h1` (hero headline, read as one sentence "Five minutes. One opponent. Sharper mind."). `h2`: How it works, Features, Leagues, final CTA. `h3`: step titles and feature card titles. Eyebrows are plain text before their heading.
- Decorative, `aria-hidden="true"`: `HeroBattlePreview` (whole panel incl. `RatingDeltaChip`), every feature fragment, the rings, sticker tiles. Their content is not real data and must not be read or focused.
- Every link reaches a 48 px hit height (nav links, logo, final `Log in`). The top-bar buttons keep the shared 44 px `AppButtonSize.small` (WCAG 2.5.5 AAA target 44 × 44); `AppButton` clips overflow, so no extra hit slop is added.
- Contrast: `muted` on white 4.9:1; `onDarkMuted` on ink and `onPrimaryBody` on primary pass AA for body sizes; amber is used for large display text on ink/blue only (≥ 3:1 large text). The `primary` third hero line is 6.2:1 on white.
- `prefers-reduced-motion`: no smooth scrolling, sticker animations show the last frame.
- `lang="en"`; document title `SkillBattles — live 1v1 SAT battles`.

## Reused components and tokens

| Paper element | Code |
|---|---|
| Logo mark + wordmark | logo SVG from `AppTopBar` / auth hero |
| Buttons | `AppButton` primary / dark / outline / accent, sizes large (52) and small (44) |
| Text links | `AppTextLink` / `AppTappable` |
| Eyebrows | `AppTextStyles.eyebrow` |
| Bordered cards | `AppCard(white, border, radius 16)` |
| Avatars | `AppAvatar` (36, 32, 28) |
| `×2 ELO` chip | home discipline card chip |
| Emblems | `LeagueEmblem` / league SVGs |
| Rating delta, review row, leaderboard row, room code tiles, rematch card | visual copies of "07 Result & Review", "20 Leaderboard", "48–50 Private room", "29 Rematch invite"; built as small presentational widgets in the welcome feature with constant sample data |
| Blue panel + rings | auth hero (`onPrimaryRingOuter` / `onPrimaryRingInner`) |
| Ink band | ink panels (`onDarkMuted`, `onDarkSubtle`, `onDarkFaint`, `onDarkLine`) |

Text styles: `displayLg`, `displayMd`, `headlineLg`, `titleLg`, `titleMd`, `titleSm`, `bodyXl`, `bodyMd`, `bodySm`, `bodyXs`, `buttonLg`, `buttonMd`, `monoXl`, `monoBodyMd`, `monoBodySm`, `monoCaption`, `eyebrow`. One-offs (combine, no new token): body 15/22 for section/card paragraphs (`bodyLg` with line height 22), question 19/26 w600 in the mini battle card, mono 18/22 w500 for the delta numbers, mono 20/24 for the mini timer.

Colors: only `AppColors` values (`primary`, `primarySurface`, `primaryTint`, `ink`, `inkSoft`, `muted`, `faint`, `white`, `surface`, `border`, `borderStrong`, `divider`, `success`, `successSurface`, `dangerText`, `dangerSurface`, `accent`, `accentText`, `onPrimary*`, `onDark*`, `shadow`, `dialogShadow`).

**No new color, text style, font or icon is introduced.**

## Assets

| Asset | Path |
|---|---|
| Arrow (hero CTA, 18, white) | `web/assets/icons/arrow_right.svg` |
| Arrow (rating deltas, 16, ink via `AppSvgIcon(color:)`) | `web/assets/icons/arrow_small.svg` |
| Check (opponent answered chip, 10, success) | `web/assets/icons/check.svg` |
| Flame (streak line) | `web/assets/icons/flame.svg` |
| League emblems | `web/assets/leagues/{bronze,iron,silver,gold,platinum,diamond,emerald,brilliant}_3.svg`, `master.svg`, `grandmaster.svg`, `legend.svg` |
| Stickers | `web/assets/stickers/{gg,fire,facepalm,lol,hmm,too_slow,ez,wait_what,crying}.json` |
| Logo mark | same inline SVG as the top bar / auth hero |

## New elements (need implementation)

1. `AppRoutes.welcome` + redirect rules (see Route behaviour).
2. `WelcomeScreen` and its section widgets: `WelcomeTopBar`, `WelcomeHero`, `HeroBattlePreview` (+ `MiniBattleCard`, `RatingDeltaChip`), `WelcomeFactsStrip`, `BattleStep`, `FeatureCard`, the five fragments (`RatingDeltaFragment`, `RoomCodeFragment`, `ReviewRowFragment`, `LeaderboardFragment`, `SocialFragment`), `LeagueLadder` / `LeagueStep`, `CalibrationNote`, `FinalCtaPanel`, `WelcomeFooter`. All presentational, built from existing widgets and styles.
3. Auth screen: accept the initial tab from the route (open question 2).

## Conflicts and notes

1. "01 Auth" hero still shows `MATH · 3 × 95s · ENGLISH · 4 × 70s`, while Home and the product facts say 5 rounds per battle (`5 rounds · 45–90s` / `36–72s`). The welcome page uses **5 rounds**. The auth captions look outdated; not changed here.
2. The hero headline reuses the auth hero line. If the auth screen keeps it too, a visitor sees it twice in a row (welcome → auth). Acceptable as brand continuity; flagging in case the auth panel should get a different line.
3. Home v0.3 shows Pro elements (Go Pro, Pro card); the landing deliberately shows none.

## Motion (decided: "more animation")

The page is alive, but only through `transform` and `opacity` (plus the Lottie stickers). Everything below is **off under `prefers-reduced-motion: reduce`**: content is shown in its final designed state at once (no entrance, no count-up, battle card frozen on the designed frame, stickers on their last frame with no replays, no smooth scroll). Content must never stay hidden if `IntersectionObserver` is unavailable or JS fails: hidden-before-reveal styles apply only while the observer is attached.

Easing for everything: `cubic-bezier(0.2, 0.7, 0.2, 1)` ("out"), unless noted.

### Entrance and scroll reveal

- **Hero, on first paint:** eyebrow, the three headline lines, subline, buttons row, footnote fade up one after another (opacity 0 → 1, `translateY(16px)` → 0, 600 ms, 80 ms stagger). The `HeroBattlePreview` panel slides in from the right (`translateX(32px)` → 0, opacity, 700 ms, starts at 200 ms); the mini battle card then rises (`translateY(24px)`, 500 ms, +150 ms); the `RatingDeltaChip` pops last (scale 0.8 → 1 keeping its −3° tilt, 400 ms, `cubic-bezier(0.34, 1.56, 0.64, 1)`).
- **Scroll reveal, once per element** when 15 % of it enters the viewport: section headers, each `FactItem`, each `BattleStep`, each `FeatureCard`, the final CTA panel — fade up (`translateY(24px)`, 600 ms), siblings staggered 70 ms. The `BattleStep` 2 px ink top border draws from left to right (`scaleX(0)` → 1, origin left, 500 ms) together with its step.
- **League ladder:** when the ladder enters view the emblems rise in order Bronze → Legend (`translateY(32px)` + opacity, 500 ms, 60 ms stagger), then the `Legend` emblem keeps a slow amber glow (`filter: drop-shadow(0 0 16px accent @ 0 → 45 %)`, 2.4 s, alternate, infinite). Hover on any emblem (mouse only): lift 6 px + scale 1.06, 200 ms.
- **Rings** (hero panel, final CTA): slow "breathing" scale 1 → 1.04, 6 s / 8 s alternate, infinite, outer and inner out of phase.

### Live battle preview (hero)

`MiniBattleCard` plays a 10-second loop while the hero is on screen (paused off-screen and when the tab is hidden), one step per second:

| Second | What happens |
|---|---|
| 0 | Fresh round: timer `0:45`, no option selected, status row hidden, opponent chip hidden, rating chip shows `1032`, delta tag hidden |
| 1–10 | Timer counts down every second (`0:44`, `0:43`, …); `RoundProgress` fill shrinks linearly with it |
| 3 | Option `B · $66.00` becomes selected (border/background 200 ms); status row `Answer locked in.` fades in |
| 5 | Chip `timur.b answered` pops in (scale 0.8 → 1, 300 ms overshoot) |
| 7 | `RatingDeltaChip` number counts `1032 → 1050` over 600 ms, then the `+18` tag pops in |
| 10 | Everything fades back to second 0 (300 ms) and the loop restarts |

The designed frame (Paper) is second 8; that frame is shown statically under reduced motion. Digits use `font-variant-numeric: tabular-nums` so the layout never shifts.

### Count-ups and fragments

- **Facts strip:** numbers count up from 0 when the strip enters view (`5`, `2`, `27` in 600 ms; `1000` in 1000 ms), ease-out, once.
- **Ranked card:** the `1050` / `992` numbers count from their old value when the card is revealed, then the `+18` / `−12` tags pop (300 ms overshoot).
- **Private duels card:** the six code tiles appear one by one (100 ms apart, scale 0.9 → 1 + opacity) as if typed; the `0:48` countdown then ticks down while on screen and wraps back to `0:59` after `0:00`; the `Waiting for timur.b…` ellipsis pulses (opacity 0.4 ↔ 1, 1.2 s).
- **Review card:** the explanation line slides down (height/opacity via `grid-template-rows` 0fr → 1fr or opacity + translate, 400 ms) after the chips appear.
- **Leaderboards card:** the three rows slide in from the left (`translateX(-12px)`, 80 ms stagger); the flame icon flickers (scale 1 ↔ 1.12, 900 ms alternate, infinite).
- **Social card:** the rematch card slides up 8 px + fades after the stickers start.

## Stickers everywhere (decided)

The landing is sprinkled with the real battle stickers (Lottie, `web/assets/stickers/*.json`), rendered with the existing sticker player (`StickerView` / `LottiePlayer`, compositions from `StickerCompositionsScope`, which already wraps the router; the welcome page calls `ensureLoaded()`). A sticker whose composition is not loaded yet renders **nothing** (never the text fallback) and appears once loaded.

Behaviour of every landing sticker (`WelcomeSticker`):

- Decorative: `aria-hidden`, not focusable, `pointer-events` only for the hover replay; absolutely positioned inside its section so it never changes layout; rotated as listed.
- Plays once when it first enters the viewport (≥ 50 % visible), with a per-sticker delay so stickers of one section do not start together.
- Then **replays from the first frame every 6–14 s** (a new random interval each time) while it is ≥ 50 % visible and the document is visible. Off-screen or hidden tab: no timers run. Between plays it rests on its last ("settle") frame.
- Mouse hover replays it at once (and resets its timer), at most once per play.
- Entrance: the first time it appears it pops in (scale 0.6 → 1, opacity, 400 ms overshoot) together with its first play.
- Reduced motion: last frame only, no pop, no replays, no hover replay.

Placement (sizes in px, offsets relative to the named block; the block gets `position: relative`; stickers may overhang a card edge but never cover text, buttons or the mini battle card's question/answers):

| # | Sticker | Size | Where | Rotation |
|---|---|---|---|---|
| 1 | `fire` | 96 | Hero `HeroBattlePreview` panel, top-left corner overhanging: left −36, top −32 | −10° |
| 2 | `gg` | 72 | Hero panel, bottom-right, to the right of the `RatingDeltaChip`: right 36, bottom 36 | 8° |
| 3 | `too_slow` | 64 | Facts strip, above the `5 ROUNDS PER BATTLE` item, sitting on the strip's top border near its right edge: top −40, left 120 | 6° |
| 4 | `hmm` | 64 | How it works, `BattleStep` 01, top-right: right 8, top −44 | −6° |
| 5 | `wait_what` | 64 | How it works, `BattleStep` 04, top-right: right 8, top −44 | 7° |
| 6 | `facepalm` | 72 | Features, `Review every round` card, overhanging the top-right corner: right −20, top −28 | 9° |
| 7 | `gg`, `fire` | 52 | Features, `Friends, rematches & stickers` card — the two existing sticker tiles (now animated, replaying like the others) | −4°, 3° |
| 8 | `crying` | 56 | Leagues ladder, above the `Bronze` emblem (sad at the bottom): bottom of the sticker 12 px above the emblem top | −8° |
| 9 | `ez` | 64 | Leagues ladder, top-right of the `Legend` emblem: overhanging right −8, top −56 | 10° |
| 10 | `lol` | 88 | Final CTA panel, right side between the rings: right 120, top 64 | −7° |

10 placements, 9 distinct stickers. The hero (1, 2) start 900 ms / 1500 ms after first paint (after the entrance); in other sections the first play is delayed 300 ms + 400 ms × index within the section.

## Open questions

1. **Legal links** (Terms, Privacy) in the footer: none exist in the app; add when the pages exist.
