# Battle stickers — backend handoff

Implemented on the current develop source tree. API version stays 0.3.0.
The runtime contract now has **41 product REST operations + 2 question media GET/HEAD**.
The existing local target specification also contains planned friends operations;
those are preserved, but are not implemented by this sticker change.
The authoritative runtime export is `target/generated-openapi.json` after Maven verify.

## Command and acknowledgement

`POST /api/v1/battles/{id}/stickers`, access JWT only. Body exactly:

```json
{"stickerId":"gg","submissionId":"22222222-2222-4222-8222-222222222222"}
```

Exact lowercase IDs: `gg`, `fire`, `facepalm`, `lol`, `hmm`, `too_slow`, `ez`,
`wait_what`, `crying`. No aliases, text, target/sender IDs, timestamps, URLs or uploads.
Unknown fields, non-string/missing/blank/overlong IDs and invalid UUIDs are VALIDATION_ERROR.
A bounded nonblank unsupported ID is INVALID_STICKER_ID.

200 body has exactly `battleId, submissionId, senderUserId, stickerId, sentAt, nextAllowedAt`.
Dates are server UTC; nextAllowedAt is sentAt +4000ms. Cache-Control is no-store.
200 means accepted, never Delivered/Read. Sender shows its own animation locally.

Allowed phases: WAITING_READY, COUNTDOWN, QUESTION, REVEAL. A private waiting room
is not a battle. No new sends in FINISHED/CANCELLED, no grace period. Access is
identical across Free/Pro, both disciplines, RANKED/PRIVATE. Unknown/foreign battle
is 404 BATTLE_NOT_FOUND. New terminal send is 409 STICKERS_NOT_ALLOWED.

## Retry and errors

Cooldown is per authenticated user, across IDs/tabs/sessions/battles, in one process.
At exactly nextAllowedAt a new send is allowed. Rejected sends consume nothing.
429 STICKER_COOLDOWN uses existing `{code,message,fieldErrors,resetsAt}`:
resetsAt is exact nextAllowedAt, Retry-After is ceiling remaining seconds, minimum 1.
For 2750ms remaining it is 3. Frontend quietly removes the rejected optimistic
preview and synchronizes its timer. Other final failures use Not sent; a timeout
is unconfirmed and does not prove the peer saw nothing.

For 120 seconds from acceptance, (senderUserId,submissionId) identifies a retained
receipt. Matching battleId/stickerId returns the original 200 including after
terminal, without another event, sequence allocation or cooldown extension.
Changed payload returns 409 IDEMPOTENCY_CONFLICT. Retention ends exactly at +120s.
Authentication/participant ownership is still checked on retry. Never automatically
resurrect old intents on reconnect/reload or after the retention window.

Other errors: 400 VALIDATION_ERROR/INVALID_STICKER_ID, 401 UNAUTHORIZED,
404 BATTLE_NOT_FOUND, 409 STICKERS_NOT_ALLOWED/IDEMPOTENCY_CONFLICT,
500 INTERNAL_ERROR. There is no sticker STOMP error command.

## Realtime

Existing native STOMP 1.2 `/ws/v1/events`, access JWT in CONNECT, sole subscription
`/user/queue/events`. No STOMP SEND, second connection, public topic or history API.
Only the opponent's current subscribed authorized session receives:

```json
{
  "eventId":"33333333-3333-4333-8333-333333333333",
  "type":"BATTLE_STICKER",
  "resourceId":"11111111-1111-4111-8111-111111111111",
  "version":1,
  "occurredAt":"2026-11-15T03:00:00Z",
  "data":{
    "battleId":"11111111-1111-4111-8111-111111111111",
    "submissionId":"22222222-2222-4222-8222-222222222222",
    "senderUserId":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
    "stickerId":"gg",
    "sentAt":"2026-11-15T03:00:00Z"
  }
}
```

resourceId equals data.battleId; occurredAt equals data.sentAt. version is the
separate per-battle sticker sequence shared by both senders, never battle.version.
Gaps are expected because the sender gets no echo. Keep a separate frontend cache
and reset its baseline per connection generation. Incoming IDs are open strings;
ignore unknown future values, stale generations, self echoes, other battles,
duplicates and terminal-screen events. Do not trigger battle snapshot recovery
for sticker sequence gaps. Local hide-opponent mode changes presentation only.

Delivery is best-effort. Offline, rejected queue, closed/replaced session or
transport failure can lose a notification. ACK remains accepted, retries do not
re-emit. A task binds its target generation before enqueue and rechecks it before
delivery; queued work cannot be replayed into a replacement connection.

## Storage and integration

No migrations, dependencies, asset hosting or BattleSnapshot changes. Receipts,
cooldowns and sticker counters exist only in memory; restart clears them. No
exactly-once guarantee across restarts. Bounded maintenance visits at most 64 user
entries and 32 battle counters per 30-second pass. Quiet active battles retain
their sequence. Terminal counters retire after outstanding authorization reads
finish. No per-send task/thread/timer is allocated for protocol cleanup.

Owned BattleService reads finish successfully before consuming any slot or
publishing. No DB locks are held by sticker-state locks, no tick/finalize,
battle UPDATE, score/Elo/usage/presence mutation or full snapshot projection.
Existing rematch/room/image/account transport handlers remain intact.
Frontend implementation and Lottie assets are out of scope. The original catalog
was absent from the supplied files; local development metadata was reconstructed
from the confirmed nine IDs, without fabricated animation files.

## Verification

Java 21 `clean verify`: **424 tests, 0 failures/errors/skipped**; includes **46 new
sticker tests** (28 state/concurrency/failure, 3 realtime queue/session, 15 real
PostgreSQL/REST/STOMP). Generated runtime OpenAPI contains exactly 41 product +2
media operations; all 40 previous operation contract shapes remain unchanged.
Real built-JAR REST/native STOMP smoke including process restart passed.
New tests cover state/time,
concurrency/read rollback/queue drop, real PostgreSQL REST and native STOMP,
auth/ownership/request shape/phases/plans/modes/disciplines, no DB updates,
no sender echo or third-party/replaced-session delivery, and preserved SEND ban.
The existing JAR and isolated Compose HTTPS/WSS smoke runners include sticker ACK,
429, retry/conflict/terminal, independent sequence, unchanged snapshots and actual
process restart. Main application DB/volumes are not part of those checks.

Final isolated Compose HTTPS/WSS smoke passed through the existing frontend proxy
using the trusted local CA, including whole-stack force-recreate and sticker receipt
loss on restart. Clean V1-V14 schema: 239 active questions /261 stored revisions.
Only the test project's containers/network were removed; its volume was retained.
The original main backend/frontend/PostgreSQL container IDs remain unchanged and
healthy. Main services were not redeployed. Browser/frontend animation behavior
was not verified. `git diff --check` and changed-file scope/secret checks passed;
no commit or push was performed.
