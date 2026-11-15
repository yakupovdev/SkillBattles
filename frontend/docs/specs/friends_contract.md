# Friends and room invitations — frontend + API contract

Status: proposed implementation contract (backend not yet available).
Baseline: develop 894079fa902b3d3fb5a6d3c2f2f475ebdc510d66 (2026-11-15).
Source: FRIENDS_FRONTEND.md + FRIENDS_OPENAPI.yaml (feature-only). This file is the
condensed, complete copy for the frontend: every endpoint, status, schema, error code,
realtime event and default from the OpenAPI is listed below.

---

## Part 1 — Frontend contract (FRIENDS_FRONTEND.md, verbatim)

### Confirmed UX flow

Friendship requires confirmation. A user shares their personal friend code; another user enters it and sends a request; the recipient receives an in-app notification and accepts/declines. Both then see each other in Friends. Either can remove the friendship.

For a match, the host first creates the EXISTING private room. INSIDE that room provide `Invite friend`, select an accepted friend and send the targeted invitation. The friend receives an actionable notification anywhere in the signed-in app. Accept joins that SAME room, assigns its single guest and opens the existing battle Ready screen. Do not create another room on behalf of the recipient.

All text is English, design uses the existing frontend system. This feature does not prescribe a redesign, chat, OS push or online-status directory.

### Friends area

Provide:
- own friend code with Copy; display grouped ABCD-2345-EFGH if desired;
- Add friend form by code;
- paged Friends list with nickname and optional existing Pro badge;
- paged incoming/outgoing pending friend requests with appropriate controls;
- friend profile entry;
- Remove friend action with normal destructive-action confirmation.

Friend code is 12 characters, different from the six-character room code. Server accepts optional hyphens and outer whitespace; canonical returned code has none. It excludes ambiguous I/L/O/0/1. Do not derive codes locally or show a friend's private code. Use a normal text widget for nicknames, not unescaped rich-text markup.

A notification is actionable in app, not dependent on the user staying on a result/Friends/room screen. A dismiss button only hides UI and does not decline/cancel server state. Pending requests/invitations remain accessible from the global panel/list until handled or expired.

### Core REST calls

All paths below are under /api/v1; access Bearer JWT required. IDs are UUIDs unless stated otherwise.

| Intent | Method/path | Body | Success |
|---|---|---|---|
| My friend code | GET /users/me/friend-code | none | 200 `{friendCode}` |
| Accepted friends | GET /friends?page=0&size=20 | none | 200 `{data,pagination}` |
| Friend profile/basic stats | GET /friends/{friendId} | none | 200 FriendProfileResponse |
| Remove friend | DELETE /friends/{friendId} | none | 204, no body |
| Send request | POST /friend-requests | `{friendCode}` | 201 new or 200 existing own pending RelationshipResponse |
| Pending requests | GET /friend-requests?direction=INCOMING&page=0&size=20 | none | 200 `{data,pagination}` |
| Restore known request | GET /friend-requests/{id} | none | 200 RelationshipResponse |
| Accept request | POST /friend-requests/{id}/accept | none | 200 RelationshipResponse |
| Decline request | POST /friend-requests/{id}/decline | none | 200 RelationshipResponse |
| Cancel own request | DELETE /friend-requests/{id} | none | 204 |
| Invite friend into my room | POST /duels/{duelId}/invitations | `{friendId,requestId}` | 201 new or 200 existing invitation |
| Restore pending invite in my room | GET /duels/{duelId}/invitations | none | 200 `{data,serverTime}` |
| Incoming room invites | GET /users/me/duel-invitations | none | 200 `{data,serverTime}` |
| Restore known invite | GET /duel-invitations/{id} | none | 200 DuelInvitationResponse |
| Accept room invite | POST /duel-invitations/{id}/accept | none | 200 DuelInvitationResponse with battleId |
| Decline room invite | POST /duel-invitations/{id}/decline | none | 200 authoritative invitation |
| Withdraw own room invite | DELETE /duel-invitations/{id} | none | 204 |

friendId is the other USER id. A relationship/request id identifies a request record. duelId identifies a room; battleId is a different id created when a guest joins. Never interchange them.

Friends and request lists use existing zero-based PaginationDto `{page,size,totalElements,totalPages}`. size is 1..100. Requests default INCOMING, allow OUTGOING, and return only PENDING. Friends order friendsSince DESC/relationshipId ASC; requests createdAt DESC/id ASC. Do not invent sort/status queries. An empty list or a page beyond the end is normal.

### Friendship model and actions

RelationshipResponse:
`{id,requester:{id,isPro,nickname},recipient:{id,isPro,nickname},status,createdAt,updatedAt,acceptedAt,version}`.
Statuses: PENDING, ACCEPTED, DECLINED, CANCELLED, REMOVED. acceptedAt is null until acceptance. REMOVED is a past friendship, not a current friend.

- PENDING where current user is recipient: Accept / Decline.
- PENDING where current user is requester: Cancel request, never Accept own request.
- ACCEPTED: refresh Friends; allow friend profile and room invitations.
- DECLINED/CANCELLED: remove from pending UI; do not claim friendship.
- REMOVED: invalidate the affected relationship entry/profile and refresh authoritative friendship/invitation state. Close a profile when it is no longer authorized and clear stale data. Do not blindly remove a newer relationship/invite for the same user based on an old event. Do not surrender an already running battle.

If A and B both send codes while one request is pending, server may return FRIEND_REQUEST_ALREADY_RECEIVED. Refresh incoming requests and let the user explicitly Accept; do not automatically accept it. Successful duplicate POST/accept does not require duplicate toast/navigation. A later new request has a new id; do not suppress it with a tombstone keyed only by friend user id.

### Friend profile and statistics

FriendProfileResponse is `{friend,friendsSince,disciplines}`. Render basic per-discipline rating/rank, calibration/peaks/season state, and ranked/private match counters as provided. Use existing rank/catalog display data and nullable no-data behavior.

The field set NEVER expands for Pro, regardless of viewer or friend's plan. There is no friend topic analytics, weak-topic list, rating chart, answer review or match-history access. Do not display a Pro upsell implying these can be unlocked. The existing isPro badge is only a public badge.

Do not call another user's own `/users/me` or `/users/me/statistics` by injecting userId. Do not request/store/render email, birth data, friendCode, account entitlements, payment information or account streak calendar for friends. The new friend endpoint is already server-redacted; hiding fields only in UI is insufficient.

Match counts use all settled applicable matches (not last-ten Free history). played=0 -> winRatePercent null; no question/time samples -> accuracyPercent/avgAnswerTimeMs null. Show an empty-state dash/message rather than manufactured zero values. Removing friendship makes the profile endpoint 404 immediately at its next authorization check.

### Invitation from the room

Use existing POST /duels `{disciplineCode}` to create the room. The host's own activity is already PRIVATE_DUEL. Show `Invite friend` only to that host while the room is WAITING. No new room is created when Send is clicked.

Select from accepted Friends. Do not require public online status: an offline friend can recover the invitation while it remains valid. A busy recipient is not automatically removed from another queue/room/battle. If own known activity is busy, recipient UI disables Accept with explanation; backend remains authoritative and Decline is still available.

Generate one requestId UUID per Send intent and retain it for network retries. Use the same requestId/duelId/friendId together. A new target/new send after resolution gets a new requestId. Do not regenerate it on a retry or use it as a room id. There is at most ONE pending targeted invitation per room; Cancel/resolve it before selecting someone else.

DuelInvitationResponse:
`{id,duelId,host,recipient,disciplineCode,format,status,reason,createdAt,expiresAt,battleId,version}`.
Public players have id/isPro/nickname. No room code is delivered by this DTO. Before acceptance the invitee cannot use GET /duels/{duelId}; that endpoint remains host/assigned-guest only. Use invitation fields for the notification preview instead.

English copy examples:
- `Match invitation` / `{hostNickname} invited you to a private {disciplineName} match.`
- `Accept` / `Decline` / `Cancel invitation`.
- `Waiting for {nickname}…`.
- `Finish or leave your current activity before accepting.`
- `This invitation expired.`
- `This room is no longer available.`
- `You are no longer friends with this player.`

Deadline is min(sent time+60s, original room deadline). Use expiresAt and serverTime, not a new timer at receipt. Invite expiry/decline/withdrawal does not cancel the host's room. User may invite a different friend afterwards; cooldown/rate errors are authoritative.

Statuses:
- PENDING: recipient Accept/Decline; host Cancel.
- ACCEPTED: navigate to returned battleId through existing battle recovery/Ready flow ONCE; both must still press Ready.
- DECLINED: remove notification; show neutral declined state to host.
- CANCELLED: close; optional reason-specific text, no auto-rejoin.
- EXPIRED: disable actions, close or show expired state.

Cancellation reasons: SENDER_CANCELLED, DUEL_CANCELLED, DUEL_FILLED, FRIEND_REMOVED; expiry reasons: INVITATION_EXPIRED, DUEL_EXPIRED. Do not infer a matched battle for a rejected invitation: if someone else joined the room, this invite is CANCELLED/DUEL_FILLED with battleId null. If the invited friend joined through the existing room code, their invitation becomes ACCEPTED for that SAME battle.

### Realtime and global coordinator

Reuse the current app-wide native STOMP client/connection and `/user/queue/events`. JWT remains in STOMP CONNECT Authorization. Commands remain REST. Extend the existing RealtimeEventType decoder with:
- FRIENDSHIP_CHANGED: resourceId = relation/request id, data = RelationshipResponse.
- DUEL_INVITATION_CHANGED: resourceId = invitation id, data = DuelInvitationResponse.

Envelope remains `{eventId,type,resourceId,version,occurredAt,data}`; version equals data.version. The same stream still includes REMATCH_CHANGED, PRIVATE_DUEL_CHANGED, BATTLE_CHANGED, QUEUE_CHANGED, ACCOUNT_CHANGED and SEASON_CHANGED. Unknown types should remain safely ignored. Do not create another socket or global topic.

FRIENDSHIP_CHANGED PENDING shows an incoming notification only when current user is recipient; requester gets its outgoing state. ACCEPTED/REMOVED invalidate Friends, pending requests and visible friend profile. Do not show a request-to-yourself toast.

DUEL_INVITATION_CHANGED PENDING shows an incoming match notification only to the recipient; host sees waiting/cancel state in their room. ACCEPTED may arrive with PRIVATE_DUEL_CHANGED and BATTLE_CHANGED: deduplicate navigation by battleId, and update the source invitation/room separately by their own id/version. A room invitation and a rematch are distinct resources; use separate decoders/actions even when rendered in one global notifications panel.

Use the existing repository/usecase/BLoC conventions. Mount global handling at authenticated application scope, not within Friends/room/result screens. Share logical state to avoid duplicate prompts between global panel and an already-open relevant screen.

### Recovery and races

After authenticated startup and every reconnect: attach listeners, SUBSCRIBE, then REST-recover pending incoming/outgoing friend requests, Friends, incoming room invites, existing incoming rematches and own activity. If a known room is still owned/waiting, recover its snapshot and outgoing invite. Fetch visible profile again if still authorized.

GET pending lists cannot explain all missing items. On uncertain accept outcome, restore the known request/invitation and own activity rather than assuming decline or resending a fresh intent. Existing activity BATTLE carries the created battle id. Lost ACCEPTED after a backend restart still recovers the battle from activity; the in-memory invite GET may now be 404.

Buffer events while recovery is in flight, compare versions per (type,resourceId), and use recovery/session generation tokens to reject stale responses. Terminal tombstones prevent late lower-version PENDING from reopening the same resource. A new relationship id after re-adding is a new resource. A late REMOVED for an OLD relationship id must not delete the newly accepted relationship for the same friend user id: match relationshipId or refetch the authoritative Friends list/profile instead of applying a user-id-only removal. Account logout/switch cancels old listeners/work and clears private cached lists/profiles. Reconnect should rebuild a fresh room-invite baseline; persistent friendship state is restored from DB.

On tab resume/visibility regain refetch relevant lists/activity. Coalesce invalidations; optional visible-page reconciliation every 15 seconds can recover lost best-effort events. Do not poll every second for countdown. Page counts are snapshots; an event can invalidate totals/order, so refetch rather than manually guessing count deltas.

Ambiguous network failures never imply successful accept/remove. Disable duplicate local clicks while reconciling, keep invitation Send requestId stable, and discard old-account responses.

### Errors and checks

Use ErrorResponse and codes in OpenAPI. 401 uses existing refresh/auth flow; 403 indicates wrong role; 404 means unavailable/unauthorized resource; friend-profile 404 clears stale profile. 409 ACTIVITY_CONFLICT does not exit current activity. 409 MATCH_ALREADY_FOUND during invitation cancellation requires invitation/activity recovery. 410 closes an expired invite. 429 respects Retry-After; do not throttle Accept/Decline locally using the Send limiter. 204 has no JSON body.

Verify two real users plus a third-party account: code sharing, incoming request notification off-screen, accept/decline/cancel, crossed requests, restart durability, both-way removal, all Free/Pro profile combinations, room-created-before-invite, busy/offline target, normal code join races, room cancel/expiry, invite-only expiry, acceptance->Ready, duplicate/lost/reordered events and late HTTP, reconnect/tab resume/logout. No third party may read requests/invites/profile.

Run model/widget tests, flutter analyze, existing tests, Web release build and real same-origin REST/STOMP browser smoke with DEV_MOCKS=false. Do not restore practice/similar-question UI or change existing image/Markdown rendering.

---

## Part 2 — API details (condensed from FRIENDS_OPENAPI.yaml)

Every response (success and error) carries `Cache-Control: no-store`. Every endpoint can also
return 400 VALIDATION_ERROR, 401 UNAUTHORIZED, 500 INTERNAL_ERROR (shared `ErrorResponse`).
All new endpoints require the access JWT.

### New operations (17)

| operationId | Method + path | Request | Success | Extra error codes |
|---|---|---|---|---|
| getUsersMeFriendCode | GET /users/me/friend-code | — | 200 FriendCodeResponse | — |
| getFriends | GET /friends?page&size | page ≥0 (default 0), size 1..100 (default 20) | 200 FriendsPage | — |
| getFriendProfile | GET /friends/{friendId} | friendId = other USER uuid | 200 FriendProfileResponse | 404 FRIEND_NOT_FOUND |
| removeFriend | DELETE /friends/{friendId} | — | 204 (also idempotent no-op) | — |
| sendFriendRequest | POST /friend-requests | SendFriendRequest | 201 new / 200 existing own pending — RelationshipResponse | 404 FRIEND_CODE_NOT_FOUND; 409 SELF_FRIEND_REQUEST_NOT_ALLOWED, FRIEND_ALREADY_EXISTS, FRIEND_REQUEST_ALREADY_RECEIVED; 429 RATE_LIMITED (+ `Retry-After` seconds) |
| getFriendRequests | GET /friend-requests?direction&page&size | direction INCOMING (default) / OUTGOING | 200 FriendRequestsPage (PENDING only) | — |
| getFriendRequest | GET /friend-requests/{id} | id = relationship uuid | 200 RelationshipResponse (any status, either participant) | 404 FRIEND_REQUEST_NOT_FOUND |
| cancelFriendRequest | DELETE /friend-requests/{id} | requester only | 204 (repeated non-accepted terminal = 204) | 403 FORBIDDEN; 404 FRIEND_REQUEST_NOT_FOUND; 409 FRIEND_REQUEST_NOT_PENDING (ACCEPTED → use DELETE /friends/{friendId}) |
| acceptFriendRequest | POST /friend-requests/{id}/accept | recipient only, no body | 200 RelationshipResponse (repeated ACCEPTED = same state) | 403 FORBIDDEN; 404 FRIEND_REQUEST_NOT_FOUND; 409 FRIEND_REQUEST_NOT_PENDING |
| declineFriendRequest | POST /friend-requests/{id}/decline | recipient only, no body | 200 RelationshipResponse (repeated DECLINED idempotent) | 403 FORBIDDEN; 404 FRIEND_REQUEST_NOT_FOUND; 409 FRIEND_REQUEST_NOT_PENDING |
| inviteFriendToDuel | POST /duels/{duelId}/invitations | SendDuelInvitationRequest | 201 new / 200 existing (same requestId replay returns current state, even terminal) — DuelInvitationResponse | 404 DUEL_NOT_FOUND, FRIEND_NOT_FOUND; 409 DUEL_NOT_JOINABLE, DUEL_INVITATION_ALREADY_PENDING, IDEMPOTENCY_CONFLICT; 410 DUEL_EXPIRED; 429 RATE_LIMITED (+ `Retry-After`) |
| getDuelOutgoingInvitations | GET /duels/{duelId}/invitations | host only | 200 DuelInvitationsSnapshot (≤1 pending; terminal room may be empty) | 404 DUEL_NOT_FOUND (room lost after restart) |
| getUsersMeDuelInvitations | GET /users/me/duel-invitations | — | 200 DuelInvitationsSnapshot (incoming PENDING, ordered expiresAt,id) | — |
| getDuelInvitation | GET /duel-invitations/{id} | host or recipient | 200 DuelInvitationResponse (incl. terminal) | 404 DUEL_INVITATION_NOT_FOUND |
| withdrawDuelInvitation | DELETE /duel-invitations/{id} | host only | 204 (non-accepted terminal = 204 no-op; does not cancel room) | 403 FORBIDDEN; 404 DUEL_INVITATION_NOT_FOUND; 409 MATCH_ALREADY_FOUND |
| acceptDuelInvitation | POST /duel-invitations/{id}/accept | recipient only | 200 DuelInvitationResponse (ACCEPTED + battleId; repeated = same) | 403 FORBIDDEN; 404 DUEL_INVITATION_NOT_FOUND; 409 DUEL_INVITATION_NOT_PENDING, ACTIVITY_CONFLICT, CONTENT_UNAVAILABLE; 410 DUEL_INVITATION_EXPIRED |
| declineDuelInvitation | POST /duel-invitations/{id}/decline | recipient only | 200 DuelInvitationResponse (non-accepted terminal returns unchanged state) | 403 FORBIDDEN; 404 DUEL_INVITATION_NOT_FOUND; 409 MATCH_ALREADY_FOUND |

Accept-invitation notes: busy/content error leaves the invitation PENDING; a terminal state
discovered during validation is committed before the error response.

### Existing operations referenced (unchanged contracts)

| Method + path | Notes for this feature |
|---|---|
| POST /duels `{disciplineCode}` | 201 DuelResponse (WAITING). 409 ACTIVITY_CONFLICT, CONTENT_UNAVAILABLE. Host creates this BEFORE inviting. |
| POST /duels/join `{code}` | 200 DuelResponse. Internally: invited guest → invitation ACCEPTED; other guest → invitation CANCELLED/DUEL_FILLED. 404 DUEL_NOT_FOUND; 409 SELF_JOIN_NOT_ALLOWED, DUEL_NOT_JOINABLE, ACTIVITY_CONFLICT, CONTENT_UNAVAILABLE; 410 DUEL_EXPIRED. |
| GET /duels/{id} | Host or assigned guest only; an invitee is NOT a guest before acceptance. 404 DUEL_NOT_FOUND. |
| DELETE /duels/{id} | Host only. New side effect: its PENDING invitation → CANCELLED/DUEL_CANCELLED. 404 DUEL_NOT_FOUND; 409 MATCH_ALREADY_FOUND. |
| GET /users/me/activity | `{type: NONE/QUEUE/PRIVATE_DUEL/BATTLE, resourceId, resourceKind: DUEL/REMATCH/null, battleId}`. Incoming invitations do not reserve activity. |

### Schemas

```
PublicPlayer        { id: uuid, isPro: bool, nickname: string }      (existing; never email)
PaginationDto       { page: int ≥0, size: int 1..100, totalElements: int64 ≥0, totalPages: int ≥0 }  (existing)
ErrorResponse       { code: string, message: string, fieldErrors: [{field, message}], resetsAt: date-time? }
                    (existing; RATE_LIMITED uses Retry-After header, resetsAt is null for the social limiter)

FriendCodeResponse  { friendCode: string }   12 chars, ^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{12}$
SendFriendRequest   { friendCode: string }   1..32 chars. Server trims outer whitespace, removes ASCII
                    hyphens, uppercases; canonical must be 12 chars of the alphabet above; internal
                    whitespace invalid. Example input "ABCD-2345-EFGH".

RelationshipResponse {
  id: uuid                      request/relationship id (≠ friend user id)
  requester: PublicPlayer
  recipient: PublicPlayer
  status: PENDING | ACCEPTED | DECLINED | CANCELLED | REMOVED
  createdAt: date-time
  updatedAt: date-time
  acceptedAt: date-time?        null until accepted
  version: int ≥1
}
FriendListItem      { relationshipId: uuid, friend: PublicPlayer, friendsSince: date-time, version: int ≥1 }
FriendsPage         { data: [FriendListItem], pagination: PaginationDto }
FriendRequestsPage  { data: [RelationshipResponse], pagination: PaginationDto }

FriendProfileResponse { friend: PublicPlayer, friendsSince: date-time, disciplines: [FriendDisciplineStatistics] }
FriendDisciplineStatistics {
  disciplineCode: string
  rating: int
  rank: RankProgress
  calibration: Calibration
  allTimePeakRating: int
  allTimePeakRankCode: string
  seasonId: string
  seasonPeakRating: int
  seasonPeakRankCode: string
  seasonRolloverPending: bool
  ranked: MatchCountsResponse
  privateMatches: MatchCountsResponse
}
RankProgress        { rankCode, rankName, leagueCode: string, divisionRpCurrent: int, divisionRpTarget: int?,
                      floorRating: int, ceilingExclusive: int? }        (same shape as existing account stats)
Calibration         { completedMatches: int, matchesRemaining: int, isCalibrating: bool, nextKFactor: int }
MatchCountsResponse { wins, losses, draws, played: int, winRatePercent: double?, currentWinStreak: int,
                      bestWinStreak: int, accuracyPercent: double?, avgAnswerTimeMs: int64?, questionCount: int }
                    played=0 → winRatePercent null; no samples → accuracyPercent / avgAnswerTimeMs null.

SendDuelInvitationRequest { friendId: uuid (accepted friend's USER id), requestId: uuid (one per Send intent,
                            kept across retries; changed duel/target under same requestId → IDEMPOTENCY_CONFLICT) }
DuelInvitationResponse {
  id: uuid                      invitation id (≠ duelId, ≠ requestId)
  duelId: uuid                  existing room id (≠ battleId)
  host: PublicPlayer
  recipient: PublicPlayer
  disciplineCode: string
  format: STANDARD
  status: PENDING | ACCEPTED | DECLINED | CANCELLED | EXPIRED
  reason: null | SENDER_CANCELLED | DUEL_CANCELLED | DUEL_FILLED | FRIEND_REMOVED | INVITATION_EXPIRED | DUEL_EXPIRED
  createdAt: date-time
  expiresAt: date-time          min(createdAt+60s, room expiry); never renewed
  battleId: uuid?               only for ACCEPTED; null when room was filled by someone else
  version: int ≥1
}                               No room code. Only host/recipient can read.
DuelInvitationsSnapshot { data: [DuelInvitationResponse], serverTime: date-time }   complete, no pagination

DuelResponse (existing, unchanged) { id, code, disciplineCode, format, status: WAITING|MATCHED|CANCELLED|EXPIRED,
                                     host: PublicPlayer, guest: PublicPlayer?, expiresAt, battleId?, version }
ActivityResponse (existing)        { type, resourceId?, resourceKind?, battleId? }
```

### Realtime (existing STOMP connection)

- Endpoint `/ws/v1/events`, STOMP 1.2 over native WebSocket, CONNECT header `Authorization: Bearer <access JWT>`,
  subscription `/user/queue/events`, no client SEND.
- Delivery: after commit, to both authorized participants' current sessions; best-effort — may be lost,
  duplicated or reordered. REST recovery required.
- Envelope `{ eventId: uuid, type, resourceId, version: int ≥1, occurredAt: date-time, data }`.
- New types:
  - `FRIENDSHIP_CHANGED` — resourceId = relationship id, version = relationship version, data = RelationshipResponse.
  - `DUEL_INVITATION_CHANGED` — resourceId = invitation id, version = invitation version, data = DuelInvitationResponse.
- Preserved: REMATCH_CHANGED, PRIVATE_DUEL_CHANGED, BATTLE_CHANGED, QUEUE_CHANGED, ACCOUNT_CHANGED, SEASON_CHANGED.
- Recovery order: attach listener and subscribe first, then REST-recover pending requests / Friends / incoming
  room and rematch invites / activity. Host restores own room and its pending invite. A known accepted invite
  or own BATTLE activity resolves lost acceptance; pending-list absence is not proof of acceptance.

### Persistence and defaults

- Postgres (survive backend restart): friend codes, relationships, pending friend requests, accepted battles.
- Memory (lost on backend restart): private rooms, room invitations, invitation idempotency receipts.
- Defaults: friendCodeLength 12; friendRequestExpiry none; roomInvitationTtlSeconds 60;
  maxPendingInvitationsPerRoom 1; friendRequestAttemptsPer20Minutes 20; newRoomInvitationsPer20Minutes 30;
  terminalPairCooldownSeconds 60.

### New error codes (add to the shared error-code list)

FRIEND_NOT_FOUND, FRIEND_CODE_NOT_FOUND, SELF_FRIEND_REQUEST_NOT_ALLOWED, FRIEND_ALREADY_EXISTS,
FRIEND_REQUEST_ALREADY_RECEIVED, FRIEND_REQUEST_NOT_FOUND, FRIEND_REQUEST_NOT_PENDING,
DUEL_INVITATION_ALREADY_PENDING, IDEMPOTENCY_CONFLICT, DUEL_INVITATION_NOT_FOUND,
DUEL_INVITATION_NOT_PENDING, DUEL_INVITATION_EXPIRED. (Already existing and reused: VALIDATION_ERROR,
UNAUTHORIZED, FORBIDDEN, INTERNAL_ERROR, RATE_LIMITED, DUEL_NOT_FOUND, DUEL_NOT_JOINABLE, DUEL_EXPIRED,
ACTIVITY_CONFLICT, CONTENT_UNAVAILABLE, MATCH_ALREADY_FOUND, SELF_JOIN_NOT_ALLOWED — verify against
`lib/core/utils/error/api_error_codes.dart`.)
