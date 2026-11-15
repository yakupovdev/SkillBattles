# Global rematch notifications — backend handoff

The complete generated OpenAPI is `backend/target/generated-openapi.json`, produced
by `cd backend` then `./mvnw -B -ntp verify` (`mvnw.cmd` on Windows). This feature
adds one operation: the baseline 39 becomes **40**, still OpenAPI version `0.3.0`.
The feature-only reference under `.ai/rematch-notifications/` does not replace
the complete application contract. No frontend implementation is included.

## New operation

```http
GET /api/v1/users/me/rematch-invitations
Authorization: Bearer <access JWT>
```

No request body, query parameters, arbitrary userId or pagination. Success is
`200 application/json` with `Cache-Control: no-store`:

```json
{
  "data": [{
    "sourceBattleId": "11111111-1111-4111-8111-111111111111",
    "requester": {
      "id": "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
      "isPro": false,
      "nickname": "Alex"
    },
    "disciplineCode": "SAT_MATH",
    "expiresAt": "2026-11-15T00:01:00Z",
    "version": 1
  }],
  "serverTime": "2026-11-15T00:00:20Z"
}
```

Both top-level fields are required; an empty snapshot is `{"data":[],"serverTime":"..."}`.
Only incoming WAITING invitations with `expiresAt > serverTime` are included,
ordered by expiresAt then sourceBattleId. The requester is `requestedBy[0]`.
`disciplineCode` is an open catalogue code. Error statuses are 401 UNAUTHORIZED
and 500 INTERNAL_ERROR, using the existing `{code,message,fieldErrors,resetsAt}`.
There is no success-with-empty-data fallback on metadata/database errors.

## Existing commands and events

POST/GET/DELETE `/api/v1/battles/{id}/rematch` are unchanged. POST requests or
accepts, GET restores known state, DELETE cancels/declines with 204. There is no
DECLINED status. DELETE on MATCHED returns 409 MATCH_ALREADY_FOUND; expired POST
returns 410 REMATCH_EXPIRED. Existing ownership/history/content/activity checks
remain authoritative. Receiving an invitation never reserves its recipient.

RematchResponse/event data retains exactly `sourceBattleId,status,requestedBy,
expiresAt,battleId,version`. REMATCH_CHANGED retains the existing envelope
`eventId,type,resourceId,version,occurredAt,data`; resourceId is the SOURCE battle.
No new event type, destination, mandatory wire field or STOMP SEND is introduced.
Native STOMP 1.2 uses `/ws/v1/events`, JWT in CONNECT Authorization and the
existing `/user/queue/events` subscription. Initial WAITING targets both current
participant sessions after commit. Retries do not emit another transition.

## Two-account integration scenario

1. A/B complete a PRIVATE battle. Keep B's application-wide personal STOMP
   subscription while B opens home/profile; no result-screen listener is required.
2. A POSTs the source's rematch URL. Both receive WAITING version 1. B's new GET
   contains one card with A's nickname/Pro flag, source discipline and the original
   expiry. A's list is empty; an unrelated C's list is empty and C receives no event.
3. Reconnect/reload B: attach the listener and subscribe before fetching invitations
   and activity. The same source/deadline/version returns within the original TTL.
4. B POSTs to accept: the same MATCHED battleId is returned on retry, both recover
   BATTLE activity and WAITING_READY. Each player must still press Ready. The
   incoming card disappears. DELETE now returns MATCH_ALREADY_FOUND.
5. Alternatively B DELETEs: both receive CANCELLED, repeated DELETE is safe, the
   requester reservation is released. A busy recipient can still decline without
   leaving their other queue, room or battle. Other invitations remain WAITING.
6. At exactly expiresAt the list excludes the invitation and POST returns 410.
   Reads/retries/reconnect never start a fresh 60-second timer.

On a new connection/recovery generation rebuild version baselines and discard
old HTTP callbacks. Within that generation retain terminal versions to prevent
a late WAITING/snapshot from reopening a card. Lost MATCHED is recovered through
`/users/me/activity` and the existing battle snapshot, not the incoming-only list.

Pending invitations are process memory only: they survive client reconnects but
not a backend restart. Afterwards the list is empty and GET known rematch returns
REMATCH_NOT_FOUND. Accepted battles remain persisted and follow existing startup
recovery (unfinished battles become CANCELLED/SERVER_INTERRUPTION). No inbox,
read/unread history, migration, external broker, push or email was added.

## Verification commands

`mvnw.cmd -B -ntp verify` covers the full contract and PostgreSQL/real-STOMP tests,
including TTL boundaries, batches, commit/rollback, replaced sessions, two-party
consent, accept/cancel/expiry races, busy states, content failure and history gates.
After the JAR is built, `python scripts/verify_e2e.py` runs real public REST/STOMP
flows and restarts that JAR against its isolated tmpfs database. The existing
`python backend/scripts/verify_compose.py --backend-image skillbattles-local-backend:latest`
checks the freshly built image through the actual
HTTPS/WSS proxy with an isolated project/ports/database. No browser is required.
These runners never import fixtures into the user's DB and never delete its volumes.
Build that image with `docker compose build backend` first. This does not restart
the main container; publish the backend update separately when ready. Until then,
the main application's `/v3/api-docs` can still describe the previous running build.

## Completed verification (2026-11-15)

- Full Maven `verify`: 371 tests, zero failures/errors/skips, including 15 new
  PostgreSQL/STOMP invitation cases. Final contract/package verification: 20 tests
  passed after the OpenAPI description was updated to 40 operations.
- Actual Java 21 JAR REST/STOMP smoke passed, including client reconnect, backend
  restart, pending invitation loss and persisted accepted-battle recovery.
- Built backend image passed isolated HTTPS/WSS proxy smoke, clean V1–V13 schema,
  240-question seeds and whole-stack restart with retained test data.
- Complete generated OpenAPI: 40 operations, version 0.3.0, the new response and
  existing rematch/event shapes checked. Removed practice routes/fields are absent.
- Local full YAML was parsed and compared with its pre-change copy: all 39 existing
  path blocks and existing schemas are unchanged. `git diff --check` passed.

No browser/frontend UI verification was performed. Frontend code, Compose,
migrations and the user's database/volumes were not changed. The main backend
container was not restarted. No commit or push was performed.
