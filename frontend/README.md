# SkillBattles — frontend (API contract v0.3)

Flutter (web/desktop) client: live SAT-skill battles, ratings, seasons,
leaderboards and SkillBattles Pro (Stripe **test mode** only).

## Run

```sh
# Against the backend (same-origin proxy for REST and the WebSocket Upgrade):
flutter run -d chrome \
  --dart-define=API_BASE_URL=https://app.example/api/v1 \
  --dart-define=EVENTS_URL=wss://app.example/ws/v1/events

# Without a backend — clearly labelled development mocks (DEV panel, red
# "DEV MOCKS" chip). Never a substitute for an end-to-end check:
flutter run -d chrome --dart-define=DEV_MOCKS=true
```

Defaults: `http://localhost:8080/api/v1` and `ws://localhost:8080/ws/v1/events`.
Paths use the path URL strategy, so the server-configured return URLs
`/billing/return?success=true|false` and `/auth/reset?token=…` open directly.

## Checks

```sh
dart run build_runner build --delete-conflicting-outputs   # after model changes
flutter analyze
flutter test
```

Architecture and conventions: `.claude/rules/` and `.claude/docs/`.
