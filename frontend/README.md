# SkillBattles — frontend (API contract v0.3)

Flutter (web/desktop) client: live SAT-skill battles, ratings, seasons,
leaderboards and SkillBattles Pro (Stripe **test mode** only).

## Run

From the repository root, `docker compose up -d --build` builds the real release
web app with Flutter 3.50.0 / Dart 3.14.0 and starts PostgreSQL, backend and nginx.
Open https://localhost:8443 after trusting the local development CA (see the root
README for certificate initialization, ENV, imports and ports). HTTP on 8081
redirects to HTTPS; secure storage needs this secure context on LAN addresses.
The Compose build disables mocks and proxies `/api/v1`, `/ws/v1/events`, Swagger
and OpenAPI to the backend service. Browser requests stay on the current origin.
Server secrets are never frontend build arguments.

```sh
# Against the backend (same-origin proxy for REST and the WebSocket Upgrade):
flutter run -d chrome \
  --dart-define=API_BASE_URL=https://app.example/api/v1 \
  --dart-define=EVENTS_URL=wss://app.example/ws/v1/events

# Without a backend — clearly labelled development mocks (DEV panel, red
# "DEV MOCKS" chip). Never a substitute for an end-to-end check:
flutter run -d chrome --dart-define=DEV_MOCKS=true
```

Web defaults: `/api/v1` and `/ws/v1/events` on the page's origin, using `ws` for
HTTP and `wss` for HTTPS. Explicit absolute defines remain supported. Desktop
defaults remain `http://localhost:8080/api/v1` and `ws://localhost:8080/ws/v1/events`.
Defines apply at build time; container runtime ENV does not change the compiled app.
Paths use the path URL strategy, so the server-configured return URLs
`/billing/return?success=true|false` and `/auth/reset?token=…` open directly.

## Checks

```sh
dart run build_runner build --delete-conflicting-outputs   # after model changes
flutter analyze
flutter test --dart-define=OUT=/tmp  # existing scratch screenshot tests write PNGs here
```

Architecture and conventions: `.claude/rules/` and `.claude/docs/`.
