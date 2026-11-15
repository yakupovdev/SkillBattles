# League emblems

Visual identity for the 11 rating leagues and their divisions. It is shown on the Home discipline card (as the hero) and in the Leaderboard (rank cell + sidebar).

Paper: file "SkillBattles MVP", page **Leagues — concepts**.

| Artboard | Role |
|---|---|
| League icons — v4 (division evolution) | **Source of truth for the emblems** (approved) |
| Home — discipline card with league | Home card layout (in scope) |
| Leaderboard — rows with league icon | Leaderboard rank cell + sidebar block (in scope) |
| League ladder — your position | **Concept only — NOT in this implementation scope** (placement undecided) |
| League icons — set / v2 / v3 | Superseded explorations, do not implement |

The artboards are desktop width (1440), like the rest of the file.

---

## 1. Leagues and divisions

| # | Code | Divisions | `divisionNumber` |
|---|---|---|---|
| 1 | `BRONZE` | I · II · III | 1 · 2 · 3 |
| 2 | `IRON` | I · II · III | 1 · 2 · 3 |
| 3 | `SILVER` | I · II · III | 1 · 2 · 3 |
| 4 | `GOLD` | I · II · III | 1 · 2 · 3 |
| 5 | `PLATINUM` | I · II · III | 1 · 2 · 3 |
| 6 | `DIAMOND` | I · II · III | 1 · 2 · 3 |
| 7 | `EMERALD` | I · II · III | 1 · 2 · 3 |
| 8 | `BRILLIANT` | I · II · III | 1 · 2 · 3 |
| 9 | `MASTER` | single | `null` |
| 10 | `GRANDMASTER` | single | `null` |
| 11 | `LEGEND` | single, open top tier (no RP target) | `null` |

- **III is the top division** of a league: Silver I → Silver II → Silver III → Gold I.
- Rank codes from the backend look like `GOLD_II`. Parse them into `leagueCode` and `divisionNumber`. A single-division league has no suffix.

### Emblem shapes

The silhouette changes from league to league, so leagues stay distinct at 32 px:

- `BRONZE`: round shield.
- `IRON`: cut-corner plate.
- `SILVER`: peaked shield.
- `GOLD`: notched shield.
- `PLATINUM`: kite shield.
- `DIAMOND`: hex cut.
- `EMERALD`: step-cut octagon.
- `BRILLIANT`: round brilliant.
- `MASTER`: obsidian 8-point star.
- `GRANDMASTER`: garnet 10-point star.
- `LEGEND`: 12-point sunstone with a faint warm halo.

Every emblem has a dark inlaid core carrying the SkillBattles clash mark: a white left chevron and a right chevron in the league accent.

### Division evolution rule (plates + core ring)

The same rule applies to every divisional league. Nothing ever sticks out to the sides.

| Division | Back plates (beneath the body, offset down) | Core ring |
|---|---|---|
| I | none | none |
| II | 1 plate in the league deep colour | thin ring, stroke 2 (amber `#F5A524`) |
| III | 2 stacked plates (deep, then darker) | bold ring, stroke 3 (amber `#F5A524`) |

- **Gold** uses a **white** ring (`#FFFFFF`), because amber disappears on gold.
- **Single-division leagues** always use the full form: two plates and the bold ring.
  - MASTER and GRANDMASTER have an amber ring.
  - LEGEND has a pale gold ring (`#FFE08A`).
- **MASTER** has a lifted lavender outline (`#8C84E0`) and gold back plates, so it stays readable on dark (ink) surfaces.
- The division is drawn into the SVG asset. The app picks a file per (league, division) and does not compose the emblem at runtime.

### League colours (UI)

These are used by the UI around the emblem: name text, pips, progress fill, hero circle. The emblem's own colours live in the SVGs.

| League | Base | Deep | Tint |
|---|---|---|---|
| Bronze | `#C07A45` | `#7A4520` | `#FBF1E8` |
| Iron | `#5B6678` | `#2F3A4A` | `#EEF1F5` |
| Silver | `#C3CBD6` | `#5E6B7D` | `#F3F5F8` |
| Gold | `#F2B52E` | `#9A6400` | `#FFF8E6` |
| Platinum | `#9BE3DC` | `#1F7F78` | `#EAFAF8` |
| Diamond | `#6CC2F7` | `#1565A8` | `#EAF6FF` |
| Emerald | `#22B97D` | `#0B6B47` | `#E6F8F0` |
| Brilliant | `#B65CF0` | `#6E2AA8` | `#F6ECFE` |
| Master | `#E8B64A` | `#241F4A` | `#F1EFFA` |
| Grandmaster | `#D3264B` | `#8E0F2C` | `#FDECEF` |
| Legend | `#F7A21B` → `#EC4F86` (gradient) | `#7A2E0E` | `#FFF6E5` |

- **Silver name text:** Silver's league-name text uses `#3E4A5B` instead of the deep colour, for contrast on light surfaces.
- **Legend name text:** a gradient from `#F7A21B` to `#EC4F86` (`ShaderMask`), with solid `#B5560A` as the fallback.
- **New tokens:** none of these colours exist in `AppColors`. Add them as a league palette, for example `LeagueColors.of(leagueCode)` with `base`, `deep`, `tint` and `nameText`. Put it in the app theme, next to `AppColors`.

---

## 2. Assets

There are 27 SVG files in `assets/leagues/`, already written:

```
bronze_1.svg  bronze_2.svg  bronze_3.svg
iron_1.svg    iron_2.svg    iron_3.svg
silver_1.svg  silver_2.svg  silver_3.svg
gold_1.svg    gold_2.svg    gold_3.svg
platinum_1.svg platinum_2.svg platinum_3.svg
diamond_1.svg diamond_2.svg diamond_3.svg
emerald_1.svg emerald_2.svg emerald_3.svg
brilliant_1.svg brilliant_2.svg brilliant_3.svg
master.svg  grandmaster.svg  legend.svg
```

- **File name:** `<league_code_lowercase>_<divisionNumber>.svg`. Single-division leagues use `<league_code_lowercase>.svg`.
- **Size:** each file is `width="48" height="48"` with `viewBox="0 0 96 96"`.
  - The art is drawn on a 96-unit grid (2×), and the files render at a 48 logical px intrinsic size.
  - Always size the emblem explicitly; the widget scales it.
- **No `transform` attributes.** The back plates are baked into plain path coordinates.
- **Gradients:** each file has one `linearGradient` (`id="body"`) for the body material. `legend.svg` also has a `radialGradient` (`id="halo"`) for its faint halo. Both are plain `objectBoundingBox` gradients and should work with flutter_svg.
- **No filters, masks, clip paths, blend modes or text.**
- **Registration:**
  - Register `assets/leagues/` in `pubspec.yaml`.
  - Add the paths to an asset constants class, following `AppIcons` (`lib/app/theme/app_icons.dart`).
  - Resolve the path with one function, `(leagueCode, divisionNumber) → path`, rather than 27 call-site constants.
- **Fallbacks:**
  - A divisional league with a missing `divisionNumber` uses `_1`.
  - An unknown league code renders an empty box of the same size, so the layout does not jump.

---

## 3. Components

### `LeagueEmblem`
Shared widget, in `lib/core/presentation/widgets/`.

| Param | Type | Notes |
|---|---|---|
| `leagueCode` | league enum / code | required |
| `divisionNumber` | `int?` | 1–3, or `null` for single-division leagues |
| `size` | `double` | required. Used sizes: 96 (Home hero), 52 (Leaderboard sidebar), 32 (Leaderboard row), 22 (next-league preview) |
| `locked` | `bool` (default `false`) | greyscale plus 35% opacity |
| `dimmed` | `bool` (default `false`) | greyscale plus 70% opacity; used for the "Next" preview |

- **Greyscale:** a `ColorFiltered` saturation-0 matrix, wrapped in `Opacity`.
- **Accessibility:**
  - Semantics label is the rank name ("Silver II", "Legend").
  - Where the rank name is already shown as adjacent text (all current placements), exclude the emblem from semantics so it is not read twice.
- **Loading:** see §5.

### `DivisionPips`
Shared widget. Kept by decision, even though the emblem also encodes the division.

- **Shape:** 3 pips in a row, gap 4. Each pip is 16 × 4, radius 2.
- **Filled pips:** the first `divisionNumber` pips, in the league **deep** colour.
- **Empty pips:**
  - `#DCE2FF` on the selected (blue-tinted) card.
  - `#EEF0F3` on white surfaces.
- **Hidden** when `divisionNumber == null` (Master, Grandmaster, Legend).

---

## 4. Placements

### 4.1 Home — discipline card (`DisciplineCard`)
Artboard: "Home — discipline card with league". This replaces the old "rating number + rank text" block. The card shell, header and footer are unchanged from "14 Home v0.3".

Component tree:

```
DisciplineCard (radius 16, column, gap 20)
├─ Head (existing: title Space Grotesk 700 28/34 -0.02em, subtitle Inter 13/16 #6B6F7A, radio 24)
├─ LeagueHero (row, align center, gap 16)
│  ├─ EmblemCircle 112×112, circle, fill = league tint, 1px border = league base
│  │  └─ LeagueEmblem size 96 (current league + division)
│  ├─ LeagueName (column, gap 6, expands)
│  │  ├─ "YOUR LEAGUE"  JetBrains Mono 11/14, letter-spacing 0.1em, #6B6F7A
│  │  ├─ rank name ("Silver I")  Space Grotesk 700 34/38 -0.02em, league name colour
│  │  └─ DivisionPips
│  └─ Rating (column, align end, gap 2)
│     ├─ Elo  JetBrains Mono 500 28/32 -0.02em (#2B4BF2 selected, #0E0F12 unselected)
│     └─ "Elo rating"  Inter 12/16 #6B6F7A
├─ LeagueProgress (column, gap 10)
│  ├─ Row (space-between, align center)
│  │  ├─ RP text  JetBrains Mono 12/16: "32 / 100 RP" #33363D + " · to Silver II" #6B6F7A
│  │  └─ NextLeague (row, gap 6, opacity 0.55)
│  │     ├─ "Next"  Inter 12/16 #6B6F7A
│  │     ├─ LeagueEmblem size 22, dimmed (next league, division I; or single form)
│  │     └─ next league name  Inter 600 12/16 #33363D
│  └─ ProgressTrack  height 8, radius 4; track #DCE2FF (selected) / #EEF0F3 (unselected);
│     fill = league deep colour, width = currentRp / targetRp
└─ Footer (existing: 1px top border #DCE2FF selected / #EEF0F3 unselected, padding-top 16;
   calibration chip + text, or "Calibrated · Season peak …")
```

**Card shell:**
- Selected: 2px `#2B4BF2` border, `#F5F7FF` background, padding 28.
- Unselected: 1px `#E6E7EB` border, white background, padding 29.

**States:**
- **Selected / unselected.** Only the shell, the Elo colour, the track colour and the footer border change.
- **Near promotion.** The RP suffix becomes `· promotion in 14` in `#B26F00`, instead of `· to <next division>`. The threshold needs a decision; the design example is 136/150.
- **Open top tier (`LEGEND`).** There is no RP target, so:
  - Hide `ProgressTrack` and `NextLeague`.
  - The RP text becomes `Open tier · no RP cap`, plus a muted `· #<position> in <discipline>`.
  - The name uses the Legend gradient text.
- **Single-division, not top (`MASTER`, `GRANDMASTER`).**
  - Pips are hidden.
  - Progress shows the RP to the next league; `· to <next league>` replaces the division wording.
- **New player / low rank** (example on the artboard: Bronze II, 874). Same layout as any other league.
- **Calibrating.** Same layout. The footer keeps the existing "×2 ELO · Calibration · N of 5 matches left" chip.
- **Loading.** See §5.
- **Error.** The Home screen's existing error view; nothing league-specific.

### 4.2 Leaderboard (artboard "Leaderboard — rows with league icon")

**`LeagueRankCell`.** This is the Rank column of each row, including the "you" row.
- Row with gap 10, fixed width 160, `flexShrink: 0`.
- `LeagueEmblem` at size 32, followed by the rank name in Inter 14/18 `#0E0F12`.
- The "you" row uses weight 600 for the rank name.
- All other row parts are unchanged.

**`SidebarLeague`.** This block sits in the sidebar, under the "#214 / Season peak…" block.
- Container:
  - Padding 14 vertical × 16 horizontal, radius 12.
  - Background = league tint, 1px border `#E6E7EB`.
  - Row with gap 14.
- Contents:
  - `LeagueEmblem` at size 52.
  - Then a column with gap 6, holding:
    - a top row (space-between, baseline): the rank name in Space Grotesk 700 18/22 in the league name colour, and the RP in JetBrains Mono 12/16 `#6B6F7A`, e.g. "32 / 100 RP";
    - a bar: height 6, radius 3, track `#E6E7EB`, fill = league deep colour.
- **Open tier:** hide the bar and show "Open tier" in place of the RP.

---

## 5. Loading state (skeleton rules, `.claude/rules/skeleton_loading.md`)

- **Home:** while the ratings load, the content of the discipline cards is skeletonized with mock data. That covers the real `DisciplineCard` widgets with `LeagueHero`, `LeagueProgress` and the footer, built from `<Feature>SkeletonData` entities.
  - The card shell, the header (title and subtitle) and the selection radio are static and stay visible.
- **Leaderboard:** the table rows and the `SidebarLeague` block are skeletonized with mock data.
- **`LeagueEmblem` while skeletonized:** it does not load the SVG. It renders as **one bone** (`Skeleton.leaf`) of its own size, checking `Skeletonizer.maybeOf(context)?.enabled`.
- **`DivisionPips`:** render as part of the normal skeleton; no annotation is needed.
- **`NextLeague` preview:** `Skeleton.ignore`. It makes no sense for mock data.
- **No bone sizes** are specified. Sizes come from the real widgets and the mock data.
- **Error and empty states are never skeletonized.**

---

## 6. Out of scope

- The **League ladder** ("League ladder — your position" artboard). This is a concept only, because its placement (Leaderboard, Stats, Profile or a sheet) is undecided.
- Any v1–v3 emblem variants.

## 7. Open questions

1. **Near-promotion threshold:** the remaining RP at which the RP suffix switches to `· promotion in N`.
2. **Unplaced player:** what to show if a discipline has no rank yet. The proposal is to render the card without `LeagueHero`'s emblem and pips, with the rank name "Unranked".
3. **Single-division progress wording:** whether `MASTER` and `GRANDMASTER` have an RP target to the next league in the backend. The spec assumes they do; only `LEGEND` is open.

## 8. As implemented (2026-11-15)

Where this section differs from the sections above, this section wins.

- **`LeagueEmblem` API:** takes a non-null `LeagueRank` (`lib/core/presentation/league/league_rank.dart`), parsed once with `LeagueRank.tryParse(rankCode)`. It does not take a code and a division separately. An unknown rank code gives `null`, and the caller shows the rank name as text only (no emblem, no pips).
- **Not implemented (by decision):**
  - The near-promotion copy `· promotion in N` (§4.1, open question 1).
  - The Legend gradient name text: Legend uses solid `#B5560A`.
  - The Legend suffix `· #<position> in <discipline>`: the card has no position data. Legend shows `Open tier · no RP cap`.
  - The Unranked state (open question 2): a discipline without stats renders as before, with no league block.
- **Next-league preview:** shows the league name (`League.displayName`, e.g. "Gold") and that league's division I (or single) form, dimmed. It comes from the `/ranks` ladder and is hidden when the ladder is missing or the user is in the top league.
- **Pips:** not added at all when the division is `null`, so there is no empty gap.
- **Skeleton:** RP bars, `DivisionPips` and the Home emblem circle are `Skeleton.leaf`, so league colours do not show while loading (this replaces "no annotation is needed" in §5).
- **Long names:** the hero and sidebar rank names scale down to fit (`FittedBox`), so "Grandmaster" is never truncated.
- **Paper vs this spec:** the code follows this spec where the Paper artboards differ:
  - the Home hero emblem is 96 in code, 92 in Paper;
  - the selected card's emblem circle uses the league tint in code, white in Paper;
  - the sidebar Silver name colour is `#3E4A5B` in code, `#4A5668` in Paper.
