# Friends and room invitations: logic contract for flutter-ui

Source of truth for behavior: `docs/specs/friends_contract.md`. This file
describes the BLoC surface the UI builds on. Everything lives in
`lib/features/friends/`. Navigation, dialogs, toasts and copy stay in the
UI; the BLoCs never navigate.

Approved product decisions (`docs/specs/friends.md`, "Decisions") applied
here: page size 20 for friends and for each request direction, shown one
page at a time (Previous / Next); recovery
re-shows every pending item; × is a session-only local hide; the invitee is
busy for every activity other than NONE; the host gets the "accepted" toast
and goes to Ready from any route; `questionCount` stays in
`MatchStatsEntity` but is not shown on the friend profile.

All BLoCs follow `state_managment.md`: independent statuses per request,
`LoadStatus` (`initial/loading/success/failure`), failures kept until the
next meaningful action, nullable fields cleared with `reset*` flags, and
latest-wins guards after every `await`.

## Shared domain types (`domain/entity/`)

| Type | Fields the UI reads |
|---|---|
| `FriendCodeEntity` | `code` (12 chars, canonical, no hyphens). Group it as `ABCD-2345-EFGH` for display only. Copy the canonical code. |
| `RelationshipEntity` | `id` (relationship/request id, never a user id), `requester`, `recipient` (`PublicPlayerEntity`), `status` (`RelationshipStatus`), `createdAt`, `updatedAt`, `acceptedAt?`, `version`, `direction` (`FriendRequestDirection.incoming/outgoing`), getters `isIncoming`, `otherPlayer`, `canRespond` (Accept/Decline), `canCancel`. |
| `FriendListItemEntity` | `relationshipId`, `friend` (`PublicPlayerEntity`; `friend.id` is the USER id for profile, remove, invite), `friendsSince`, `version`. |
| `FriendProfileEntity` | `friend`, `friendsSince`, `disciplines` (`List<FriendDisciplineStatsEntity>`). |
| `FriendDisciplineStatsEntity` | `disciplineCode`, `rating`, `rank` (`RankProgressEntity`), `calibration` (`CalibrationEntity`), `allTimePeakRating`, `allTimePeakRankCode`, `seasonId`, `seasonPeakRating`, `seasonPeakRankCode`, `seasonRolloverPending`, `ranked`, `privateMatches` (`MatchStatsEntity`). |
| `DuelInvitationEntity` | `id` (invitation id), `duelId` (room), `host`, `recipient`, `disciplineCode`, `status` (`DuelInvitationStatus`), `reason?` (`DuelInvitationReason`), `createdAt`, `expiresAt` (server clock), `battleId?`, `version`, `isIncoming`. |

`RankProgressEntity`, `CalibrationEntity` and `MatchStatsEntity` moved to
`lib/core/domain/entity/` (same classes the own profile already renders), so
the existing rank/stat widgets accept friend data unchanged. `MatchStatsEntity`
nullable fields (`winRatePercent`, `accuracyPercent`, `avgAnswerTime`) mean
"no data": render a dash, never 0. Friends never get topic analytics, rating
history or answers, whatever the plan. Do not show a Pro upsell there.

Countdowns (host row): `AppCountdownText(target: invitation.expiresAt, clockOffset: state.clockOffset)` of `RoomInvitationState`.

## Use cases (resolve with `getDep<...>()`)

`GetFriendCodeUsecase`, `GetFriendsUsecase`, `GetFriendProfileUsecase`,
`RemoveFriendUsecase`, `SendFriendRequestUsecase`, `GetFriendRequestsUsecase`,
`GetFriendRequestUsecase`, `AcceptFriendRequestUsecase`,
`DeclineFriendRequestUsecase`, `CancelFriendRequestUsecase`,
`SendDuelInvitationUsecase`, `GetRoomInvitationsUsecase`,
`GetIncomingDuelInvitationsUsecase`, `GetDuelInvitationUsecase`,
`AcceptDuelInvitationUsecase`, `DeclineDuelInvitationUsecase`,
`WithdrawDuelInvitationUsecase`, `WatchFriendshipChangesUsecase`,
`WatchDuelInvitationChangesUsecase`, `WatchSignedInUserUsecase` (all in
`features/friends/domain/usecases/`). Also used: `WatchConnectionUsecase`,
`GenerateIdUsecase` (core), `GetActivityUsecase` (account).

The two watch streams carry the realtime pushes plus the records returned
by this app's own send/get/accept/decline calls, so several BLoCs converge
by id + version even when a push is lost. Commands answered with 204
(cancel request, remove friend, withdraw invitation) emit nothing; their
BLoCs refetch instead.

Direction is mapped for the user who started the HTTP operation. Its result
is published to the watch streams only while that user is still signed in;
an old account's late response never becomes a new account's notification.
Refreshing tokens for the same user keeps the streams working.

## 1. Overlay notifications: `NotificationBloc` (app scope)

Incoming friend requests, incoming room invitations and the host's own
invitation are two kinds of the app-wide `NotificationBloc`
(`lib/features/notifications/presentation/bloc/notification_bloc/`), next to
rematches. There is no friends-specific app-scope BLoC. The full generic
contract (items, notices, overlay) is `docs/specs/app_notifications_contract.md`;
this section is the friends part.

**Provided** in `lib/app/skill_battles_app.dart` (`lazy: false`, started
with `NotificationStarted`). The overlay (`lib/app/notifications/`) renders
it; screens only send `NotificationBattleOpened` (below).

**Kinds and items** (`NotificationItem.id = '<kind>:<resourceId>'`):

| Kind | Item | Payload |
|---|---|---|
| `NotificationKind.friendRequest` | prompt per incoming PENDING request, `resourceId` = relationship id; sorted after every card with a deadline, oldest first (`hasDeadline == false`) | `FriendRequestNotificationPayload { relationship, isDone }` |
| `NotificationKind.duelInvitation` | prompt per incoming PENDING invitation (`expiresAt` already on the local clock), `resourceId` = invitation id | `DuelInvitationNotificationPayload { invitation, isGone }`, getter `isRoomUnavailable` |
| `NotificationKind.duelInvitation` | the host's own PENDING invitation, `isPrompt: false` (tracked for its outcome only) | same |

**Generic events used:** `NotificationAcceptRequested(itemId)`,
`NotificationDeclineRequested(itemId)`, `NotificationHidden(itemId)` (×,
local only), `NotificationHiddenShown` (pill: un-hide all),
`NotificationActivityRefreshRequested` (the overlay sends it on every route
change), `NotificationBattleOpened(battleId)`, `NotificationNoticeShown(id)`.

**Per-card action** (`NotificationAction.status`): `accepting`,
`declining`, `reconciling` (uncertain outcome; the resource and own
activity are being re-read; buttons disabled), `failed` (`failure` set;
still pending, retry allowed).

### Behaviour

- **Recovery** on start, sign-in, account switch (another user id without
  sign-out) and every reconnect: incoming requests (first page of 20),
  incoming invitations, own activity (the busy flag), and the host's own
  invitation (activity PRIVATE_DUEL → GET `/duels/{duelId}/invitations`; a
  known own invitation the room no longer lists → GET by id). Pushes that
  arrive meanwhile are buffered and applied right after the snapshot in one
  synchronous step; superseded recoveries and old sessions are dropped by
  tokens. These recoveries show every recovered friends prompt again
  (hidden ones are un-hidden). Sign-out clears everything.
- **Versions** per (kind, resource id); a terminal record leaves a
  tombstone keyed by the resource id, so a late PENDING never reopens it,
  while a new relationship id after re-adding shows again.
- **Busy** = own activity other than NONE (`state.isBusy`): Accept of an
  invitation is disabled with the busy text; Decline stays.
- **Friend request card:** Accept → on success the card shows "You and
  `{nickname}` are now friends." (`payload.isDone`, `isExpired`) and is
  removed 4 s later. Decline → removed, no toast. Resolved elsewhere →
  removed silently. NOT_PENDING / NOT_FOUND / uncertain → re-read
  (`reconciling`), then removed, Done, or `failed`.
- **Invitation card:**
  - EXPIRED (INVITATION_EXPIRED), the local deadline, or 410 on Accept →
    visible: expired state 4 s; hidden: removed + `expired` notice.
  - CANCELLED with DUEL_CANCELLED/DUEL_FILLED, EXPIRED with DUEL_EXPIRED,
    gone from a snapshot, or 404 after the activity check → visible: "This
    room is no longer available." state (`isRoomUnavailable`) for 4 s;
    hidden: removed + `cancelled` notice.
  - CANCELLED with SENDER_CANCELLED/FRIEND_REMOVED → removed + `cancelled`
    notice.
  - Accept: ACCEPTED + battleId → removed, `accepted` notice and
    `battleToOpen`. ACTIVITY_CONFLICT → `failed` + busy + activity re-read.
    CONTENT_UNAVAILABLE → `failed` (card shows the content warning).
    NOT_PENDING / NOT_FOUND / uncertain → re-read the invitation and own
    activity: ACCEPTED → open; still PENDING → `failed`; 404 + own BATTLE →
    open the activity battle (lost acceptance); 404 otherwise → room
    unavailable. ACCEPTED without battleId → own activity's battle.
  - Decline: success → removed, no toast. MATCH_ALREADY_FOUND / NOT_FOUND /
    uncertain → re-read, no error copy unless still pending.
- **Host's own invitation:** followed from pushes (where the user is the
  host), the room BLoC's send results and recovery. ACCEPTED → `accepted`
  notice (`isOutgoing`) and `battleToOpen`; DECLINED → `declined`; EXPIRED
  (or the local deadline) → `expired`; CANCELLED with DUEL_FILLED /
  FRIEND_REMOVED → `cancelled`. Own withdrawal (SENDER_CANCELLED) and own
  room cancellation (DUEL_CANCELLED) raise nothing. One notice per
  (invitation, status).
- **Own outgoing friend request accepted** → `accepted` notice
  (`friendRequest`, `isOutgoing`, the friend's nickname). No toast for a
  declined request.

### One navigator for a battle

`battleToOpen` appears at most once per battle id per session, shared by
rematches, the invitee's accept and the host's accepted invitation. The
overlay navigates on it. The private room keeps its own MATCHED navigation
(code joins) and sends `NotificationBattleOpened(battleId)` **before** it
navigates. That event now marks the id as opened (it never becomes
`battleToOpen` afterwards) and clears `battleToOpen` when it is the same
id. `RoomInvitationBloc` never navigates.

**Host paths when a push is lost or the overlay is not mounted:** the
overlay is only mounted inside the shell (not on the battle route or auth)
and drops a stale `battleToOpen` on remount. The host can only have a
waiting room inside the shell, so the overlay is mounted when the friend
accepts. If the ACCEPTED push is lost: (1) the room screen, when open,
still navigates on MATCHED (`PrivateDuelBloc` polls); (2) every activity
read (each route change, via `NotificationActivityRefreshRequested`) whose
activity is no longer that room re-reads the own invitation by id; (3) every
reconnect recovery does the same. Both route-change checks and reconnect
recovery open the activity's battle if the invitation returns 404 while
own activity is BATTLE. A newer activity read supersedes a pending check.

### Overlay copy (adapter `lib/app/notifications/friends_notifications.dart`)

Cards copy `FriendRequestCard` / `MatchInviteCard`; toasts use
`FriendsToastVariant` (`friendRequestAccepted`, `invitationAccepted`,
`invitationExpired`, `invitationCancelled`). Host toasts other than
accepted have no approved copy; the adapter uses "`{nickname}` declined
your match invitation.", "Your match invitation expired.", "Your match
invitation was cancelled." / "You are no longer friends with this player."
(FRIEND_REMOVED). The pill counts hidden pending cards of every kind
(`{n} pending requests`; all rematches keep the rematch wording).

## 2. `FriendsBloc` (Friends screen)

`presentation/bloc/friends_bloc/`. Provided in the Friends screen's
`wrappedRoute`: `FriendsBloc(...)..add(const FriendsStarted())`.

**Constructor:** `getFriendCode`, `getFriends`, `getFriendRequests`,
`sendFriendRequest`, `acceptFriendRequest`, `declineFriendRequest`,
`cancelFriendRequest`, `removeFriend`, `watchFriendshipChanges`,
`watchConnection`; optional `pageSize` (default 20).

### Events

| Event | Payload | Use |
|---|---|---|
| `FriendsStarted` | none | Loads code + page 0 of the three lists in parallel. |
| `FriendsRefreshRequested` | none | Pull-to-refresh / resume: the current page of every list (and the code if it failed). |
| `FriendsListRetryRequested` | `FriendsList list` | Retry one list's error view (its current page). |
| `FriendsPageRequested` | `FriendsList list, int page` (zero-based) | Previous / Next / a page number: loads that page and REPLACES the items. Ignored while that list loads; out-of-range pages are clamped to the known pages; a page found past the end loads the last page. |
| `FriendRequestSubmitted` | `SendFriendRequestParamsEntity(friendCode:)` | Add-friend form submit. The use case trims, removes hyphens, upper-cases and validates (12 chars of the code alphabet); a bad code returns `ValidationFailure` without a request. |
| `FriendRequestAcceptRequested` | `requestId` | Incoming row Accept. |
| `FriendRequestDeclineRequested` | `requestId` | Incoming row Decline. |
| `FriendRequestCancelRequested` | `requestId` | Outgoing row Cancel request. |
| `FriendRemoveRequested` | `friendId` (USER id) | After the destructive confirmation. |

`FriendsList`: `friends`, `incoming`, `outgoing`.

### State (`FriendsState`)

| Field | Meaning |
|---|---|
| `codeStatus`, `code`, `codeFailure` | Own friend code. |
| `friends` | `FriendsListSlice<FriendListItemEntity>` |
| `incoming`, `outgoing` | `FriendsListSlice<RelationshipEntity>` (PENDING only). |
| `sendStatus`, `sendFailure`, `sentRequest` | Add-friend submit; `sentRequest` is the created (201) or existing own pending (200) request. Both are success: show one "Request sent to `{recipient.nickname}`". |
| `requestActions` | `requestId → FriendsItemAction(status: LoadStatus, failure?)` for Accept/Decline/Cancel. `loading` disables the row; `success` stays until the refetched list drops the row. |
| `friendActions` | `friendId → FriendsItemAction` for Remove. |

`FriendsListSlice<T>`: `loadStatus` (first load and refreshes of the
current page), `items` (the current page only), `page` (`PageInfoEntity?`:
current zero-based `page`, `totalPages`, `totalElements`), `failure`,
`pageStatus` (`LoadStatus` of a page change; the current page stays visible
while the next loads), `pageFailure`, getters `hasPrevious`, `hasNext`,
`totalElements`. Skeleton = `items.isEmpty && loadStatus == loading` on the
first load (mock items via skeleton data); a refresh with items keeps them
visible. Empty success shows the empty state. A refresh started during a
page change supersedes it (`pageStatus` back to `initial`) and loads the
requested page. A refresh also clears a previous page-change error. Page
failures keep the current rows visible, show an inline error, and leave
Previous / Next available to retry.

Lists are refetched on every relevant FRIENDSHIP_CHANGED push, on own
command results and on reconnect, at their CURRENT page (latest-wins per
list); if that page is now past the end (the last row of the last page was
removed), the last existing page is loaded. Counts are never patched
locally.

## 3. `FriendProfileBloc` (friend profile screen)

`presentation/bloc/friend_profile_bloc/`. Provided in the profile screen's
`wrappedRoute`:
`FriendProfileBloc(...)..add(FriendProfileStarted(friendId: id, relationshipId: relId))`.
Pass `relationshipId` when the screen is opened from the Friends list.

**Constructor:** `getFriendProfile`, `removeFriend`,
`watchFriendshipChanges`, `watchConnection`.

| Event | Payload |
|---|---|
| `FriendProfileStarted` | `friendId` (USER id), `relationshipId?` |
| `FriendProfileRefreshRequested` | none |
| `FriendProfileRemoveRequested` | none (after confirmation) |

State: `friendId`, `relationshipId`, `loadStatus`, `profile`, `failure`,
`isNoLongerFriends`, `removeStatus`, `removeFailure`.

- `isNoLongerFriends == true` (404 `FRIEND_NOT_FOUND`, REMOVED push for the
  same `relationshipId`, or own removal): `profile` is null. Show "You are
  no longer friends with this player." and close/pop the profile (listen on
  `isNoLongerFriends`). Do not keep stale stats.
- Removals for the same user under a different relationship id never clear
  directly; the BLoC refetches and trusts the server.
- Removing returns 204 and emits nothing, so an open Friends screen below
  updates only through the push: when the profile closes as no longer
  friends, add `FriendsRefreshRequested` to the Friends BLoC if it is open.
- Do not render `MatchStatsEntity.questionCount` (approved decision).
- Reconnect refetches; a failed refetch keeps the shown profile.

## 4. `RoomInvitationBloc` (host, inside the private room)

`presentation/bloc/room_invitation_bloc/`. Provide it in the private room
screen next to `PrivateDuelBloc` once the room id is known, and add
`RoomInvitationStarted(duelId)`. Show "Invite friend" only to the host while
the room is WAITING (from `PrivateDuelBloc`).

**Constructor:** `getRoomInvitations`, `getDuelInvitation`,
`sendDuelInvitation`, `withdrawDuelInvitation`, `getFriends`,
`watchDuelInvitationChanges`, `watchConnection`, `generateId`; optional
`pageSize` (default 20).

The room UI passes `pageSize: 5` for the picker, as drawn in Paper. The
Friends screen and its request lists keep page size 20.

Request id policy: a Send creates an intent (duelId, friendId, requestId).
It is kept after `ConnectionFailure`, `TimeoutFailure`, 5xx, parsing
failures and 429, so a Send to the same friend reuses the id
(`canRetrySend == true`). Any definite answer (success or 4xx) ends the
intent, and so does a push or restore showing an invitation to that friend
in this room (the uncertain send went through). The next Send, or one to
another friend, then gets a new id.

A matching push or restore resolves the intent even while Send's HTTP
request is pending. The late HTTP answer of that resolved intent is ignored;
it cannot restore a retry with the old request id.
Resolved results can be dismissed without forgetting their versions. A
replayed older invitation cannot become pending again or resolve a later
Send; newer invitations are ordered by creation time across resource ids.
After a terminal push, a new Send may start before the old HTTP call ends.

| Event | Payload | Use |
|---|---|---|
| `RoomInvitationStarted` | `duelId` | Restores the pending/latest invitation and follows pushes for this room. |
| `RoomInvitationRefreshRequested` | none | Resume / retry restore. |
| `RoomInvitationFriendsRequested` | none | Open picker: page 0 of accepted friends. |
| `RoomInvitationFriendsPageRequested` | `int page` (zero-based) | Picker page navigation: replaces `friends`. Ignored while the picker loads; clamped; past the end → last page. |
| `RoomInvitationSendRequested` | `friendId` | Send. Same friend after an uncertain failure = retry with the same request id. |
| `RoomInvitationWithdrawRequested` | none | "Cancel invitation". |
| `RoomInvitationResultCleared` | none | Dismiss a terminal result to pick someone else. |

State: `duelId`, `restoreStatus`, `restoreFailure`, `invitation`
(latest of the room, any status), `clockOffset`, `friendsStatus`, `friends`,
`friendsPage` (`PageInfoEntity?`), `friendsFailure`, `friendsPageStatus`
(`LoadStatus` of a picker page change), `friendsPageFailure`,
`sendStatus`, `sendFailure`, `sendFriendId`, `canRetrySend`,
`withdrawStatus`, `withdrawFailure`. Getters: `pendingInvitation`,
`canInvite`, `hasPreviousFriends`, `hasNextFriends`.

Rendering by `invitation?.status`:

- `pending`: "Waiting for `{recipient.nickname}`…", countdown, "Cancel
  invitation" (disabled while `withdrawStatus.isLoading`). Picker disabled.
- `accepted`: nothing to do here. The toast and the navigation come from
  `NotificationBloc` (see "One navigator"); the room's own MATCHED
  navigation sends `NotificationBattleOpened(battleId)` first.
- `declined`: neutral declined state; picker available again.
- `cancelled` / `expired`: reason text ("This invitation expired.", "This
  room is no longer available.", "You are no longer friends with this
  player."); picker available again. The room itself stays open.
- `sendFailure` with `canRetrySend` → show Retry (re-adds
  `RoomInvitationSendRequested(sendFriendId)`).

## Error codes the UI must render

All failures are the shared `Failure`; read `failure.code` (or
`failure.hasCode(ApiErrorCodes.x)`), `ApiFailure.retryAfter` for 429, and
fall back to `failure.userMessage`.

| Where | Code / failure | Meaning, suggested copy |
|---|---|---|
| Send request | `ValidationFailure` | "Enter the 12-character friend code." (no request sent) |
| Send request | `FRIEND_CODE_NOT_FOUND` (404) | "No player has this friend code." |
| Send request | `SELF_FRIEND_REQUEST_NOT_ALLOWED` (409) | "That's your own friend code." |
| Send request | `FRIEND_ALREADY_EXISTS` (409) | "You're already friends." (friends list refetched) |
| Send request | `FRIEND_REQUEST_ALREADY_RECEIVED` (409) | "This player already sent you a request. Accept it below." (incoming list refetched; never auto-accept) |
| Send request / invite | `RATE_LIMITED` (429) | "Too many attempts. Try again in `{retryAfter}`." (`ApiFailure.retryAfter`, may be null) |
| Accept/Decline/Cancel request | `FRIEND_REQUEST_NOT_PENDING` (409) | Already handled; list refetched. Cancel on an accepted request: use Remove friend. |
| Accept/Decline/Cancel request | `FRIEND_REQUEST_NOT_FOUND` (404) | Request no longer exists; list refetched. |
| Any | `FORBIDDEN` (403) | Wrong role (e.g. accepting own request); should not happen with `canRespond`/`canCancel`. |
| Profile | `FRIEND_NOT_FOUND` (404) | Becomes `isNoLongerFriends`, not an error view. |
| Invitation accept | `ACTIVITY_CONFLICT` (409) | "Finish or leave your current activity before accepting." (activity re-read) |
| Invitation accept | `CONTENT_UNAVAILABLE` (409) | Not enough questions; invitation stays pending. |
| Invitation accept | `DUEL_INVITATION_EXPIRED` (410), `DUEL_INVITATION_NOT_PENDING` (409), `DUEL_INVITATION_NOT_FOUND` (404) | Resolved by the BLoC: the item leaves and an `invitationClosed` notice says why. |
| Invitation decline | `MATCH_ALREADY_FOUND` (409) | Resolved by re-reading the invitation. |
| Invite (host) | `FRIEND_NOT_FOUND` (404) | "You are no longer friends with this player." |
| Invite (host) | `DUEL_NOT_FOUND` (404), `DUEL_NOT_JOINABLE` (409), `DUEL_EXPIRED` (410) | "This room is no longer available." |
| Invite (host) | `DUEL_INVITATION_ALREADY_PENDING` (409) | Another invitation is pending; the BLoC restores it. |
| Invite (host) | `IDEMPOTENCY_CONFLICT` (409) | Request id reused for another target; the next Send gets a new id. Generic message. |
| Withdraw (host) | `MATCH_ALREADY_FOUND` (409) | The friend already joined; the BLoC re-reads the invitation, the room moves to MATCHED. |
| Restore (host) | `DUEL_NOT_FOUND` (404) | Room lost (server restart). |
| Any | `ConnectionFailure`, `TimeoutFailure`, 5xx | Generic `userMessage`. Accepts are never assumed: the BLoC re-reads first. |
