# Battle stickers (live battle overlay)

Paper file: **SkillBattles MVP**, page **"v0.3 — New screens"**, new bottom row (y = 5840, below the rematch row):

| Artboard | Purpose |
|---|---|
| `31 Battle stickers — Sticker set` | The 9 stickers at the 96 px display size, each with name, category tag, id, a 3-frame key-frame strip and a motion note; plus the character-family construction rules (geometry, layer stack, palette) |
| `32 Battle stickers — Component sheet` | All components and states: `StickerTriggerButton` (5 states + in context), `StickerPicker` (open, hover on item, pressed / sending, cooldown), `StickerBubble` (outgoing, incoming, not sent), `MuteOpponentToggle` (shown, hidden) and the hidden indicator in the opponent block |
| `33 Battle — Sticker picker open` | `16 Battle — Overtime` with the trigger in its open state and the picker open in the left gutter (hover on "On fire") |
| `34 Battle — Sticker sent` | The same round right after sending "On fire": the picker is closed, your bubble plays under your avatar and the trigger is in cooldown |
| `35 Battle — Sticker received` | `17 Battle — Reveal (Free)`: the opponent, correct this round, sends "LOL"; it plays under their avatar |

The base size is the 1440 x 900 desktop web layout used by every artboard in the file.

## Purpose

During a live battle, each player can throw a short animated sticker at the opponent: five emotions and four taunts drawn as one mascot family. A sticker is a reaction, not chat: there is no text input, no history and no reply thread. It plays once near the sender's avatar on both screens and disappears.

This spec and the Paper artboards define the art (static peak frame), the motion and the UI around it. The Lottie files are built from that art by `tool/stickers/build_stickers.py` (see "Lottie asset notes").

## Placement and layout

Hard rule: **the picker and the bubbles never cover the question text, the option cards, the timer, the time bar or the round footer.** They live only in the side gutters, below the time bar.

- **Trigger**: inside your own header block only (`BattleHeader` → `_PlayerBlock` with `isYou: true`). The opponent's block never has a trigger.
  - Paper row: `avatar (48) · gap 14 · name column · gap 14 · StickerTriggerButton (40) · flexible space · score`.
  - In Flutter, the name column changes from `Expanded` to `Flexible` (loose fit, ellipsis kept) in the "you" block. Then the trigger sits right after the name, and a `Spacer` keeps the score at the right edge of the 420 px block.
- **Overlay frame**: positions are measured in the same frame as the header, which is the 1440 px max-width box with 64 px side padding. The overlay is a genuine overlay (`OverlayPortal` or a `Stack` over the battle body), so it is the one place that uses positioning. Everything inside it is plain rows and columns.
- **Picker**: `left = 64`, `top = 122`, which is the 104 header + 6 time bar + 12 gap. It is 200 px wide, so it spans x 64–264 and leaves 16 px before the 880 px content column at x 280. It opens downward.
  - The caret is a 16 x 9 notch on the top edge. Its centre follows the trigger's centre (145 px from the picker's left in artboard 33). It is clamped to 16–168 px from the picker's left.
- **Outgoing bubble (yours)**: `left = 64`, `top = 122`, 120 px wide. The caret is 16 px from the left, pointing at your avatar's centre (x 88). The picker and your bubble never show together: sending closes the picker.
- **Incoming bubble (opponent)**: `right = 64`, `top = 122`, 120 px wide. The caret is 16 px from the right, pointing at the opponent's avatar centre (x 1352).
- Both bubbles can play at the same time, one on each side. The incoming bubble can also show while your picker is open, because they are on opposite sides.
- **Width limits**: the gutter is `(viewport − 880) / 2` (the `BattleColumn` max width). The picker needs a gutter of at least 280 px at `left = 64`. When the gutter is smaller, the picker and bubble slide left to `left = max(16, gutter − 16 − width)`.
  - The picker fits down to a 1344 px viewport and a bubble down to 1280 px. Below 1280 px the page scrolls sideways inside a 1280 px canvas (`AppDesktopViewport`) while the overlay follows the window, so the app shows no bubble and disables the trigger (`Window too narrow for stickers`); see the open questions. Nothing may overlap the column.
- **Z-order**: the overlay is above the battle body and below dialogs (the report modal, the surrender confirm). Opening any dialog closes the picker.
- **Empty state**: no picker open and nothing playing → nothing is rendered. There is no loading skeleton and no per-message spinner. Until the nine compositions are parsed, only the trigger is disabled (tooltip `Loading stickers…`); see "Lottie asset notes".

## Components

### StickerTriggerButton (new)

```
StickerTriggerButton                   40 x 40 circle (AppTappable), hit area = the 40 px circle
└── state content
    ├── Icon/Sticker                   20 px peeled-sticker smiley, stroke 1.6 (new icon asset)
    └── CooldownRing + seconds         cooldown only: 40 px ring, 2.5 stroke, divider track, primary arc; JetBrains Mono 13/16 w600 primary
```

| State | Fill | Border | Icon / content | Tappable |
|---|---|---|---|---|
| Default | `white` | 1 px `border` | sticker icon `inkSoft` | yes |
| Hover / focus | `surface` | 1 px `borderStrong` | sticker icon `ink` (+ app focus ring on keyboard focus) | yes |
| Open | `primaryTint` | 1.5 px `primary` | sticker icon `primary` | yes (closes the picker) |
| Cooldown | `white` | none (the ring is the outline) | ring drains clockwise (remaining / total), seconds left in the middle (`4`) | no |
| Disabled | `surface` | none | sticker icon `faint` | no (only while the realtime connection is down) |

- Tooltip and semantics label: `Send a sticker`.
- Disabled while the realtime connection is not `connected` (tooltip `Reconnecting…`), while the compositions are still loading (`Loading stickers…`), and in the `finished` / `cancelled` phases or after a `STICKERS_NOT_ALLOWED` answer. There is no count limit.

### StickerPicker (new)

```
StickerPicker                          200 wide, padding 8, Column(gap 4), white, 1 px border, radius 16, overlay elevation shadow
├── Caret                              16 x 9 notch on the top edge, white fill, 1 px border stroke on its two sides
├── PickerHeader (Row, 40 high, spaceBetween, padding-left 8)
│   ├── Eyebrow "STICKERS"             AppTextStyles.eyebrow (JetBrains Mono 12/16, +0.08em, muted)
│   └── MuteOpponentToggle             40 x 40 icon button (see below)
├── StickerGrid (Column, gap 8)        3 rows × Row(gap 8) × 3 StickerCell
│   └── StickerCell/<Name>             56 x 56, radius 12; Lottie at 44 px showing its static peak frame
└── PickerFooter (Row, gap 8)          padding 8 8 4, 1 px divider top
    └── status text                    bodyXs 12/16 muted — see states
```

Grid order (row by row):

| | 1 | 2 | 3 |
|---|---|---|---|
| Row 1 | GG | On fire | Ez |
| Row 2 | LOL | Too slow | Facepalm |
| Row 3 | Hmm… | Wait, what? | Crying |

| State | Grid | Hovered / pressed cell | Footer |
|---|---|---|---|
| A · Open | full opacity | — | `Tap a sticker to send` |
| B · Hover on item (also keyboard focus) | full opacity | `primarySurface` fill, 1 px `primaryLine` border, sticker scales to 50 px (1.14) | `<Name> · <Category>` with the name in w600 ink (`Ez · Taunt`) |
| C · Pressed / sending | full opacity | `primaryTint` fill, 1.5 px `primary` border, sticker scales to 38 px | `Sending <Name>…` w600 primary |
| D · Cooldown | 0.4 opacity, cells not tappable | — | clock icon 14 px + `Next sticker in 0:04` (JetBrains Mono 12 w600 primary) |

Behaviour:
- Tap or Enter on a cell sends right away (no confirm). The picker closes, your bubble plays (optimistic) and the trigger enters cooldown.
- The picker closes on: an outside click, Esc, a send, a dialog opening, or the battle screen leaving (navigation to the result). A phase change does not close it.
- Opening the picker during cooldown shows state D. There is no count limit: the 4 s cooldown is the only throttle.
- Keyboard: focus starts on the first cell. Arrow keys move inside the 3 x 3 grid, Tab moves to the mute toggle. Hover and focus look the same.

### StickerBubble (new)

```
StickerBubble                          120 wide, padding 8 8 10, Column(gap 2, center), radius 18, overlay elevation shadow
├── Caret                              16 x 9 notch on the top edge, toward the sender's avatar
├── Sticker (Lottie)                   96 x 96
└── Caption (Row, gap 6)               6 px dot + name, Inter 12/16 w600
```

| Variant | Fill | Border | Caret | Caption |
|---|---|---|---|---|
| Outgoing (you) | `primarySurface` | 1 px `primaryLine` | left 16 | `primary` dot + `You` in `primary` |
| Incoming (opponent) | `accentSurface` | 1 px `accentRowBorder` | right 16 | `accent` dot + opponent nickname in `accentText` |
| Not sent (yours) | `white` | 1 px `border` | left 16 | `danger` dot + `Not sent` in `dangerText`; sticker at 0.4 opacity, not animated |

Surface decision: the bubbles are tinted, with no 1.5–2 px colored border, because a heavy `primary` border means "selected / your answer" in this design. Blue = you, amber = opponent, as in the avatars.

Lifecycle:
- **Enter**: scale 0.6 → 1 from the caret point plus fade in, 180 ms, ease-out-back. Then the Lottie starts.
- **Hold**: the bubble stays **3.0 s** from its appearance. Every sticker plays **once** from its start and then holds its last frame; nothing loops (`battle_stickers_frontend_task.md`).
- **Exit**: fade out and move 8 px up, 200 ms.
- One bubble per side. A newer sticker from the same player replaces the current bubble and restarts it (no queue).
- **Not sent**: shown instead of the outgoing animation when the send is rejected or fails. It hides after 2 s and does not start or keep the cooldown.
- Incoming stickers are dropped silently while `MuteOpponentToggle` is on "hidden". They are shown in `waitingReady`, `countdown`, `question` and `reveal`; the bubbles are cleared when the battle ends.

### MuteOpponentToggle (new, optional)

40 x 40 icon button, radius 10, in the picker header. The state is local to the current battle: it lives in `BattleStickersBloc` (`opponentHidden`), is not persisted, never reaches the server and resets to "shown" in the next battle. Switching to "hidden" also hides the opponent's bubble that is playing right now.

| State | Fill | Icon | Tooltip / label |
|---|---|---|---|
| Shown (default) | transparent (hover: `surface`) | eye 18 px `muted` | `Hide timur.b's stickers` |
| Hidden | `accentTint` | eye-off 18 px `accentText` | `Show timur.b's stickers` |

While hidden, a 14 px `faint` eye-off (`StickersHiddenIndicator`) sits before the opponent's nickname in their header block. It is not tappable.

## Sticker catalog

All stickers use the same 96 x 96 canvas, mascot body, 3 px ink stroke and palette. Duration is the length of one cycle; a loop repeats until the bubble exits.

| id | Name | Category | Motion (key frames in Paper: start → peak → settle) | Duration | Playback |
|---|---|---|---|---|---|
| `gg` | GG | Emotion | The body stretches up, the eyes close happily and the thumb pops in with overshoot (scale 0 → 1.18 → 1). The sparkles twinkle twice. | 1.4 s | one-shot |
| `fire` | On fire | Emotion | The flame ignites from a small spark and flickers (scale Y 0.92 to 1.08, slight sway). The grin snaps open and the embers drift up and fade. | 1.2 s | loop |
| `facepalm` | Facepalm | Taunt | The hand swings up and slaps the face. The body squashes on impact with 3 short hit lines, then a slow head shake (±6°), and a sweat drop slides down. | 1.3 s | one-shot |
| `lol` | LOL | Taunt | The character rocks ±8° around its base every 0.4 s and bounces 4 px. The mouth stays wide open and the tears fly outward and fade. | 1.6 s | loop |
| `hmm` | Hmm… | Emotion | The hand rises to the chin and the head tilts −5°. One brow lifts and the other eye squints. The thought dots pop in one by one (0.2 s apart), then fade and repeat. | 1.8 s | loop |
| `too_slow` | Too slow | Taunt | The character checks the stopwatch, then yawns big (the body stretches, the watch tilts). The watch hand ticks round once per cycle and the Z's float up and fade. | 2.0 s | loop |
| `ez` | Ez | Taunt | The shades drop from above and land on the eyes with a small bounce. The mouth turns into a smirk, a glint sweeps across the lenses and the sparkle pops. | 1.2 s | one-shot |
| `wait_what` | Wait, what? | Emotion | The character jumps 10 px and stretches, the eyes pop open (scale 1.25) and the jaw drops. The shock lines flash twice, then it lands with a small squash and the eyes stay wide. | 1.2 s | one-shot |
| `crying` | Crying | Emotion | A first tear wells up, then the eyes shut and two streams run down (trim path 0 → 100 %). The body sobs (scale Y 1 → 0.96 every 0.6 s) and the puddle grows. | 1.8 s | loop |

These ids are the client's working wire format and asset file names (`assets/stickers/<id>.json`) for now. The backend team will send its own decision later; until then the client uses this list, kept in one place so it can be remapped.

The "settle" frame in Paper is the static frame used in the picker cells, as the reduced-motion frame and as the asset preview.

## Lottie asset notes

- **Canvas**: 96 x 96, displayed at 96 px in the bubble and 44 px in picker cells. Author at 96, or at 192 with a 2x scale. The shapes are vector, so both stay sharp.
- **Frame rate**: 60 fps (a 1.2 s sticker is 72 frames). Loops must match the first and last frames.
- **Layer structure**: one shape layer per Paper SVG group, same name, bottom → top:
  `Shadow · Tuft · Body · Blush · Brows · Eyes · Mouth · Prop/<name> · FX/<name>`. The `Body` layer is the rig. Its anchor is the base point (48, 86), and the Tuft, face and Prop layers are parented to it, so every squash, tilt, rock (LOL) or jump moves the whole character. Shadow and most FX layers are not parented and stay on the ground.
- **Allowed**: shape layers with solid fills and strokes, transform (position, scale, rotation, anchor), opacity, and trim paths (Crying tears). Path morphs are fine for mouths and eyes.
- **Not allowed**: raster images, text layers ("GG" / "EZ" are names in the UI, never text in the file), masks/mattes where a simple shape works, effects (blur, glow, drop shadow), expressions, and gradients.
- **Stroke**: 3 px at 96, round caps and joins, `ink` everywhere.
- **Colors**: only `AppColors` values:

  | Role | Color |
  |---|---|
  | outline | `ink` #0E0F12 |
  | body, hand, watch face | `white` #FFFFFF |
  | tears, sparkle, glint | `primary` #2B4BF2 |
  | flame, embers, watch hand, sparkle | `accent` #F5A524 |
  | inner flame, tongue, shock lines | `danger` #E5484D |
  | blush | `accentRowBorder` #F5D9A3 |
  | puddle, sweat fill | `primaryLine` #DCE2FF |
  | ground shadow | `border` #E6E7EB |
  | thought dots | `faint` #A0A3AB |
  | Z's | `muted` #6B6F7A |

  The body is deliberately white, not blue or amber, so a sticker reads the same on either side. The bubble carries the ownership color.
- **Size budget**: aim for 20 KB or less per JSON. Bundle the files with the app (`assets/stickers/` in `pubspec.yaml`). On Flutter Web the files are still fetched from the frontend server on first load: the app parses the nine compositions once (signed-in shell / battle screen) and renders every bubble and cell from those objects.
- **Files in the app** (`assets/stickers/<id>.json`, as of 2026-11-15): 512 x 512, 60 fps, 8.1–18.4 KB. They are the loop-cut Telegram builds without the `tgs` key, copied into the app on 2026-11-15. The art fills 88 % of the canvas. The loop stickers contain one loop cycle and the one-shots end with a 0.6 s hold on the settle pose; no file is longer than 2.0 s.
  - The last frame (progress 1.0) is the settle frame of every file: it is the picker frame and the reduced-motion frame.
  - `tool/stickers/build_stickers.py` generates a different variant for `assets/stickers/`: 96 x 96 with an intro and the full one-shot. Running it overwrites the files in the app, so decide which variant ships before running it again.
- **Telegram (.tgs)**: `docs/stickers/tgs/<id>.tgs`, gzipped Lottie with `"tgs": 1`, 512 x 512, 60 fps, at most 2.0 s, 1.2–1.9 KB; outside `assets/`, not bundled.
  - Telegram always loops the whole file: the loop stickers contain only their loop cycle; the one-shots snap back to the start pose when they repeat.
  - The files use only shape layers, parenting, transforms, path morphs and trim paths. They use no masks, mattes, effects, expressions, repeaters, star shapes, merge paths, images, text or solids.
- **As built: differences from the catalog** (the decision is open):
  - `wait_what`: the jump is 5 px, not 10 px, and the stretch is 1.04, not 1.06, so the tuft and the shock lines stay inside the canvas.
  - `fire`: in the loop the flame scale Y is 0.92–1.03, not up to 1.08, because the Paper flame already touches the top edge.
  - `facepalm`: the hand starts 7 px left and 22 px down, not 14 and 30, so it starts inside the canvas.
  - `crying`: the open wailing mouth from the Paper 0.5 s key frame is left out.
  - The one-shots end on the hero art from artboard 31 (also the picker art on artboard 32).
- **Reduced motion** (`MediaQuery.disableAnimationsOf`): the bubble shows the static settle frame with a plain fade in/out, and the picker cells never animate.
- **Picker cells**: show the settle frame and do not autoplay. Hover or focus may play the sticker once (optional, nice-to-have).

## States

New sends are allowed in `waitingReady`, `countdown`, `question` and `reveal` only (`battle_stickers_frontend_task.md`):

| Phase | Trigger | Incoming stickers | Overlay top |
|---|---|---|---|
| `waitingReady` | enabled | shown | 116 (104 header + 12, no time bar) |
| `countdown` | enabled | shown | 116 |
| `question` (incl. overtime) | enabled | shown | 122 (104 header + 6 time bar + 12) |
| `reveal` | enabled | shown | 122 |
| `finished` (until the result screen opens), `cancelled` | disabled | cleared, new ones dropped | — |

Leaving the battle screen (the result screen, leaving the app) removes the picker and the bubbles; the result screen has no stickers.

Other states:
- **Cooldown**: starts when a send is accepted and lasts **4 s**. The trigger shows the ring and the seconds left (`4` → `1`); the picker shows state D if open. It is the only throttle: there is no per-round or per-battle limit.
- **Connection lost** (`RealtimeStatus` not `connected`): the trigger is disabled with the `Reconnecting…` tooltip and the picker closes. Incoming stickers stop naturally.
- **Send failed**: the `Not sent` bubble (above). Nothing else changes.
- **Muted**: incoming stickers are dropped for the rest of this battle; the indicator shows in the opponent block.

## Reused components and tokens

| Paper element | Flutter widget / token |
|---|---|
| Header player block, avatars, score (`16 Battle — Overtime`, `17 Battle — Reveal`) | `BattleHeader` / `_PlayerBlock`, `AppAvatar(size: lg)` (changed: trigger slot in the "you" block) |
| Round-reveal artboard used as the base of 35 | `BattleRoundView` (unchanged) |
| Tap / hover / focus handling | `AppTappable` |
| Eyebrow "STICKERS" | `AppEyebrow` / `AppTextStyles.eyebrow` |
| Clock icon in the cooldown footer | `AppIcons.clock` (tinted `primary`, 14 px) |
| Overlay elevation shadow | `BoxShadow(color: AppColors.shadow, offset: (0, 8), blurRadius: 24)`, the same as the rematch overlay (`rematch_notifications.md`) |
| Category tags on artboard 31 | `AppTag` neutral styles: Emotion = `primaryTint` / `primary`, Taunt = `accentTint` / `accentText` (documentation only, not used in the UI) |

Colors: `primary`, `primaryTint`, `primarySurface`, `primaryLine`, `ink`, `inkSoft`, `muted`, `faint`, `white`, `surface`, `border`, `borderStrong`, `divider`, `accent`, `accentSurface`, `accentTint`, `accentText`, `accentRowBorder`, `danger`, `dangerText`, `shadow`.
Text styles: `eyebrow`, `bodyXs` (w400 / w600), `monoBodySm`-sized JetBrains Mono 12–13 w600 for the countdowns.

## New elements (need implementation)

1. **Icon assets**:
   - `sticker.svg` (20 x 20, the trigger icon, tinted per state)
   - `eye.svg` and `eye_off.svg` (18 x 18, the mute toggle; the eye-off also at 14 px as the hidden indicator)
   - Add them to `AppIcons`.
2. **9 Lottie files**: done, in `assets/stickers/<id>.json` (see "Lottie asset notes"), with `lottie: ^3.8.2` and `assets/stickers/` in `pubspec.yaml`.
3. **`StickerTriggerButton`, `StickerPicker`, `StickerCell`, `StickerBubble`, `MuteOpponentToggle`, `StickerOverlay`**: new widgets in `features/battle/presentation/widgets/`.
4. **Cooldown ring**: a 40 px circular progress ring (2.5 stroke, `divider` track, `primary` arc). There is no existing ring widget; a `CustomPaint` or `CircularProgressIndicator` styled to match.
5. **`BattleHeader` change**: a trigger slot in the "you" block (`Expanded` → `Flexible` + `Spacer`), and the optional hidden indicator in the opponent block.

No new color or text style is introduced.

## Accessibility

- Hit targets: trigger 40 x 40, picker cells 56 x 56, mute toggle 40 x 40 (desktop ≥ 40 rule).
- Each cell has the label `<Name>, <Category>` (for example "LOL, taunt"). The trigger's label is `Send a sticker`, or the disabled reason.
- An incoming sticker is announced once as a polite live region: `timur.b sent LOL`. It is not announced while muted.
- Esc closes the picker and returns focus to the trigger. Focus does not leave the picker by itself, and the answer keyboard shortcuts (if any) stay active when the picker is closed.
- Reduced motion: static frame, fade only (see "Lottie asset notes").

## Decisions (2026-11-15)

1. **Cooldown**: 4 s.
2. **Limits**: none; the cooldown is the only throttle.
3. **Phases**: `waitingReady`, `countdown`, `question`, `reveal`; never after `finished` / `cancelled` (owner decision in `battle_stickers_frontend_task.md`, no post-battle grace window).
4. **Mute**: per battle, not persisted.
5. **Wire ids**: confirmed by the owner: the nine lowercase ids in "Sticker catalog". API: `battle_stickers_api.yaml` (POST `/battles/{id}/stickers`, STOMP `BATTLE_STICKER`).

## Open questions

1. **Rematch overlay collision**: `RematchOverlay` sits top-right at 88 px from the window top, 64 px from the right. If it ever shows on the battle route, it overlaps the incoming bubble. The rematch spec asks the same question; proposal: suppress the rematch overlay on the live battle route.
2. **Narrow widths**: below a 1344 px viewport the picker no longer fits in the gutter, and below 1280 px the bubbles are not shown (incoming stickers are missed there). Options: a smaller bubble (64 px sticker), hide the trigger, or receive-only. Not designed; mobile is not designed either.
3. **Moderation / abuse**: taunts are fixed art, so there is no free text, but should the server rate-limit or log them, and should a report option exist? Not designed.
4. **Copy**: `Send a sticker`, `Tap a sticker to send`, `Reconnecting…`, `Next sticker in 0:04`, `Sending GG…`, `Not sent`, `Hide / Show timur.b's stickers`, `timur.b sent LOL`. All are proposals.
