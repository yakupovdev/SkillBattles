# Rematch notifications (global overlay)

Paper file: **SkillBattles MVP**, page **"v0.3 — New screens"**, new bottom row:

| Artboard | Purpose |
|---|---|
| `28 Rematch notifications — Component sheet` | All components and states: `RematchInviteCard` (6 states), `RematchStatusToast` (4 variants), `RematchPendingPill` (3 variants), `RematchConnectionIndicator` |
| `29 Rematch invite — Home, one incoming` | Home (`14 Home v0.3`) inside the shell with one incoming invitation |
| `30 Rematch invites — Home, stacked + hidden pill` | Home with three visible invitations sorted by deadline, plus the pill for one more invitation that the player hid with × |

The base size is the 1440 x 900 desktop web layout used by every artboard in the file (the task is Flutter web, desktop shell).

## Purpose

When player A asks for a rematch after a private duel, player B gets an actionable invitation wherever they are in the signed-in app (home, profile, history, leaderboard, stats...). It is an in-app overlay only: no OS push, no bell, no inbox, no history, no unread counter. Player A gets short status toasts about their own request.

## Placement and layout

- `RematchOverlay` is drawn by the app shell **above the routed page and below the top bar** (`AppTopBar` stays fully visible and clickable). It never pushes or resizes page content.
- Anchor: top-right of the content area. **Top = 16 px under the 72 px top bar** (88 px from the window top), **right = 64 px**, the page gutter, so the right edge lines up with the avatar in the top bar.
- Width: **380 px** fixed for cards, toasts and the column. The pill and the reconnecting indicator hug their content and are right-aligned in the column.
- Column: `Column(crossAxisAlignment: end)` with **12 px** gaps. Order from top to bottom:
  1. `RematchConnectionIndicator` (only while the socket is down)
  2. `RematchPendingPill` (only when at least one invitation was hidden with × and is still pending)
  3. `RematchInviteCard`s, **sorted by `expiresAt` ascending** (the soonest deadline on top). New invitations are inserted by deadline, not appended.
  4. `RematchStatusToast`s, oldest first
- At most **3 invitation cards** are shown. Pending, not-hidden invitations beyond 3 wait in a queue (by `expiresAt`) and take a free slot as soon as a visible card is accepted, declined, hidden, expired or cancelled. They are not counted in the pill.
- The overlay only takes the space of its children; the rest of the page stays interactive. It is a genuine overlay, so it is the one place that uses positioning (`Stack` + `Positioned(top: 16, right: 64)` inside the shell body); everything inside it is plain rows and columns.
- Empty state: no pending invitations, no toasts, socket connected → **nothing is rendered**. There is no loading skeleton for this feature.

## Components

### RematchInviteCard (new)

Card for the invited player (player B). Built from existing widgets.

```
RematchInviteCard                      AppCard(color: white, borderColor: border, radius: 16, padding: 21), wrapped with the overlay elevation shadow
├── Header (Row, gap 14, align start)
│   ├── AppAvatar(size: md (44), tone: accent)   requester's initial; amber = opponent, as elsewhere
│   ├── Text (Column, gap 4, Expanded, 2 px top padding)
│   │   ├── Title   "Rematch request"            AppTextStyles.titleSm (Space Grotesk 18/22 bold), ink
│   │   └── Body    "{nickname} wants a rematch in {discipline display name}."
│   │                                            bodySm 13/18, muted; nickname w600 ink
│   └── CloseButton (hide)                       AppIcons.close 20 px, muted, 32 px visual box, 48 x 48 hit area
├── Deadline (Row, gap 12, center)
│   ├── DeadlineTrack (Expanded)                 6 px track, radius 3: primaryLine track, primary fill = remaining / total
│   └── AppCountdownText(format: clock, suffix: ' left')   JetBrains Mono 13/16 w600, primary ("0:42 left")
├── [state slot]                                 AppNotice (busy) / ExpiredText (expired) — see states
├── Actions (Row, gap 10)
│   ├── AppButton("Accept", variant: primary, size: medium, expand)   48 high
│   └── AppButton("Decline", variant: outline, size: medium, expand)  48 high
└── [AppInlineError]                             network error only
```

Card gaps: 16 px between Header, Deadline, state slot, Actions and the inline error. Padding 21 = 20 + the 1 px border, the same visual inset as the 2 px-bordered rematch block on the result screen.

**Surface decision**: the card is neutral (white, 1 px `border`), not the blue rematch block from "18 Result" (`primarySurface` + 2 px `primary` border). In this design a 2 px blue border means "selected" (the SAT Math card on home), and three of them stacked next to the selected discipline card competed with it. Blue is kept for the countdown, the track and Accept.

Countdown:
- `AppCountdownText` is display-only. The **expired state is driven by the invitation state computed from the server `expiresAt`** (corrected by the server clock offset), not by the widget reaching zero.
- The track fill is the remaining fraction of the request lifetime (max 60 s). Sample values in Paper: 0:42 → 70 %, 0:12 → 20 %.
- Each card has its own countdown and its own track.

### RematchStatusToast (new)

Transient, non-actionable message. Row(gap 12, center), padding 14 / 16, white surface, 1 px `border`, radius 14, overlay elevation shadow, 380 px.

- Leading icon 20 px, then message in `bodyMd` 14/18 w500 ink (`Expanded`, wraps to 2 lines).
- No close button, no actions.
- **Auto-hides after 4 s**. It is announced to screen readers (live region), like `AppNotice` / `AppCallout`.
- Icons: Flutter uses the existing assets at 20 px (`AppIcons.statusSuccess`, `AppIcons.clock`, `AppIcons.info`). The clock and info glyphs in Paper are redrawn at 20 px to match those assets.

| Variant | Who sees it | Icon | Copy |
|---|---|---|---|
| Requested / waiting | Requester (A), right after sending the request from the result page | primary spinner (style of the "25 Checkout return" spinner: `divider` track, `primary` arc) | `Rematch requested. Waiting for your opponent…` |
| Accepted | Both players, just before navigating to the ready check | `AppIcons.statusSuccess` | `Rematch accepted. Opening the ready check…` |
| Expired | Requester (A) when nobody answered; invited player (B) only when the invitation was hidden (see below) | `AppIcons.clock` (muted) | `The rematch request expired.` |
| Cancelled | Invited player (B) when A cancelled the request | `AppIcons.info` (muted) | `The rematch request was cancelled.` |

### RematchPendingPill (new)

The reopen entry for invitations hidden with ×. Pill, 34 high (same as the "Go Pro" pill in the top bar), radius 999, padding 0 14, white fill, 1.5 px `primary` border, overlay elevation shadow. Row(gap 8): `AppDot(color: primary)` (8 px) + label 13/16 w600 primary.

- Counts **only invitations hidden with × that are still pending**. Queued overflow invitations (beyond 3 cards) are not counted.
- Label: `1 pending rematch`; with more: `{n} pending rematches` (plural copy is an open question).
- Hover / focus: fill `primarySurface`.
- Tap: un-hides every hidden invitation that is still pending. They rejoin the deadline-sorted list. Those that do not fit in the 3 visible slots wait in the queue. The pill disappears because nothing is hidden any more.
- Not a counter or a bell: it exists only while hidden pending invitations exist and disappears otherwise.

### RematchConnectionIndicator (new)

Shown at the top of the overlay column while the realtime socket is down and at least one invitation card or the pill is on screen. Pill, 32 high, radius 999, padding 0 12, `surface` fill, Row(gap 8): 14 px muted spinner (`border` track, `muted` arc) + `Reconnecting…` 13/16 w500 `inkSoft`. Hidden as soon as the socket reconnects. Not shown when the overlay is otherwise empty.

## Invitation card states

| # | State | Accept | Decline | × (hide) | Extra |
|---|---|---|---|---|---|
| 1 | **Default** | enabled | enabled | enabled | countdown running |
| 2 | **Accepting** (request in flight) | loading: white 16 px spinner before the label, label stays `Accept`, full opacity, not tappable | disabled (1 px light border, faint label) | hidden (slot kept, so the layout does not move) | countdown keeps running |
| 3 | **Busy** (player is in a battle, search or ready check) | disabled (primary at 0.4 opacity) | enabled | enabled | `AppNotice(tone: warning)` between Deadline and Actions: `Finish or leave your current activity before accepting.` |
| 4 | **Expired** | disabled | disabled | enabled | track empty on `divider`, countdown `0:00` in faint, line `The rematch request expired.` (bodyMd w500 inkSoft) above Actions |
| 5 | **Network error** (accept or decline failed) | enabled (retry) | enabled (retry) | enabled | `AppInlineError`: `Couldn't update the rematch request. Try again.` under Actions; cleared on the next Accept / Decline tap |
| 6 | **Reconnecting** (socket down) | as in the underlying state | as in the underlying state | enabled | `RematchConnectionIndicator` at the top of the overlay (see open questions) |

Rules:
- Accept is enabled only when: not expired, not busy, no request of this card in flight.
- Decline is enabled when: not expired and no request of this card in flight. Busy does **not** disable Decline.
- **Declining** (not drawn separately): the mirror of state 2. Decline shows the loading spinner before its ink label, Accept is disabled, and × is hidden.
- Accept succeeds → card is removed, the **Accepted** toast shows, the app opens the ready check.
- Decline succeeds → card is removed, no toast.
- Busy is re-evaluated live: when the player leaves the activity, the card returns to Default.
- The countdown never stops in any state except Expired.

## Expired, cancelled and hidden invitations (recipient side)

- **Visible card expires** → the card switches to state 4 (Expired) in place, stays **4 s**, then is removed. No Expired toast is shown for it.
- **Hidden card expires** → it is removed from the hidden set, the pill count decreases (the pill disappears at 0), and the **Expired** toast is shown once.
- **Queued (overflow) invitation expires** → it is dropped silently; the player never saw it.
- **Requester cancels** (visible or hidden) → the card (or the hidden entry) is removed immediately and the **Cancelled** toast is shown. A queued one is dropped silently.
- The Expired state in the card and the Expired toast never both show for the same invitation.

## Dismiss (×) and reopen

- × hides the card **locally only**. It never sends a decline; the requester still sees the request as pending until it expires.
- Hidden invitations are kept in memory only for the current session (no persistence, no history).
- A newly arriving invitation is always shown as a card if a slot is free, even if others are hidden; otherwise it is queued.

## Requester side (player A)

- On sending a request from the result page, the **Requested / waiting** toast shows for 4 s. The inline "Rematch requested" block on the result page stays the primary UI there.
- When B accepts: **Accepted** toast, then navigation to the ready check.
- When nobody answers before `expiresAt`: **Expired** toast.
- When B declines: no copy was provided — see open questions.

## Reused components and tokens

Paper components reused (artboards "18 Result — Private, Overtime, Rematch (Free)", "14 Home v0.3", "25 Checkout return — verifying", "19 Report question (modal)"):

| Paper element | Flutter widget |
|---|---|
| Bordered card (discipline card, radius 16) | `AppCard(color: AppColors.white, borderColor: AppColors.border, radius: 16)` |
| Primary / outline buttons ("Find ranked match", "Cancel request") | `AppButton(variant: primary / outline, size: medium)` |
| Opponent avatar (amber initial) | `AppAvatar(size: AppAvatarSize.md, tone: AppAvatarTone.accent)` |
| Countdown (the "42" on the rematch block), rendered as text | `AppCountdownText(format: AppCountdownFormat.clock, suffix: ' left')` |
| RP progress track (discipline card) | 6 px track, `primaryLine` / `primary`, radius 3 (no shared widget; same as the RP bar) |
| Amber note | `AppNotice(tone: AppNoticeTone.warning)` |
| Form error | `AppInlineError` |
| Dot | `AppDot` |
| Close icon (report modal) | `AppIcons.close` via `AppSvgIcon` |
| Success / clock / info icons (checkout return) | `AppIcons.statusSuccess`, `AppIcons.clock`, `AppIcons.info` at 20 px |
| Spinner (checkout return) | same arc style, sizes 14 / 16 / 20 |
| "Go Pro" pill geometry | pending pill (34 high, radius 999, 1.5 px border) |

Colors (all existing in `AppColors`): `primary`, `primarySurface`, `primaryLine`, `ink`, `inkSoft`, `muted`, `faint`, `white`, `surface`, `border`, `divider`, `accent`, `accentSurface`, `accentInk`, `danger`, `success`, `shadow`.
Text styles (all existing in `AppTextStyles`): `titleSm`, `bodyMd`, `bodySm` (18 px line), `buttonLg`, `eyebrow`, `monoBodySm` with w600.

`AppCallout`, `AppTag`, and `ProBadge` were considered and are not used: no title-plus-body callout, tag, or Pro gating is needed here.

## New elements (need implementation)

1. **Overlay elevation shadow**: `BoxShadow(color: AppColors.shadow, offset: (0, 8), blurRadius: 24)`. It applies to cards, toasts and the pill. The file only has `0 1 2` (cards) and the modal `0 24 64 #0E0F1233`. The first is too flat for something floating over content, and the second is too heavy for a stack of three. No new color is added. `AppCard` has no shadow parameter, so either wrap it in a `DecoratedBox` with the shadow or add an optional `shadows` parameter to `AppCard`.
2. **`AppButton` loading state**: today a null `onPressed` dims the primary button to 0.4. "Accepting" / "Declining" need a loading flag that keeps full opacity, shows a 16 px spinner in the label color before the label, and ignores taps.
3. `RematchInviteCard`, `RematchStatusToast`, `RematchPendingPill`, `RematchConnectionIndicator`, `RematchOverlay`: new widgets composed only from the existing widgets above.

No new color, text style, or icon asset is introduced.

## Accessibility

- Every interactive element has at least a 48 x 48 hit area (buttons are 48 high; × and the pill get padded hit areas).
- The card is announced as a live region when it appears ("Rematch request. {nickname} wants a rematch in {discipline}."). Toasts and the inline error are live regions.
- The countdown is not re-announced every second.
- Keyboard: Tab reaches Accept, Decline and × in that order. Esc on a focused card hides it, the same as ×.

## Open questions

1. **Routes**: should the overlay be suppressed on routes where it would get in the way (live battle, ready check, ranked search), or always show (with Accept disabled as Busy)? The design assumes it always shows and uses Busy.
2. **Definition of "busy"**: which activities count (live battle, ranked search queue, ready check, own outgoing rematch, checkout)?
3. **Result page**: on the result page of the same duel, should the overlay card be suppressed in favor of an inline block, or shown in addition?
4. **Reconnecting**: can Accept / Decline still be sent while the socket is down (HTTP), or must they be disabled until reconnect? The design keeps them enabled.
5. **Requester waiting feedback after the 4 s toast**: the request can stay pending for up to 60 s, but the "Waiting for your opponent…" toast hides after 4 s. Outside the result page, A has no visible pending indicator. Is that acceptable, or should the requester toast persist until resolved, with a Cancel action?
6. **Copy not supplied**: plural pill label (`{n} pending rematches`), the `Reconnecting…` label, and what player A sees when B declines (no toast, or a "declined" toast).
7. **More than 3 invitations**: confirm queueing overflow silently rather than surfacing it (for example as "+N more").
8. **Mobile**: this is a desktop (1440) design as requested; a narrow-width variant (full-width cards under the top bar) was not designed.
