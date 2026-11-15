# Global in-app notifications — contract (rematch is the first source)

Design: `docs/specs/rematch_notifications.md`, Paper file **SkillBattles MVP**,
page **"v0.3 — New screens"**, artboards `28 Rematch notifications — Component
sheet`, `29 Rematch invite — Home, one incoming`, `30 Rematch invites — Home,
stacked + hidden pill`.

## Bug this fixes

Player A asks for a rematch, player B leaves the result screen → B never sees
the request. The backend pushes `REMATCH_CHANGED` to both participants on the
personal socket, but only `BattleResultBloc` (closed with the result route)
listens to it. Same for A: if A leaves, A is never taken to the ready check
when B accepts.

## Layers

| Layer | Where | What |
|---|---|---|
| Generic widgets | `lib/core/presentation/widgets/` | `AppNotificationCard`, `AppNotificationToast`, `AppNotificationPill`, `AppConnectionIndicator`, `AppButton(isLoading:)`, `AppShadows.overlay` (or equivalent). Know nothing about rematches or friends. |
| Composition | `lib/app/notifications/` | `AppNotificationsOverlay` (mounted once in `AppShell`), the generic prompt/toast view data, and one adapter per source (`rematch_notifications.dart`) mapping a feature state to that view data. Adding a source later (friends room invitations, friend requests) = one adapter + one more `BlocBuilder`/`BlocListener` in the overlay. |
| State | `lib/features/notifications/presentation/bloc/notification_bloc/` | `NotificationBloc`: one app-scope BLoC for every notification kind, provided next to `AccountBloc`. |

Friend requests and room invitations are kinds of `NotificationBloc` too
(adapter `lib/app/notifications/friends_notifications.dart`); their rules
are in `docs/specs/friends_logic_contract.md` §1.

## 1. Logic — `NotificationBloc` (flutter-logic)

One app-scope BLoC for every in-app notification kind: rematches, friend
requests and room invitations. A new kind is a payload subclass + handlers
+ a UI adapter, not a new BLoC.

**Location:** `lib/features/notifications/presentation/bloc/notification_bloc/`
(`notification_bloc.dart` + `part` files). It consumes use cases of
`battle_result`, `friends`, `account`, `auth` and `core`.

**Provided** in `lib/app/skill_battles_app.dart` in a `MultiBlocProvider` next
to `AccountBloc`, started with `NotificationStarted`. It lives above
`MaterialApp.router`, never inside a route, so it survives navigation away
from the result screen.

**New domain piece:** `BattleResultRepository.watchRematches()` →
`Stream<RematchEntity>` of every `REMATCH_CHANGED`, and `WatchRematchesUsecase
implements Usecase<Stream<RematchEntity>, NoParams>`.

**Constructor (named, required):** `watchRematches`, `getRematch`,
`getResult`, `requestRematch`, `cancelRematch`, `getActivity`,
`watchSignedIn`, `watchConnection`, `isSignedIn` (bool),
`watchSignedInUser`, `watchFriendshipChanges`, `watchDuelInvitationChanges`,
`getFriendRequests`, `getFriendRequest`, `acceptFriendRequest`,
`declineFriendRequest`, `getIncomingDuelInvitations`, `getRoomInvitations`,
`getDuelInvitation`, `acceptDuelInvitation`, `declineDuelInvitation`;
optional `now`.

### API

- `enum NotificationKind { rematch, friendRequest, duelInvitation }`
- `sealed class NotificationPayload`; `RematchNotificationPayload { rematch,
  isIncoming, opponentNickname?, disciplineCode? }`,
  `FriendRequestNotificationPayload { relationship, isDone }`,
  `DuelInvitationNotificationPayload { invitation, isGone }`
  (`isRoomUnavailable`).
- `NotificationItem { id ('<kind>:<resourceId>'), kind, resourceId,
  expiresAt, isPrompt, isHidden, isExpired, action?, payload }` — `isPrompt`:
  shown as a card (incoming rematch); `false` for own outgoing rematch, which
  is tracked only for notices and navigation.
- `NotificationItem.hasDeadline` is false for a friend request: its
  `expiresAt` is only a sort key (`NotificationItem.noDeadline` + creation
  time), so it sorts after every card with a deadline. A room invitation's
  `expiresAt` is already converted to the local clock.
- `NotificationAction { status (accepting / declining / reconciling /
  failed), failure? }`; `reconciling` = an uncertain outcome being re-read
  (friends kinds).
- `NotificationNotice { id, kind, type (accepted / expired / cancelled /
  declined), resourceId, playerNickname?, isOutgoing, invitationReason? }`;
  `isOutgoing` = about the player's own friend request or room invitation.
- `NotificationState { items, notices, battleToOpen?, isBusy, isConnected }`,
  getters `prompts` (isPrompt, not hidden, by `expiresAt`, lingering expired
  included) and `hiddenCount` (isPrompt, hidden, not expired).
- Events, by item id: `NotificationStarted`, `NotificationAcceptRequested(id)`,
  `NotificationDeclineRequested(id)`, `NotificationHidden(id)`,
  `NotificationHiddenShown`, `NotificationActivityRefreshRequested`,
  `NotificationBattleOpened(battleId)`, `NotificationNoticeShown(noticeId)`.
  `NotificationBattleOpened` also marks the id as opened for the session,
  so a screen that navigates itself (the private room on MATCHED) sends it
  first and the bloc never exposes that id as `battleToOpen` afterwards.
  Accept / Decline dispatch by kind with an exhaustive switch on the payload.

### Rules (rematch kind)

- **Ingest everything.** Every `REMATCH_CHANGED` is applied regardless of the
  current route. Hiding the card while that battle's result screen is open is
  a render-time filter in the overlay (§2), never a drop here. Reason: in the
  reported case the request arrives while B is still on the result screen.
- Version guard per resource, keeping the last seen version also after an
  item is removed (tombstone), so a late lower version never reopens it.
- New `sourceBattleId` → `getResult` once for opponent nickname, discipline
  and my id; failure keeps the item with `null` names.
- **Incoming** = `waiting && !hasConsentOf(me)` (`isPrompt: true`).
  **Outgoing** = `waiting && hasConsentOf(me)` (`isPrompt: false`).
- `MATCHED` → remove the item, set `battleToOpen = battleId` once per battle id
  in a session, add an `accepted` notice.
- Expiry is client-driven from `expiresAt` (the backend expires lazily); a
  server `EXPIRED` is handled the same way: visible prompt → `isExpired`,
  removed 4 s later, no notice; hidden prompt → removed + `expired` notice;
  outgoing → removed + `expired` notice.
- `CANCELLED`: incoming → removed + `cancelled` notice, except after this
  player's own successful Decline; outgoing → removed + `declined` notice.
- **Accept** → `requestRematch`: `MATCHED` as above; still `waiting` → apply;
  `REMATCH_EXPIRED` → expired path; `REMATCH_NOT_ALLOWED` → removed +
  `cancelled`; `ACTIVITY_CONFLICT` → `isBusy = true` + `failed`; other →
  `failed`.
- **Decline** → `cancelRematch` (the backend has no decline; cancel ends a
  `waiting` rematch for either participant). Success → removed, no notice.
- Actions on an item with an action in flight are ignored.
- Busy: `getActivity` on start (inside the friends recovery), on a new
  prompt and on `NotificationActivityRefreshRequested`.
- Reconnect → `getRematch` for every known `waiting` item. There is no REST
  list of incoming rematches, so a request made while offline is not
  recovered.
- Signed out → clear everything, cancel timers. No emit after close.

## 2. UI (flutter-ui)

### Generic widgets (`lib/core/presentation/widgets/`)

Exactly as in `rematch_notifications.md` (sizes, colors, states), but generic:

- `AppNotificationCard`: avatar initial, title, body (`TextSpan`s or
  highlighted name + text), optional deadline (`expiresAt`, `lifetime`,
  `clockOffset`) with track + `AppCountdownText`, `isExpired` (+ expired line
  text), optional warning notice text, primary/secondary action labels and
  callbacks with `isLoading` flags, `onHide` (null hides × but keeps its slot),
  optional error text. States 1–5 of the spec.
- `AppNotificationToast`: icon kind (`progress`, `success`, `clock`, `info`) +
  message; a live region.
- `AppNotificationPill`: label + `onPressed`.
- `AppConnectionIndicator`: `Reconnecting…`.
- `AppButton`: add `isLoading` (full opacity, 16 px spinner in the label color
  before the label, taps ignored).
- Overlay shadow `BoxShadow(color: AppColors.shadow, offset: Offset(0, 8),
  blurRadius: 24)` as a shared constant.

### Composition (`lib/app/notifications/`)

- `AppNotificationsOverlay`, mounted once in `AppShell`: the body becomes a
  `Stack` with the routed page and the overlay, anchored top 16 / right 64
  with a 380 px column (below 508 px: `width - 32`, right 16). It never covers
  the top bar.
- `AppShell` receives the current route name and path parameters from the
  `ShellRoute` builder in `app_router.dart` and passes them to the overlay.
- Column order: connection indicator (only while `!isConnected` and a card or
  the pill is shown) → pill (hidden prompts of the one `NotificationBloc`;
  tap sends `NotificationHiddenShown`) → at most 3 cards
  (`AppNotificationPrompt.mergeVisible`, sorted by deadline) → toasts, oldest
  first, each auto-hidden after 4 s.
- `notification_mapper.dart` (`NotificationMapper`) is the per-kind switch
  point: `prompts` (exhaustive switch on `item.payload`), `toast` (switch on
  `notice.kind`), `isSuppressed` (same-screen filter per kind), `pill`
  (`(count, label)`; all rematches → `1 pending rematch` / `{n} pending
  rematches`, mixed kinds → `{n} pending requests`). **A new kind = one case
  in each switch + one adapter file; the overlay does not change.**
- `app_notification_data.dart`: `AppNotificationPrompt` (card view data, `id`
  = item id; `hasDeadline`, `deadlineLabel`, `doneText` forwarded to
  `AppNotificationCard`) and `AppNotificationToastData`.
- `friends_notifications.dart`: the friend request and room invitation
  adapter (copy in `friends_logic_contract.md` §1).
- `rematch_notifications.dart`: the rematch adapter. Card copy: title
  `Rematch request`, body `{nickname} wants a rematch in
  {formatDisciplineCode(code)}.` (`{nickname} wants a rematch.` without a
  discipline, `Your opponent wants a rematch.` without a nickname), Accept /
  Decline, busy text `Finish or leave your current activity before
  accepting.`, error `Couldn't update the rematch request. Try again.`,
  expired line `The rematch request expired.`. Accept disabled when expired,
  `isBusy`, or the item's action is in flight; Decline disabled when expired
  or in flight.
- Toast copy: accepted `Rematch accepted. Opening the ready check…`, expired
  `The rematch request expired.`, cancelled `The rematch request was
  cancelled.`, declined `{nickname} declined the rematch.` (fallback `Your
  opponent declined the rematch.`).
- **Same-battle filter (rematch):** while the current route is `battleResult`
  with `battleId == sourceBattleId`, that rematch's card and hidden count are
  not shown and its notices are consumed without a toast (the inline
  `RematchPanel` is the UI there). Leaving the route shows the card if it is
  still pending.
- Effects in one `MultiBlocListener`:
  - `battleToOpen` → **always** `context.goBattle(id)`, then
    `NotificationBattleOpened(id)`. The battle route is outside the shell, so
    the overlay is never mounted there; when the source result screen
    navigates as well, the second go to the same location is a no-op.
  - new notices → toast queue (unless suppressed) + `NotificationNoticeShown`.
  - route change (`didUpdateWidget`) → `NotificationActivityRefreshRequested`.
- **Stale state on mount:** the overlay is unmounted outside the shell (live
  battle, auth) while the bloc keeps working, and a `BlocListener` never fires
  for the state it mounts with. After its first frame the overlay consumes a
  pending `battleToOpen` (no navigation) and every pending notice (no toast).
  A new kind must not rely on effects that arrive while the shell is
  unmounted. For the host's accepted room invitation the fallback paths are
  in `friends_logic_contract.md` §1 ("Host paths").
- Rebuild scoping per `state_managment.md`: separate selectors for the
  indicator, the pill, the cards and the toasts.

## Not in scope

Tests: `test/features/notifications/`, `test/app/notifications/`, fakes in
`test/helpers/notification_fakes.dart`.

The "Requested / waiting" toast for the requester (the inline result panel
already shows it), server clock offset for rematches (the response has no
server time; `Duration.zero`), recovery of incoming rematches after offline,
a mobile layout.
