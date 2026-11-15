# Packaged question illustrations — backend handoff

The complete generated contract is `backend/target/generated-openapi.json`,
produced by Maven `verify`. Version remains `0.3.0`: 40 product REST operations
plus 2 anonymous media GET/HEAD operations. The supplied feature-only YAML does
not replace that complete contract. Frontend UI rendering is a separate task.

## Public question field

`QuestionResponse` and `ReviewQuestionResponse` add exactly one required,
nullable field, `imageUrl`. Existing request bodies are unchanged.
The current public option shape stays `{id,text}`; the extra `key` shown in
some proposed feature examples is not introduced into the existing API.

```json
{
  "imageUrl": "/media/questions/SAT_MATH/3f5a3602/224eefc655e44ddac7e07d499e9fad2ba90e28bd8db675e8cd15b31156b7a203.png"
}
```

This is the additive fragment, not the complete question. Without an image the
field is explicitly `null`, including old persisted JSONB with no imageKey.
Resolve the URL against the page origin, preserving HTTPS/host/port; do not append
it to `/api/v1` or reconstruct it from a question UUID. Display the image above
the existing prompt, preserve its aspect ratio, and retain Markdown/LaTeX and
the original textual diagram descriptions. Loading/error/retry UI belongs to
the frontend task; an image failure must not change the timer or answer state.

The field is present in:

- `GET /api/v1/battles/{id}` → `round.question.imageUrl`;
- returned readiness/surrender snapshots when a round is present;
- the existing `BATTLE_CHANGED` envelope → `data.round.question.imageUrl`;
- `GET /api/v1/battles/{id}/review` → `rounds[].question.imageUrl`.

Each comes from the same frozen question revision, including overtime. There
are no future-image previews, new event types, STOMP commands or subscriptions.
Result/history/rematch/account responses do not gain an image field. Free/Pro
both see the illustration of an accessible question; the existing answer,
explanation, history and mistakesOnly gates are unchanged.

## Media HTTP

Anonymous GET and HEAD:
`/media/questions/{disciplineCode}/{sourceId}/{sha256}.png`.

- GET 200: exact original PNG, `Content-Type: image/png`, original Content-Length,
  `X-Content-Type-Options: nosniff`, public one-year immutable Cache-Control
  (directive order is not significant).
- HEAD 200: same metadata without a body. Last-Modified conditional requests can
  return 304 without a body. ETag is not required.
- Unknown valid key: GET 404 with the existing ErrorResponse; HEAD 404 without
  a body. Neither receives the immutable success cache policy.
- Invalid/traversal keys are rejected. No directory listing, manifest/source
  files, upload/delete endpoint, external URL fetching or arbitrary classpath
  access is exposed. Other APIs remain JWT protected.

Nginx proxies `/media/questions/` to the backend with the path intact on the
existing HTTPS origin. TLS, HTTP redirect, COOP/COEP, REST and STOMP are preserved.

Examples after deployment (use the application's current origin):

```text
/media/questions/SAT_MATH/3f5a3602/224eefc655e44ddac7e07d499e9fad2ba90e28bd8db675e8cd15b31156b7a203.png
/media/questions/SAT_RW/a15b3219/b61ffefd1f32186b69ee8d6bf4fc841c320a14642d672494226432d1b478f513.png
```

## Assets, revisions and deployment

23 original PNGs are versioned under `backend/src/main/resources/question-images/`:
21 Math and 2 Reading & Writing. All are copied unchanged into the Maven JAR and
Docker image. 22 READY bindings use externalKey, not database UUID/position/text.
`SAT_MATH:15ce8207` is the single `DEFERRED_SOURCE_REMOVED`: its PNG remains
available, but no question or attachment is recreated for it.

The original delivery manifest was absent. With the owner's confirmation, the
manifest was reconstructed from the confirmed original `images.zip` and V12;
byte lengths, PNG decoding/dimensions, SHA-256 and discipline/difficulty identities
are checked. The test inventory is `src/test/resources/question-images-manifest.json`;
the local reference/specification copies remain ignored under `.ai/question-images/`.
No manifest is served by the media namespace.

V14 adds nullable `questions.image_key`, validates all 22 expected original rows
and atomically appends revision 2 while deactivating revision 1. Original authored
content and option IDs/correct mappings are preserved. The remaining 217 active
source questions are unchanged: 239 active logical questions, 261 seed revisions.
Custom/additional data is retained; unexpected/missing/newer READY sources abort
the entire migration instead of silently changing or downgrading content.

The owner confirmed 239 and authorized fixing V12's stale 240-row count assertion.
Its checksum therefore changes. **Before updating an existing deployment, audit
its applied V12/content and decide the migration-history reconciliation explicitly.**
No automatic Flyway repair, database reset, history rewrite or volume deletion
was performed. Fresh installs and isolated upgrades use the corrected chain.

For a compatible database, ordinary `docker compose up -d --build` packages and
serves images automatically; there are no extra services, ENV, volumes, SDKs or
manual runtime copy steps. This task tests new images on isolated projects and
does not update the main running backend/database.

To add the next illustration: retain original bytes, derive a new content-hashed
key, package it, and create a new question revision through an append-only Flyway
migration or the local JSON importer. Optional imageKey must name an existing
packaged PNG and match discipline/source externalKey. Legacy imports without the
field remain valid. Identical v1/v2 imports are idempotent; changing an image under
the same contentVersion conflicts. Retain every old hash-keyed asset so frozen
history URLs continue to work.

## Verification

Commands run from `backend/` unless noted otherwise:

```text
mvnw.cmd -B -ntp clean verify
python scripts/verify_e2e.py
```

From the repository root:

```text
docker compose config --quiet
docker compose build backend frontend
python backend/scripts/verify_compose.py --backend-image skillbattles-local-backend:latest --frontend-image skillbattles-local-frontend:latest
git diff --check
```

The runners use isolated databases/ports, never import fixtures into the user's
database, and never run `down -v`. Frontend browser/layout verification is separate.
No commit/push is performed.

### Completed results (2026-11-15)

- Full Java 21 Maven `clean verify`: **378 tests**, zero failures/errors/skips.
  Final targeted `verify`: all 7 image tests passed, including the added
  pre-existing battle-history preservation assertion.
- Clean V1–V14 install, V13→V14 upgrade with custom data/users/ratings/history
  retained, idempotent startup and atomic rollback for a newer conflicting source
  passed. No missing READY binding was silently skipped.
- Actual JAR REST/STOMP/media smoke passed: exact 23 PNG hashes, GET/HEAD/304,
  no immutable-cache on missing files, namespace/traversal rejection, JWT protection,
  frozen URLs in REST/STOMP/review, actual overtime and backend restart recovery.
- Compose config/build/start passed. New images passed isolated HTTPS/WSS smoke,
  first with restart and then with whole-stack **force-recreate**, retaining the
  test database. All 23 hashes were checked again after recreation. COOP/COEP and
  existing REST/STOMP/auth/history/rematch/Free-Pro regression scenarios passed.
- Complete generated OpenAPI checked: 40 product plus 2 media operations,
  required nullable imageUrl, explicit anonymous GET/HEAD and no practice endpoints.
  All 23 expected hashes are present inside the actual executable JAR.
- Local full YAML parsed; all original 40 product operations and old model fields
  are preserved, with only the intended imageUrl/media additions. Protected scope,
  configured-secret scan and `git diff --check` passed; assets are not ignored.

The main frontend/backend/PostgreSQL containers were not restarted by this task.
Existing deployment reconciliation for the changed V12 checksum remains manual
and must be agreed before rollout. No browser/layout verification was performed.
