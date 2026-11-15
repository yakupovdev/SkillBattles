# Friends and existing-room invitations — backend handoff

The actual complete OpenAPI is `backend/target/generated-openapi.json`, generated
by Maven `verify`. Application API version stays **0.3.0**. This increment adds
**17** product operations. Combined with the existing sticker command, the current
contract has 58 product REST operations plus 2 illustration media GET/HEAD operations,
60 total. The supplied feature-only YAML includes 5 existing
context operations and does not replace the complete application contract.
Frontend implementation and browser UI testing belong to the frontend task.

All paths below are under `/api/v1`, require an access Bearer JWT and return
`Cache-Control: no-store`. Refresh tokens cannot authorize them. Existing
ErrorResponse `{code,message,fieldErrors,resetsAt}` and security responses apply.

| New operation | Body / success |
| --- | --- |
| GET /users/me/friend-code | 200 `{friendCode}` |
| GET /friends?page=0&size=20 | 200 `{data,pagination}` |
| GET /friends/{friendId} | 200 basic FriendProfileResponse |
| DELETE /friends/{friendId} | 204, idempotent |
| POST /friend-requests | `{friendCode}`; 201 new / 200 existing own pending |
| GET /friend-requests?direction=INCOMING&page=0&size=20 | 200 pending page; OUTGOING also supported |
| GET /friend-requests/{id} | 200 any retained participant-owned status |
| POST /friend-requests/{id}/accept | No body; recipient only, 200 |
| POST /friend-requests/{id}/decline | No body; recipient only, 200 |
| DELETE /friend-requests/{id} | Requester only, 204 |
| POST /duels/{duelId}/invitations | `{friendId,requestId}`; 201 new / 200 idempotent |
| GET /duels/{duelId}/invitations | Host-only pending `{data,serverTime}` |
| GET /users/me/duel-invitations | Complete incoming pending `{data,serverTime}` |
| GET /duel-invitations/{id} | Current host/recipient-owned invitation, 200 |
| POST /duel-invitations/{id}/accept | No body; recipient only, 200 |
| POST /duel-invitations/{id}/decline | No body; recipient only, 200 |
| DELETE /duel-invitations/{id} | Host only, 204 |

friendId is the OTHER USER UUID; relationship/request ids, room ids, invitation
ids, client requestId and battle ids are distinct. page is zero-based, size 1–100,
default 20. Friends order by friendsSince DESC/relationshipId ASC; requests by
createdAt DESC/id ASC. Incoming room invites order by expiresAt/id. No public
user/code search, status/sort filter, online directory or arbitrary userId query
was added. Unknown/unrelated resources are hidden as 404; wrong-role 403 applies
only after participant ownership is established.

## Codes, friendship and profile

Own code example: `{"friendCode":"ABCD2345EFGH"}`. It is SecureRandom, 12 symbols
from `ABCDEFGHJKMNPQRSTUVWXYZ23456789`, stable across login/restart. Accept outer
ASCII whitespace/hyphens/lowercase input up to 32 characters; never reconstruct a
code from a UUID/nickname. Existing accounts allocate lazily on their own GET;
new registrations allocate transactionally. Deleted-account codes remain reserved.

Example send: `POST /friend-requests {"friendCode":"ABCD-2345-EFGH"}`.
RelationshipResponse fields are exactly:

```text
id, requester:{id,isPro,nickname}, recipient:{id,isPro,nickname}, status,
createdAt, updatedAt, acceptedAt:null|UTC instant, version
```

Statuses: PENDING, ACCEPTED, DECLINED, CANCELLED, REMOVED. Recipient confirmation
is explicit; opposite PENDING returns FRIEND_REQUEST_ALREADY_RECEIVED. Self is
SELF_FRIEND_REQUEST_NOT_ALLOWED; unknown code FRIEND_CODE_NOT_FOUND; accepted
pair FRIEND_ALREADY_EXISTS. Unchanged retries retain timestamps/version and emit
no event. A new request after a terminal state gets a new UUID/version 1 after
the 60-second pair cooldown; an old resource cannot resurrect a newer friendship.

Friend list items are `{relationshipId,friend,friendsSince,version}`. Profile is
exactly `{friend,friendsSince,disciplines}`. Every discipline contains only:

```text
disciplineCode, rating, rank, calibration, allTimePeakRating, allTimePeakRankCode,
seasonId, seasonPeakRating, seasonPeakRankCode, seasonRolloverPending,
ranked, privateMatches
```

The last two use existing MatchCountsResponse; no denominator/sample means null
winRatePercent/accuracyPercent/avgAnswerTimeMs. isPro is only a badge. Every viewer
and target Free/Pro combination has the same allowlisted fields; no email, age,
friendCode, entitlements, streak calendar, topics, rating history, match history,
answers or billing data is exposed. Removing friendship makes future profile
reads 404. A racing profile read is authorized under canonical user/relation locks;
previously delivered data is not recalled.

## Room invitation flow

1. A/B become accepted friends. Keep both users' application-wide personal STOMP
   subscriptions; no Friends/result-screen-owned subscription is needed.
2. A uses EXISTING POST /duels, then POST /duels/{duelId}/invitations with B's user
   UUID and a UUID requestId for this send intent. Preserve it across retries.
3. B recovers GET /users/me/duel-invitations anywhere in the app. Its DTO is:

```text
id, duelId, host:{id,isPro,nickname}, recipient:{id,isPro,nickname},
disciplineCode, format:STANDARD, status, reason:null|reason,
createdAt, expiresAt, battleId:null|UUID, version
```

4. B accepts via the invitation URL. The common code-join core assigns B to that
   SAME room and creates one PRIVATE battle. ACCEPTED retries return the same id
   even after the battle finishes. Both still press Ready. Receiving an invite
   never reserves B or leaves their queue/room/battle. Busy/content failures are
   authoritative 409 and leave an otherwise valid invitation pending.
5. Decline/withdraw terminates only the invitation; the host's room stays waiting.
   Cancel room/room expiry/unfriend reconcile pending invitations atomically.
   Invited-recipient ordinary code join accepts for the same battleId; a different
   code join cancels as DUEL_FILLED with battleId null for the excluded recipient.

At most one pending target per room. Deadline is min(sent+60s, original room expiry)
and is never renewed. Expired accept returns 410 DUEL_INVITATION_EXPIRED after
committing expiry. Other terminated accepts return 409 DUEL_INVITATION_NOT_PENDING.
ACCEPTED cancellation/decline is 409 MATCH_ALREADY_FOUND. The invite does not grant
GET room access before assignment, and its payload never contains the room code.

PENDING/ACCEPTED/DECLINED have null reason. Cancellation reasons are
SENDER_CANCELLED, DUEL_CANCELLED, DUEL_FILLED, FRIEND_REMOVED; expiry reasons are
INVITATION_EXPIRED and DUEL_EXPIRED, with room expiry taking precedence at an
equal deadline. ACCEPTED alone has battleId. Removing friends never undoes an
already-created battle or unrelated activity/rematch.

Same host/requestId/payload returns the current original invitation. Changed
room/recipient with that requestId returns IDEMPOTENCY_CONFLICT. A fresh requestId
aliasing the current same-target pending invitation is also permanently bound to
that payload. Another pending target is DUEL_INVITATION_ALREADY_PENDING.

## Events, recovery and limits

Same native STOMP 1.2 endpoint `/ws/v1/events`, CONNECT Authorization access JWT,
personal `/user/queue/events`. No new socket/topic/SEND. Envelope stays
`{eventId,type,resourceId,version,occurredAt,data}`:

- FRIENDSHIP_CHANGED: resourceId is the persistent relationship/request UUID;
  data is RelationshipResponse.
- DUEL_INVITATION_CHANGED: resourceId is the in-memory invitation UUID;
  data is DuelInvitationResponse.

Versions equal data.version and increment only for changed state. Events publish
after commit to the two allowed participants' current sessions; rollback/no-op
emits none. Existing queue/room/battle/account/season/rematch events remain intact.
Delivery is best-effort, without outbox or durable replay.

Reconnect: subscribe first, recover pending friend requests, accepted friends,
incoming room invites/rematches and own activity. Host additionally restores its
known room/outgoing invite. Merge per resource/version and recovery generation;
discard stale HTTP callbacks. Incoming-only absence cannot prove acceptance:
restore the known invitation and activity/battle. An old REMOVED event must not
remove a newer relationship for the same user id.

V15 persists codes/relations/requests in PostgreSQL. Rooms, invitations and requestId
receipts stay in the EXISTING staged registry and vanish on backend restart.
Accepted persisted battles use existing activity/snapshot recovery; unfinished
battles become CANCELLED/SERVER_INTERRUPTION. There is no SQL invitation inbox,
broker, upload, email, OS push or separate notification registry.

Existing RequestRateLimiter has separate per-user purposes: 20 friend-code request
attempts per 20 minutes and 30 NEW invitation sends per 20 minutes. Invitation
retries/aliases do not consume the latter. Same-pair friendship and same-room/
same-target invitation cooldowns after termination are 60 seconds. 429 RATE_LIMITED
includes Retry-After. Reads/accept/decline/remove are outside send limits. Limiter
and room state remain single-process and do not promise distributed enforcement.

## Verification and deployment

From backend: `mvnw.cmd -B -ntp clean verify`, then
`python scripts/verify_e2e.py` for the actual JAR/REST/STOMP/restart smoke.
From root: `docker compose config --quiet`, `docker compose build backend`,
then `python backend/scripts/verify_compose.py --backend-image skillbattles-local-backend:latest`
for isolated HTTPS/WSS proxy and whole-stack recreation with retained test data.
Also run `git diff --check`.

All runners use isolated test DBs/ports. The user's database/volumes/.env and main
running containers are not modified. Earlier V1–V14, question assets, frontend,
Compose and external billing/mail settings are unchanged by this increment.
Deploy the built update separately against a compatible migrated database.
No commit/push or frontend browser/layout check is performed by this task.

### Completed verification (2026-11-15)

- Full Maven `verify` on the final implementation: **413 tests**, zero failures,
  errors or skips; 35 new social PostgreSQL/real-STOMP cases. A preceding full
  `clean verify` also passed before the final concurrency guards were added.
- Clean V1–V15 schema and V14→V15 upgrade preserve existing users, ratings,
  questions and prior Flyway checksums; repeat startup inserts no social seed data.
- PostgreSQL uniqueness/direction checks, whole-transaction code collision retry,
  roles/privacy/pagination/batches, every Free/Pro profile combination, exact TTL/
  cooldown boundaries, crossed requests and invite accept/code-join/cancel/expiry/
  unfriend races passed. Battle-write and unfriend rollback retained SQL/state/
  reservations and emitted no false events.
- Shared battle creation now orders UUID locks the same way as PostgreSQL and
  friendship workflows. A fixed UUID pair across the sign bit verifies the order
  and a concurrent profile/battle creation completes without inverted locks.
  Account deletion between list and metadata reads cannot emit null PublicPlayer.
- Actual built Java 21 JAR REST/STOMP smoke passed, including complete request
  state transitions, private profiles, same-room invitation accept/retry/withdraw/
  decline, two authorized personal sessions and a third outsider, reconnect and
  persistence/recovery after backend restart. Existing game/auth/billing gates,
  history/review/rematch/season flows and all 23 illustration hashes passed.
- Compose config and backend image build passed. The final image passed isolated
  HTTPS/WSS proxy smoke plus whole-stack force-recreate with retained test data.
  No user volume was removed and no `down -v` was used.
- Full generated OpenAPI checked: 17 exact additions, 57 product + 2 media methods,
  version 0.3.0, required allowlists/auth/statuses, both event definitions, unchanged
  original 40 contract objects and no practice endpoints/fields. The local full
  YAML was parsed and merged with old operation/schema contents preserved; its
  path prefix is normalized to `/api/v1` with root server URL for media consistency.
- Protected-scope checks, configured-secret scan and `git diff --check` (including
  untracked additions) passed. Local AI/spec copies remain ignored.

This task built images and ran isolated projects; it did not restart the user's
main services or write to their database. Frontend UI/browser verification remains
with the frontend task. No commit or push was performed.
