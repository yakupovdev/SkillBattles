# SkillBattles — local animated battle stickers: frontend task

Status: proposed implementation contract. Baseline develop 894079fa902b3d3fb5a6d3c2f2f475ebdc510d66 (2026-11-15).
Companions: BATTLE_STICKERS_OPENAPI.yaml (here: `battle_stickers_api.yaml`), BATTLE_STICKERS_CATALOG.json and backend specification.

> Received from the user on 2026-11-15 as BATTLE_STICKERS_FRONTEND.md. Where it differs from
> `battle_stickers.md` (playback, allowed phases, mute ownership, loading), this document wins.

## Decisions and assets

Exact wire IDs: gg, fire, facepalm, lol, hmm, too_slow, ez, wait_what, crying. Preserve lowercase and underscores; unknown incoming IDs are silently ignored. Domain has an Unknown variant that can never be sent from the picker.

Add the lottie dependency to pubspec.yaml as part of this requested feature, selecting a compatible locked version for the actual Flutter/Dart SDK. Do not use `any` or require a separate user approval solely because this feature needs that package. Actual changes still follow applicable project dependency rules.

Animation files belong to frontend assets/presentation, not backend/MinIO or domain. Expected mapping is assets/stickers/<wireId>.json; the catalog file is a DEVELOPMENT CONTRACT, not a server endpoint or runtime download manifest. If the existing files have different extensions/names, adjust the presentation mapping while preserving these wire IDs.

Actual nine Lottie files were NOT supplied with this document package. Obtain/use the project's existing files; do not generate fake animation placeholders and report them as the real assets. Verify their reported ~20KB-per-file size, correct format and all referenced image/font resources when available. They must be self-contained or refer only to bundled frontend resources, with no remote image/font fetches per sticker. Include assets in pubspec.yaml and the frontend release/Docker build.

Important for Flutter Web: frontend-bundled files are still fetched from the frontend server on first load. Bundled does not mean already in browser RAM/offline. Preload and parse the nine compositions once, before interaction (e.g. authenticated shell/Ready initialization), cache/reuse compositions, and render from those objects. Do not fetch/parse in every build or send. Lottie supports asset loading and explicit composition preloading:
https://pub.dev/packages/lottie

Do not block game readiness, answer inputs, timers or navigation waiting for animations. Until ready, disable just the picker or use a local static text/frame fallback for a known incoming sticker. No per-message loading spinner. If a composition arrives after its bubble has expired, do not replay the stale sticker. Full first-load offline operation is not promised by this feature; no new service worker/offline infrastructure is required.

## Available phases and presentation

New sends are allowed in the battle's WAITING_READY, COUNTDOWN, QUESTION and REVEAL. No sends after FINISHED/CANCELLED; the owner chose no post-battle grace window. An unjoined private room is not a battle and has no sticker UI.

Use the current design system; layout/design is owned by frontend. Keep one current own bubble and one opponent bubble, each defaulting to a three-second display window. Play a new animation from its start once (no infinite looping), replace a bubble only with a newer valid message from the same side, and do not obscure question text/options, diagram, answer feedback or timer. Use distinct message keys/controllers so re-sending the same sticker later actually restarts it.

Respect reduced-motion settings by showing a static frame/label. Provide English semantic labels (catalog has examples). An unreadable asset uses a local safe fallback instead of triggering an API send failure. Do not claim missing animations have been verified visually.

`Hide opponent stickers` is a local per-battle boolean in BLoC/Cubit. It hides/clears incoming bubbles, not own messages, server cooldown or gameplay. No mute API; no notification to the opponent. Reset per battle/logout as appropriate. No sounds/chat/history/paid sticker catalog in this increment.

## Domain and code structure

Use the project's repository/usecase/BLoC conventions:
- Domain StickerId with Unknown; receipt/incoming-message entities have no asset paths or Lottie types.
- SendStickerUsecase with SendStickerParamsEntity (battleId, stickerId, submissionId).
- Battle repository exposes sendSticker and a sticker stream filtered by battleId from the EXISTING realtime client.
- presentation maps ids to local files/preloaded compositions.
- Battle BLoC/Cubit stores current own/opponent bubbles, current sending intent, mute flag and cooldown deadline; it must not copy the whole animation object into game state.
- A small widget/ticker displays cooldown progress; do not emit whole BattleBloc state every animation frame or re-render question/options for timer ticks. Dispose subscriptions/controllers/timers.

Preserve existing image/Markdown question rendering, battle version/reconnect handling, friends/rematch events and result behavior.

## Send command and acknowledgement

NEW POST `/api/v1/battles/{battleId}/stickers`, existing access Bearer JWT:

```json
{"stickerId":"gg","submissionId":"22222222-2222-4222-8222-222222222222"}
```

The path carries battleId; do not send senderUserId/recipientId, asset URL/file, client timestamp or roomId. This is REST, not STOMP SEND. Keep the current socket's SEND prohibition.

200:

```json
{
  "battleId":"11111111-1111-4111-8111-111111111111",
  "submissionId":"22222222-2222-4222-8222-222222222222",
  "senderUserId":"aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
  "stickerId":"gg",
  "sentAt":"2026-11-15T03:00:00Z",
  "nextAllowedAt":"2026-11-15T03:00:04Z"
}
```

On tap, generate one submissionId, start own preloaded animation immediately and mark it pending locally. Disable another send while this request is in flight or cooldown remains. No animation-asset loading indicator is needed; network confirmation remains asynchronous.

200 confirms server acceptance only. Mark that intent confirmed without replaying its animation. The sender receives no echoed event. It does not mean `Delivered`/`Read`; peer may be disconnected or locally hiding stickers. Only a new accepted send consumes four seconds server-side.

Use nextAllowedAt with an existing server-clock estimate/HTTP timing and a monotonic local display timer. Never allow an old replayed receipt to shorten a later cooldown: merge deadlines with max(currentKnownDeadline,receipt.nextAllowedAt). A late response for an older submission must not replace a newer bubble, revive a terminal-screen bubble or modify another user's session state.

## Errors, retries and cooldown

ErrorResponse is existing `{code,message,fieldErrors,resetsAt}`.

| Error | Frontend action |
|---|---|
| 429 STICKER_COOLDOWN | Quietly remove that rejected optimistic preview, synchronize cooldown from resetsAt/Retry-After; NO Not sent bubble/toast |
| 400 INVALID_STICKER_ID / VALIDATION_ERROR | Mark current intent `Not sent`; do not retry the same invalid payload automatically |
| 401 UNAUTHORIZED | Existing access-token refresh path; retain same submissionId for its retry; after final failure show Not sent/auth recovery |
| 404 BATTLE_NOT_FOUND | Not sent and existing battle access/recovery behavior |
| 409 STICKERS_NOT_ALLOWED | Not sent if this intent still has a visible bubble; disable picker and recover current battle phase |
| 409 IDEMPOTENCY_CONFLICT | Not sent; do not replace submissionId and silently re-send |
| network/500 | Not sent after final failure; no unbounded retry or automatic resend on reconnect |

429 body resetsAt is exact server nextAllowedAt; Retry-After is ceiling seconds (minimum 1). Prefer existing server clock estimate; if unavailable, wait the conservative Retry-After duration from monotonic receipt time instead of comparing against an unsynchronized browser clock. This is separate from the social 20-minute limiter and must not use its generic RATE_LIMITED UI.

A timeout is ambiguous: `Not sent` means there was no confirmed acceptance; it does not prove the other player saw nothing. One short bounded retry may use the SAME submissionId while the intent is still relevant and transport/session generation is unchanged. Server deduplicates accepted submissions for 120 seconds in the same process. Do not auto-retry after that window or recreate queued intents after reload/reconnect/restart. New deliberate clicks after resolution use NEW ids. No durable send queue is part of this feature.

## Incoming events

Existing native STOMP connection /ws/v1/events, JWT in CONNECT Authorization, one subscription /user/queue/events. Add RealtimeEventType BATTLE_STICKER without new socket/topic.

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

Incoming stickerId decoder must accept an arbitrary string and map an unsupported id to Unknown, then silently skip it. Do not reject the whole realtime client or crash JSON decoding because a future backend knows a new sticker. Outgoing picker still has only the nine supported ids.

Validate resourceId == data.battleId == current battle, sender is the known other participant, and current phase is allowed. Ignore self echoes, old connection/battle/session generations, duplicate eventId/submissionId and lower/equal sticker sequence; ignore known ids when locally muted. For optional stale-event protection, ignore events more than five seconds old only when a reliable SERVER clock estimate is available (never compare blindly to local wall clock). No toast for ignored events.

Envelope version is STICKER SEQUENCE, NOT the battle's BATTLE_CHANGED version. Keep it in its own per-type/resource cache. Sequence gaps are normal because sender does not get their own events. Do not trigger snapshot recovery or update game version on a sticker gap. Backend restart resets sticker sequence; every new connection/recovery generation rebuilds this sticker-only baseline and drops callbacks from old generations.

On a valid message, replace/play the opponent bubble once from the cached local composition, without affecting answers/scoring/timer. Clear bubbles on leaving/changing battle, logout and terminal transition; never show/replay them on result/review pages. A delayed HTTP confirmation may settle internal send status but cannot recreate a terminal UI bubble.

Reconnect restores game snapshot/activity as before, but NEVER requests sticker history or replays missed stickers. Cooldown after a fresh frontend connection can be unknown until next send; an authoritative 429 quietly resynchronizes it. The game snapshot schema itself does not change for this feature.

## Checks

- All nine actual animations map to exact IDs, load/parse once, package into Flutter Web and work on a warmed cache with sticker-related networking blocked. Verify first-load behavior separately; don't claim offline availability before loading assets.
- Allowed phases and immediate disable at FINISHED/CANCELLED; no result-page send.
- Own immediate animation + success without double play; opponent-only event, three-second bubbles, mute and reduced motion.
- Four-second timer updates only the small UI; 429 quietly syncs, other failures display Not sent.
- Same-id retry/auth refresh, conflict/timeout/no unbounded resend, old-ACK/later-cooldown race.
- Duplicate/reordered/unknown-id/wrong-battle/stale-generation events, separate sticker/game counters, no reconnect history replay.
- No Lottie parsing/network/whole-screen rebuild per sticker; active gameplay remains responsive.
- flutter analyze/tests/release build; actual two-user REST/STOMP through Compose with DEV_MOCKS=false, plus third-party access checks with backend.
