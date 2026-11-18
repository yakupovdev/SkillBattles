# SkillBattles (web)

The SkillBattles web client, built with [Jaspr](https://docs.jaspr.site) in
server mode: the Jaspr server renders the document and the browser hydrates
the app (`SkillBattlesRoot`, a `@client` component). The app itself starts
only in the browser — the session lives in `localStorage`, and the realtime
connection, KaTeX and lottie-web are browser-only. In the Docker image, nginx
terminates TLS, serves the static files, proxies `/api` and `/ws` to the
backend and every other path to the Jaspr server.

`frontend/` holds the Flutter web app this project was ported from. Data,
domain and bloc layers were carried over unchanged (blocs run on
`bloc_signals`, bound to components with `bloc_signals_jaspr`); only the UI
was rewritten.

## Running

```sh
jaspr serve        # http://localhost:8080
```

Compile-time configuration (same keys as the Flutter app):

```sh
jaspr serve --dart-define=API_BASE_URL=/api/v1 --dart-define=EVENTS_URL=/ws/v1/events
```

## Building

```sh
jaspr build        # build/jaspr/app (server executable) + build/jaspr/web
docker build .     # nginx + Jaspr server image (see nginx/start.sh)
```

## Layout

- `lib/` — the app. `main.server.dart` renders the document (`<head>`:
  meta, fonts, global CSS, vendored scripts); `main.client.dart` hydrates it.
- `web/` — global CSS (`styles/base.css`), fonts, icons, league
  emblems, sticker animations, and vendored KaTeX / lottie-web.
- `test/` — unit tests (`dart test`).
