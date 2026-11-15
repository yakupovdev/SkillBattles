# Friends and room invitations

Paper file: **SkillBattles MVP**, new page **"v0.4 — Friends"** (placed right after "v0.3 — New screens").
API and UX contract: `docs/specs/friends_contract.md` (source of truth for statuses, fields and error codes).
Global overlay patterns: `docs/specs/rematch_notifications.md` (artboards 28–30).

Base size: 1440 x 900 desktop web, like every artboard in the file. Artboards whose content is taller use `fit-content` height.

Numbering: 31–35 are already used by the battle stickers on "v0.3 — New screens", so this feature starts at **36**.

Canvas layout of the page: row 1 = component sheets 36–38; row 2 = Friends page 39–42; row 3 = friend profile 43–46 and the Remove dialog 47; row 4 = private room 48–50 and the overlay 51.

| Artboard | Purpose |
|---|---|
| `36 Friends — Component sheet` | `FriendCodeCard` (copied, loading/error notes), `AddFriendForm` (12 states, every server code), `FriendRequestRow` (incoming accepting / failed, outgoing default / cancelling / empty, pagination), `RemoveFriendDialog` (removing, failed) |
| `37 Room invitations — Component sheet` | `HostInvitationPanel` (cancelling, declined, expired, friend removed, already pending, rate limited, accepted), `FriendPickerDialog` (sending, send failed, empty, loading/list error notes) |
| `38 Friend & match notifications — Component sheet` | `FriendRequestCard` (default, accepting, network error, done), `MatchInviteCard` (default, accepting, busy, expired, room unavailable, network error), toasts, pending pill |
| `39 Friends — loaded` | Friends page: requests (Incoming tab), friends list page 1 of 3, own code, Add friend |
| `40 Friends — loading (skeleton)` | 39 with data blocks skeletonized |
| `41 Friends — empty` | No incoming requests, no friends |
| `42 Friends — load errors` | Code, requests and friends list each failed independently |
| `43 Friend profile — loaded` | Header + two discipline cards (calibrating / calibrated, open tier, rollover pending, played 0) |
| `44 Friend profile — loading (skeleton)` | 43 skeletonized |
| `45 Friend profile — no longer friends (404)` | FRIEND_NOT_FOUND |
| `46 Friend profile — load error` | Network / other failure |
| `47 Remove friend — confirmation` | Destructive dialog over the Friends page |
| `48 Private room — waiting, Invite friend` | Existing waiting room + `Invite friend` |
| `49 Private room — friend picker` | `FriendPickerDialog` open, friend selected |
| `50 Private room — invitation pending` | `Waiting for {nickname}…`, countdown, `Cancel invitation` |
| `51 Overlay — Home, mixed stack` | Rematch card + match invite + friend request + a toast, with the pending pill |

## Entry point: a new `Friends` top bar tab

`AppNavTab` gets a fifth value, `friends('Friends')`, after `History`. Drawn on every artboard of this page (active on 39–47, inactive on 48–51).

Why a tab and not an account menu item:
- Friends is a destination people return to (copy the code, answer requests, open a profile, pick someone to invite). The account menu (`Account settings`, `Subscription`, `Log out`) holds account administration, which people open rarely.
- The account menu is a `PopupMenuButton` that hides its entries behind a click; a request that arrived while the player hid the overlay card would be two clicks away.
- The bar has room: five 14 px labels with 32 px gaps fit at 1440 next to the Pro pill and the account.
- There is no unread counter or dot on the tab (non-goal). Incoming requests are surfaced by the global overlay.

The friend profile (43–46) keeps `Friends` active; it is a child route of the tab.

## Friends page (39–42)

```
FriendsScreen                              AppDesktopViewport, padding 48 64 64
└── Row(gap 64, crossAxis start)
    ├── Main (Expanded)  Column(gap 40)
    │   ├── PageTitle                      AppEyebrow "Social · Private matches" + "Friends" displayMd
    │   ├── FriendRequestsSection          Column(gap 8)
    │   │   ├── Header Row                 "Requests" titleLg + AppSegmentedControl(small): Incoming | Outgoing
    │   │   ├── FriendRequestRow × n       (see below)
    │   │   └── RequestsPagination         only when totalPages > 1 (same widget as FriendsPagination)
    │   └── FriendsListSection             Column
    │       ├── Header Row                 "Your friends" titleLg + "{totalElements} friends · newest first" bodySm muted
    │       ├── TableHeader                Player (Expanded) | Friends since (160) | actions lane (224); bodyXs muted, 1 px border below
    │       ├── FriendRow × n              (see below)
    │       └── FriendsPagination          "Showing {from}–{to} of {total}" + Previous / Next (AppButton outline compact)
    └── Sidebar (400 fixed)  Column(gap 24)
        ├── FriendCodeCard
        └── AddFriendForm
```

- Page size: **5** for both lists in the design (`size=5`), the same density as the profile match history. Server default is 20; the size is a client choice (open question 1).
- The Incoming / Outgoing switch is one `AppSegmentedControl`; each tab is its own paged request (`direction=INCOMING|OUTGOING`), keeps its own page index and status.
- Ordering is the server's (friendsSince DESC; requests createdAt DESC). No search or sort UI.
- The requests section stays visible with its empty line when a tab is empty, so the switch is always reachable.
- A page beyond the end (e.g. after a removal) is normal: refetch the last valid page; never compute counts locally.

### FriendRow (new)

`Row(gap 14, center)`, padding 10 0, 1 px `divider` bottom border.

| Slot | Widget |
|---|---|
| Identity (Expanded, tappable → profile) | `AppAvatar(size: sm, tone: accent)` + nickname `bodyLg` w600 + `ProBadge()` when `friend.isPro` |
| Friends since (160) | `bodyMd` muted, `MMM d, yyyy` of `friendsSince` |
| Actions (224, end) | `AppTextLink("View profile")` ink w600 14 and `AppTextLink("Remove")` muted w500 14, each in a 48 high hit area |

Remove opens `RemoveFriendDialog`. While a removal of this friend is in flight the row stays, the dialog shows the loading state.

### FriendRequestRow (new)

Same row geometry as `FriendRow` with a two-line identity: nickname (+ `ProBadge`) and `bodySm` muted subtitle.

| Variant | Subtitle | Actions (fixed width so lanes align) |
|---|---|---|
| Incoming (current user = recipient) | `Wants to add you · {createdAt relative}` | `AppButton(primary, field) "Accept"` 112 + `AppButton(outline, field) "Decline"` 112 |
| Outgoing (current user = requester) | `Request sent · {createdAt relative}` | `AppButton(outline, field) "Cancel request"` 160. Never Accept. |

| State | Accept | Decline / Cancel request | Extra |
|---|---|---|---|
| Default | enabled | enabled | — |
| Accepting | loading (spinner + label, full opacity) | disabled (1 px light border, faint) | — |
| Declining | disabled | loading | — |
| Cancelling (outgoing) | — | loading (ink spinner) | — |
| Failed | enabled | enabled | `AppInlineError("Couldn't update the friend request. Try again.")` under the row, indented 50 px to the text lane; cleared on the next tap |
| Done | — | — | row is removed after the refetch; Accept also refreshes the friends list |

The in-flight state is per row (other rows stay interactive). FRIEND_REQUEST_NOT_PENDING / FRIEND_REQUEST_NOT_FOUND: refetch the list silently (the row disappears or moves); no error copy. An ambiguous network failure never implies success: restore the request with `GET /friend-requests/{id}` before showing the failed state.

### FriendCodeCard (new)

`AppCard(color: white, radius 16, padding 24)`, `Column(gap 16)`:
1. `AppEyebrow("Your friend code")`
2. Code `JetBrains Mono 30/36 w600 +0.02em` ink, shown grouped `XXXX-XXXX-XXXX`. The grouping is display only; Copy writes the canonical 12 characters from the server.
3. `AppButton(dark, medium, icon: AppIcons.copy) "Copy code"` → for 2 s `"Copied"` with a check icon (see New elements), then back.
4. `bodySm` 13/18 muted: `Friends enter this code to send you a request. It is not a room code, and only you can see it.`

Loading: the code text and the Copy button are skeletonized with mock data; the eyebrow and the explanation stay visible (`Skeleton.keep`). Error: code and button replaced by `AppInlineError("Couldn't load your friend code.")` + `AppButton(outline, field) "Try again"` in a row (42).

### AddFriendForm (new)

`AppCard(radius 16, padding 24)`, `Column(gap 16)`: title `"Add a friend"` titleMd, `bodySm` 13/18 muted `Ask for their friend code and send a request. They accept it from their notifications.`, then a row of `AppTextField(label: "Friend code", hintText: "ABCD-2345-EFGH")` (Expanded) and `AppButton(dark, field) "Send"`, then the helper / error / notice line.

Form rules (`.claude/docs/architecture/forms.md`): the screen validates and builds `SendFriendRequestParamsEntity(friendCode:)` on submit; the field value is not stored in the BLoC. Client validation mirrors the server: trim, drop ASCII hyphens, uppercase; then exactly 12 characters of `ABCDEFGHJKMNPQRSTUVWXYZ23456789`; internal whitespace invalid. The raw input (up to 32 chars) is sent; the server canonicalizes.

| # | State | Field | Send | Line under the field |
|---|---|---|---|---|
| 1 | Empty | rest | disabled | helper `12 letters and digits. Hyphens and spaces around it are fine.` |
| 2 | Typed / focused | focused (blue 1.5) | enabled | helper |
| 3 | Sending | disabled (grey fill, muted text) | loading | helper |
| 4 | Sent (201) | cleared | disabled (empty) | `AppNotice(success)`: `Request sent to {recipient.nickname}. It's under Outgoing.` Outgoing tab refetches. |
| 5 | Already sent by you (200) | cleared | disabled | `AppNotice(info)`: `You already sent {nickname} a request. It's under Outgoing.` |
| 6 | FRIEND_REQUEST_ALREADY_RECEIVED (409) | kept | enabled | `AppNotice(info, actionLabel: "Show")`: `This player already sent you a request. Accept it under Incoming.` "Show" switches to Incoming and scrolls to the requests. Incoming refetches. Never auto-accept. |
| 7 | Invalid format (client, on Send) | error (red 1.5) | enabled | errorText `Enter 12 characters like ABCD-2345-EFGH. Codes never use I, L, O, 0 or 1.` (also for server VALIDATION_ERROR) |
| 8 | FRIEND_CODE_NOT_FOUND (404) | error | enabled | errorText `No player has this friend code. Check it and try again.` |
| 9 | SELF_FRIEND_REQUEST_NOT_ALLOWED (409) | error | enabled | errorText `That's your own friend code. Share it with a friend instead.` |
| 10 | FRIEND_ALREADY_EXISTS (409) | error | enabled | errorText `You're already friends with this player.` |
| 11 | RATE_LIMITED (429) | error | disabled until Retry-After passes | errorText `Too many requests. Try again in {mm:ss}.` (`AppCountdownText` inline, mono w600). When it reaches 0 the error clears and Send enables. |
| 12 | Network / other | rest | enabled | `AppInlineError("Couldn't send the request. Check your connection and try again.")` |

Server errors (8–11) go through `AppTextField.errorText`; they clear when the user edits the field.

### Empty, loading, error (40–42)

- **Loading (40)**: the content of the requests list, of the friends list, and the code text + Copy button of `FriendCodeCard` are skeletonized with mock data. Stay visible: page title, section titles, the Incoming / Outgoing switch, the table header, the code eyebrow and explanation, and the whole `AddFriendForm` (it does not depend on a request). Hidden while loading: pagination (`Skeleton.ignore`); the friends count line is skeletonized. Three independent `Skeletonizer`s (code, requests, friends), each keyed on its own status.
- **Empty (41)**: incoming empty → a line block `No incoming requests` / `When someone enters your friend code, their request shows up here and as a notification.`; outgoing empty → `No outgoing requests` / `Requests you send with a friend code wait here until they're answered.` (sheet 36, E). Friends empty → `AppEmptyView` on a `surface` tile: `No friends yet` / `Share your friend code, or enter a friend's code on the right. Once they accept, you can invite each other to private matches.` + `AppButton(outline, medium) "Copy your friend code"`. The count line and table header are hidden.
- **Errors (42)**: each block fails on its own. Requests: inline `Couldn't load your requests. Check your connection and try again.` (danger) + `Try again`. Friends: `AppErrorView(title: "Couldn't load your friends", message: "Check your connection and try again. Your friends are safe; nothing was removed.")`. Code: see `FriendCodeCard`.
- A refresh with data on screen keeps the data (no skeleton).

## RemoveFriendDialog (47, sheet 36)

Shell of "19 Report question": `Dialog`, white, radius 20, `AppColors.dialogShadow` 0 24 64, padding 32, width 480, `Column(gap 22)`, barrier `AppColors.scrim`.

```
RemoveFriendDialog
├── Header Row(start, space-between)
│   ├── Column(gap 8): AppEyebrow("Friends since {MMM d, yyyy}") + "Remove {nickname}?" (Space Grotesk 28/32 bold -0.02em)
│   └── CloseButton  AppIcons.close 20, 48 hit
├── Body  bodyMd 14/20 muted
├── [AppInlineError]  failed only
└── Actions Row(end, gap 10)
    ├── AppTextLink "Cancel"  muted w500, 48 hit
    └── AppButton(variant: danger (NEW), size: field) "Remove friend"
```

Body: `You'll disappear from each other's Friends and can't invite each other to private matches. A pending match invitation between you is cancelled. You can add each other again later with a friend code.`

| State | Cancel / × / Esc / barrier | Remove friend |
|---|---|---|
| Default | close | enabled |
| Removing | disabled (faint), × hidden (slot kept), not dismissible | loading (white spinner + label) |
| Failed | enabled | enabled (retry); `AppInlineError("Couldn't remove {nickname}. Check your connection and try again.")` above actions |
| Success (204) | dialog closes; on the profile → back to Friends; the list refetches. No toast. |

DELETE is idempotent: an already-removed friend is a success. An ambiguous failure never implies success: refetch the friends list before deciding.

## Friend profile (43–46)

```
FriendProfileScreen                        padding 24 64 64, Column(gap 32)
├── BackLink  AppTextLink(chevronLeft) "Friends", 48 high
├── FriendProfileHeader Row(center, space-between)
│   ├── Row(gap 20): AppAvatar(xl, accent) + Column(gap 4):
│   │     Row(gap 12): nickname displaySm + ProBadge() (public badge only)
│   │     "Friends since {MMMM d, yyyy}" bodyMd muted
│   └── AppButton(outline, field) "Remove friend" → RemoveFriendDialog
└── DisciplineCards  Row(gap 24) of FriendDisciplineCard, one per entry of `disciplines` (two per row; a third wraps)
```

### FriendDisciplineCard (new)

`AppCard(color: white, radius 16, padding 28)`, `Column(gap 24)`. Built from the pieces of the home discipline card (`home_discipline_cards.dart`), not selectable:

1. **Head** Row: discipline display name (`titleXlCompact`, from the catalog by `disciplineCode`) + calibration status at the end:
   - `isCalibrating`: the existing `×2 ELO` chip + `Calibrating · {matchesRemaining} of {completed + remaining} matches left` bodySm `primaryInk`.
   - done: `Calibrated` bodySm muted.
2. **[Rollover notice]** when `seasonRolloverPending`: `AppNotice(warning)` `Season reset pending. These numbers update when the new season starts.`
3. **LeagueHero** Row(gap 16): emblem circle 88 (league `tint` fill, 1 px `base` border, `LeagueEmblem` 72) + `LEAGUE` caption (monoCaption +0.1em muted) and `rank.rankName` 30/34 bold in `palette.nameText` + rating (mono 28/32) with `Elo rating` bodyXs muted.
4. **DivisionProgress** when `divisionRpTarget != null`: `{divisionRpCurrent} / {divisionRpTarget} RP` (eyebrow mono, inkSoft) + `AppProgressBar(height 8, color: palette.deep, track: divider)`. Open tier (`divisionRpTarget == null`): text `Open tier · no RP cap`, no bar.
5. **Peaks** Row(gap 24), top divider: `All-time peak` → `{allTimePeakRating} · {rank name of allTimePeakRankCode}`; `Season peak` → `{seasonPeakRating} · {name of seasonPeakRankCode}`. Label bodyXs muted, value bodyLg with the number in mono w600.
6. **MatchCounters** Row(gap 24), top divider: two `MatchCountsColumn`s, `RANKED` (from `ranked`) and `PRIVATE` (from `privateMatches`, left divider). Rows (label bodyMd muted, value monoBodyMd ink, right aligned):

| Row | Value | Null / zero rule |
|---|---|---|
| W–L–D | `{wins}–{losses}–{draws}` | zeros shown (`0–0–0`) |
| Played | `{played}` | `0` shown |
| Win rate | `{winRatePercent}%` (1 decimal, trailing `.0` dropped) | null (played = 0) → `—` in `faint` |
| Win streak · best | `{currentWinStreak} · {bestWinStreak}` | zeros shown |
| Accuracy | `{accuracyPercent}%` | null → `—` |
| Avg answer time | `{avgAnswerTimeMs / 1000}s` (1 decimal) | null → `—` |

`questionCount` is not displayed (open question 4). Not shown, by contract: topic analytics, rating chart, match history, answer review, Pro upsell, email, friend code.

States:
- **Loading (44)**: the content of the header (avatar, nickname, badge, friends since) and of the discipline cards is skeletonized with mock data. Stay visible: back link and the static labels (`LEAGUE`, `Elo rating`, peak labels, `RANKED` / `PRIVATE`, counter row labels) via `Skeleton.keep`. Hidden: `Remove friend` (`Skeleton.ignore`) and the rollover notice (not part of the mock data). The emblem is one bone (`Skeleton.leaf`).
- **No longer friends (45)**, 404 FRIEND_NOT_FOUND (also when a FRIENDSHIP_CHANGED REMOVED for this relationship id arrives while open): stale data is cleared; `AppEmptyView(title: "This profile is no longer available", message: "You are no longer friends with this player.")` + `AppButton(outline, medium) "Back to Friends"`. Header and Remove are hidden.
- **Error (46)**: `AppErrorView(title: "Couldn't load this profile", message: "Check your connection and try again.")` + Try again.

## Private room, host side (48–50, sheet 37)

The existing `PrivateDuelScreen` (`_CodeColumn` + `_RoomCard`) is unchanged except for the room card's guest slot and a new slot under it. Only the host sees it, and only while `duel.status == WAITING`.

```
_RoomCard (unchanged shell: radius 20, 1 px border, padding 32, gap 24)
├── Header "Ready check" + "1 of 2 joined"
├── PlayerRows
│   ├── _PlayerRow (host, you)
│   └── HostInvitationPanel.guestSlot      _WaitingRow  |  HostInvitationRow (pending)  |  _PlayerRow (joined)
├── HostInvitationPanel.actionSlot (NEW)   AppButton(outline, medium, expand) "Invite friend" | "Cancel invitation" + [AppNotice] + [AppInlineError]
├── Hint text (unchanged)
└── Cancel duel (unchanged)
```

`_WaitingRow` subtitle changes from `Share the code to invite them` to `Share the code or invite a friend`.

### HostInvitationRow (new, replaces `_WaitingRow` while PENDING)

Same 1 px bordered 12 radius box as `_WaitingRow`, padding 15, `Column(gap 14)`:
- Row(gap 14): `AppAvatar(md, accent)` + Column: `Waiting for {recipient.nickname}…` bodyLg w600 ink, `Invitation sent · the code still works` bodySm muted + `AppCountdownText(target: expiresAt, clockOffset, format: clock)` monoBodySm w600 primary in the 72 px `_RowStatus` lane.
- Deadline track: 6 px, radius 3, `primaryLine` / `primary`, fill = remaining / (expiresAt − createdAt). Same as the rematch card.

### States (sheet 37)

| # | Invitation | Guest slot | Action slot | Message |
|---|---|---|---|---|
| — | none (48) | `_WaitingRow` | `Invite friend` | — |
| 1 | PENDING (50) | `HostInvitationRow` | `Cancel invitation` | — |
| 1b | PENDING, cancelling | `HostInvitationRow` | `Cancel invitation` loading | — |
| 2 | DECLINED | `_WaitingRow` | `Invite friend` | `AppNotice(info)` `{nickname} declined the invitation.` |
| 3 | EXPIRED (INVITATION_EXPIRED) | `_WaitingRow` | `Invite friend` | `AppNotice(info)` `This invitation expired.` |
| 4 | CANCELLED / FRIEND_REMOVED | `_WaitingRow` | `Invite friend` | `AppNotice(warning)` `You are no longer friends with this player.` |
| 5 | DUEL_INVITATION_ALREADY_PENDING (409) | recovered `HostInvitationRow` (GET /duels/{id}/invitations) | `Cancel invitation` | `AppInlineError` `This room already has a pending invitation. Cancel it before inviting someone else.` |
| 6 | RATE_LIMITED (429) | `_WaitingRow` | `Invite friend` disabled until Retry-After | `AppInlineError` `Too many invitations. Try again in {mm:ss}.` |
| 7 | ACCEPTED | `_PlayerRow` (guest, accent), subtitle `Accepted your invitation`, status `Joined` | hidden (room no longer WAITING) | hint becomes `Opening the ready check…`; navigation once per battleId |

- After 2, 3, 4 (or a cancelled-by-host 204) the host can invite again; the notice clears when the picker opens. The room is never cancelled by an invitation outcome.
- CANCELLED / SENDER_CANCELLED (own cancel): back to the default slot, no notice. DUEL_FILLED / DUEL_CANCELLED / DUEL_EXPIRED: the room state already explains it (existing closed-room copy); no extra notice.
- MATCH_ALREADY_FOUND (409) on cancel: no error copy; recover invitation + activity (the match is starting).
- Other failures on cancel: `AppInlineError("Couldn't cancel the invitation. Try again.")`.

### FriendPickerDialog (new, 49, sheet 37)

Report-dialog shell, width 520. Title block (`AppEyebrow("Private duel · {discipline}")` + `Invite a friend`), × close, body `They get a notification anywhere in SkillBattles and have up to a minute to accept. Accepting brings them into this room.`, then the list, pagination, actions.

- `FriendPickerRow` (new): 56 high, radius 10, the radio of "19 Report question" (selected: 2 px `primary` border + `primarySurface`; rest: 1 px `border`, 17 px inset) + `AppAvatar(row (32), accent)` + nickname bodyLg (w600 selected / w500) + `Friends since {MMM d}` bodySm muted. Whole row is the 48+ hit target; single selection.
- Pagination: `{from}–{to} of {total} friends` + Previous / Next compact (paged `GET /friends`, size 5).
- Actions: `AppTextLink "Cancel"` + `AppButton(primary, field) "Send invitation"` (disabled until a friend is selected).

| State | List | Send | Notes |
|---|---|---|---|
| Loading | content of the list skeletonized with mock data; taps inert | disabled | title, body, Cancel stay |
| Default / selected (49) | interactive | enabled when selected | — |
| Sending | dimmed 0.6, locked | loading | not dismissible; one `requestId` per Send intent, kept on retries |
| Send failed (network) | interactive | enabled (retry, same requestId) | `AppInlineError("Couldn't send the invitation. Try again.")` |
| FRIEND_NOT_FOUND (404) | refetched, selection cleared | disabled | `AppInlineError("You are no longer friends with this player.")`; a new Send gets a new requestId |
| DUEL_INVITATION_ALREADY_PENDING / RATE_LIMITED | dialog closes | — | message shown in the room card (states 5, 6) |
| DUEL_NOT_JOINABLE / DUEL_EXPIRED / DUEL_NOT_FOUND | dialog closes | — | the room shows its closed state |
| Empty (no friends) | replaced by compact `AppEmptyView` on `surface`: `No friends to invite yet` / `Add friends with a friend code, or share this room's code instead.` + `AppButton(dark, medium) "Add friends"` (→ Friends tab) | hidden | — |
| List error | `AppErrorView` `Couldn't load your friends.` + Try again | disabled | — |
| Success (201/200) | dialog closes | — | room card shows `HostInvitationRow` |

## Global overlay (38, 51)

The rematch overlay becomes a shared **notification overlay**: same `Stack` + `Positioned(top: 16, right: 64)` under the 72 px top bar, 380 px column, 12 px gaps, at most **3 cards**, overflow queued, × hides locally (never declines), the connection indicator and the pending pill at the top, toasts at the bottom (oldest first). Decoders, actions and state stay separate per resource (rematch, room invitation, friend request), as the contract requires; only the rendering column is shared.

Card order and slots:
- Cards with a deadline (rematch, match invitation) come first, sorted by `expiresAt` ascending; friend requests (no deadline) follow, by `createdAt` ascending. 51 shows: rematch (0:12) → match invitation (0:48) → friend request → toast.
- **Pre-emption**: a deadline card always takes a slot. When the 3 slots are full and a rematch or match invitation arrives, the last visible friend request moves back to the queue (not hidden, not counted in the pill) and returns when a slot frees. A friend request never displaces a deadline card. This keeps a 60 s invitation from expiring unseen behind requests that never expire.

### FriendRequestCard (new)

`RematchInviteCard` anatomy without the Deadline row:
- Header: `AppAvatar(md, accent)` + `Friend request` titleSm + `{nickname} wants to add you as a friend.` (bodySm 13/18 muted, nickname w600 ink) + × (20 px, 48 hit).
- Actions: `AppButton(primary, medium, expand) "Accept"` + `AppButton(outline, medium, expand) "Decline"`.

| # | State | Accept | Decline | × | Extra |
|---|---|---|---|---|---|
| 1 | Default | enabled | enabled | enabled | — |
| 2 | Accepting | loading | disabled | hidden (slot kept) | — |
| 2b | Declining (not drawn) | disabled | loading | hidden | mirror of 2 |
| 3 | Network error | enabled (retry) | enabled | enabled | `AppInlineError("Couldn't update the friend request. Try again.")` |
| 4 | Done (accepted) | — | — | enabled | Actions replaced by a 48 high line: `AppIcons.statusSuccess` 20 + `You and {nickname} are now friends.` (bodyMd w500 inkSoft); removed after 4 s |

- Decline success → card removed, no toast. No countdown, no expiry state (friend requests never expire).
- Shown only when the current user is the recipient. If the request is resolved elsewhere (Friends page, other tab, requester cancelled), the card is removed silently. FRIEND_REQUEST_NOT_PENDING / NOT_FOUND on a tap: restore with `GET /friend-requests/{id}` and remove the card (Done state if it turns out ACCEPTED).
- Hidden friend requests stay reachable from the pill and from Friends → Requests.

### MatchInviteCard (new)

`RematchInviteCard` anatomy: header (`Match invitation` / `{host.nickname} invited you to a private {discipline display name} match.`), Deadline row (track + `AppCountdownText(suffix: ' left')`), Actions. No room code.

| # | State | Accept | Decline | × | Extra |
|---|---|---|---|---|---|
| 1 | Default | enabled | enabled | enabled | countdown running |
| 2 | Accepting | loading | disabled | hidden (slot kept) | countdown runs |
| 3 | Busy (own activity QUEUE / PRIVATE_DUEL / BATTLE, or 409 ACTIVITY_CONFLICT) | disabled (0.4) | enabled | enabled | `AppNotice(warning)` `Finish or leave your current activity before accepting.` between Deadline and Actions; invitation stays PENDING |
| 4 | Expired (EXPIRED, or 410 DUEL_INVITATION_EXPIRED) | disabled | disabled | enabled | empty track on `divider`, `0:00` faint, `This invitation expired.` (bodyMd w500 inkSoft); removed after 4 s |
| 5 | Room unavailable (CANCELLED with DUEL_CANCELLED / DUEL_FILLED, EXPIRED with DUEL_EXPIRED, or 404 on Accept after the activity check below) | disabled | disabled | enabled | empty track, `—`, `This room is no longer available.`; removed after 4 s |
| 6 | Network error | enabled (retry) | enabled | enabled | `AppInlineError("Couldn't update the invitation. Try again.")` |
| 7 | Content unavailable (409 CONTENT_UNAVAILABLE on Accept; not drawn) | enabled (retry) | enabled | enabled | the invitation stays PENDING and the countdown keeps running; `AppNotice(warning)` in the busy slot. Copy not supplied (open question 7); proposal: `Questions for this discipline are unavailable right now. Try again in a moment.` |

Error handling on Accept / Decline:
- **404 on Accept**: first refetch own activity; if it is `BATTLE` with a battleId, treat as accepted (navigate once). Otherwise state 5.
- **409 DUEL_INVITATION_NOT_PENDING on Accept**: restore with `GET /duel-invitations/{id}` and render the terminal state it returns (4, 5, or accepted → navigate; DECLINED → remove).
- **409 MATCH_ALREADY_FOUND on Decline**: no error copy; recover the invitation and own activity (the match is starting).
- An ambiguous network failure never implies accept: restore the invitation and activity before showing state 6.

Other rules:
- Accept success (ACCEPTED + battleId) → card removed, `Invitation accepted. Opening the ready check…` toast, navigation to the battle Ready flow once per battleId.
- CANCELLED / SENDER_CANCELLED or FRIEND_REMOVED on a visible card → card removed + `The match invitation was cancelled.` toast. On a hidden one → same toast. Queued → dropped silently.
- Hidden card expires → `The match invitation expired.` toast (same rule as rematch).
- Expired state is driven by the invitation state from `expiresAt` + server clock offset, not by the widget reaching zero.

### Toasts (new copy on the existing `RematchStatusToast` anatomy)

| Variant | Who | Icon | Copy |
|---|---|---|---|
| Friend request accepted | requester | `AppIcons.statusSuccess` | `{nickname} accepted your friend request.` |
| Invitation accepted | invitee after Accept; host when the friend accepts | `AppIcons.statusSuccess` | `Invitation accepted. Opening the ready check…` |
| Invitation expired | invitee, hidden card only | `AppIcons.clock` | `The match invitation expired.` |
| Invitation cancelled | invitee | `AppIcons.info` | `The match invitation was cancelled.` |

Auto-hide 4 s, live region, no actions. No toast for a declined friend request (the requester just sees the row leave Outgoing) and none for a request to yourself.

### Pending pill

`RematchPendingPill` is reused as `NotificationPendingPill`, counting every hidden, still-pending card of any type. Label: `1 pending request` / `{n} pending requests` (one word for rematches, invitations and friend requests). Tap un-hides all. Queued (pre-empted or overflow) cards are not counted.

## Component tree summary and Flutter mapping

| Paper element | Flutter widget |
|---|---|
| Top bar + `Friends` tab | `AppTopBar` with `AppNavTab.friends` (new enum value) |
| Bordered cards | `AppCard(color: white, borderColor: border, radius 16)` |
| Buttons | `AppButton` primary / dark / outline, sizes medium / field / compact |
| Text links (View profile, Remove, Cancel, back) | `AppTextLink` in a 48 px hit area (layers named `AppTextLink — …`) |
| Avatars | `AppAvatar` sizes sm (36), row (32), md (44), xl (72), tone accent for other players |
| Pro badge | `ProBadge()` (ink tone) |
| Incoming / Outgoing | `AppSegmentedControl(size: small)` |
| Friend code input | `AppTextField(errorText:, helperText:, hintText:)` |
| Notes | `AppNotice` tones info / success / warning, `actionLabel` for "Show" |
| Errors | `AppInlineError`, `AppErrorView`, `AppEmptyView` |
| Countdown | `AppCountdownText(format: clock)` |
| RP bar | `AppProgressBar` |
| League | `LeagueEmblem`, `LeagueColors`, `LeagueRank`, `×2 ELO` chip (from home cards) |
| Dialog shell | the `ReportRoundDialog` shell (Dialog, radius 20, dialog shadow, scrim) |
| Overlay cards, toast, pill, indicator | rematch overlay widgets (`rematch_notifications.md`) |
| Skeletons | `Skeletonizer` + `FriendsSkeletonData` / `FriendProfileSkeletonData` in `presentation/widgets/` |

## New elements (need implementation)

1. **`AppNavTab.friends`** — new tab (see Entry point).
2. **`AppButtonVariant.danger`** — red fill (`AppColors.danger`), white label, for `Remove friend`. No destructive button exists in the code or Paper (log out is a red menu text). No new color: it uses `danger`.
3. **`AppButton` loading flag** — already requested by `rematch_notifications.md` and still missing in `app_button.dart`; used here by every Accept / Decline / Send / Remove / Cancel in-flight state. Spinner in the label color (white on primary/dark/danger, ink on outline).
4. **"Copied" state of the Copy button** — a check glyph (16 px) for 2 s. `AppIcons.check` is a 12 px white tick made for the radio; either reuse it at 16 px or export a `check_16.svg`. No snackbar (the room screen uses a `Code copied` snackbar; the friends card shows it in the button instead).
5. **Overlay generalization** — `RematchOverlay` → shared notification overlay hosting three card types with the pre-emption rule; `RematchPendingPill` → generic pill copy.
6. New composite widgets (from existing ones only): `FriendCodeCard`, `AddFriendForm`, `FriendRow`, `FriendRequestRow`, `FriendsPagination` (or reuse the history pagination widget if one exists), `RemoveFriendDialog`, `FriendDisciplineCard`, `MatchCountsColumn`, `HostInvitationPanel`, `HostInvitationRow`, `FriendPickerDialog`, `FriendPickerRow`, `FriendRequestCard`, `MatchInviteCard`.

No new color token, text style or font is introduced in the app. The friend code size (JetBrains Mono 30/36 w600) is a one-off `monoLg.copyWith(fontSize: 30, height: 36/30, letterSpacing: 0.02*30)`.

Paper note: skeleton artboards (40, 44) simulate bones with the "Flow Block" font in `skeletonLight` plus filled boxes; the font was added to the Paper file only for this. The app uses `Skeletonizer` over the real widgets.

## Accessibility

- All buttons are 48 high; text links, ×, picker rows and pagination (36 visual, padded hit area) reach 48 x 48.
- Overlay cards, toasts, inline errors and `AppNotice` are live regions. Countdowns are not re-announced.
- The picker rows are a radio group (`Semantics(inMutuallyExclusiveGroup, checked)`).
- The friend code is read character by character (`Semantics(label: 'Friend code K 7 Q M …')`), like the room code tiles.
- Nicknames are plain `Text`, never rich-text markup.

## Conflicts between Paper and the code

1. **"04 Private Duel" (Page 1) vs `PrivateDuelScreen`**: Paper shows a joined guest with `Ready` / `I'm ready` / `0:24 left`; the code shows `1 of 2 joined`, a `_WaitingRow` and `In room` / `Joined`. 48–50 follow the **code** (the WAITING state) because the invite flow only exists in that state.
2. **"14 Home v0.3" vs `HomeDisciplineCards`**: the code renders league emblems, pips and next league (Paper "Leagues — concepts" page), while 14 shows the older card. 51 reuses the 30 artboard (old home) as background only; the friend profile cards follow the **code / leagues concept** look.
3. **Account menu** exists in code (`Account settings`, `Subscription`, `Log out`) but is not drawn in Paper; not needed after choosing the tab.
4. **`AppButton` loading** is specified in `rematch_notifications.md` but not implemented yet.

## Decisions (approved by the user, 2026-11-15)

1. **Page size**: 20 for friends and for each request direction (server default). Lists scroll inside their section; pagination controls stay as drawn.
2. **Entry point**: new top bar tab `Friends` after History (`AppNavTab.friends`), no counter or dot.
3. **Recovery and re-showing**: after startup and every reconnect, every recovered pending incoming friend request and room invitation shows as an overlay card (subject to the 3-card limit and the queue rules). × hides it for the current session only.
4. **`questionCount`**: not shown on the friend profile.
5. **Busy definition**: the invitee is busy for every own activity other than `NONE` (QUEUE, PRIVATE_DUEL, BATTLE). Accept is disabled with the busy notice; Decline stays enabled.
6. **Host toast**: the host gets the "accepted" toast and is taken to the Ready screen from any route, not only the room screen.
7. **Copy**: the copy drawn in Paper (artboards 36–38) is approved. Where the contract supplies copy, the contract text wins.
8. **Pending pill**: allowed. It counts hidden pending items and disappears when none are hidden; it is not an unread counter.
9. **Requests section**: stays above the friends list.
10. **Narrow widths**: out of scope (desktop 1440 only, like the rest of the file).
