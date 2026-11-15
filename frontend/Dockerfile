# syntax=docker/dockerfile:1.7
FROM ubuntu:24.04 AS flutter-sdk
RUN apt-get update && apt-get install -y --no-install-recommends     ca-certificates curl git unzip xz-utils libglu1-mesa libstdc++6     && rm -rf /var/lib/apt/lists/*
ARG FLUTTER_VERSION=3.50.0
ARG FLUTTER_SHA256=6ea2d806fd57269ae783e6788e2a81fc26eaad782f1e0d0ff38623bb765ff9f5
ENV FLUTTER_ROOT=/opt/flutter     PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$PATH     CI=true FLUTTER_SUPPRESS_ANALYTICS=true DART_SUPPRESS_ANALYTICS=true
RUN curl -fsSL --retry 3 "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" -o /tmp/flutter.tar.xz     && echo "${FLUTTER_SHA256}  /tmp/flutter.tar.xz" | sha256sum -c -     && tar -xJf /tmp/flutter.tar.xz -C /opt && rm /tmp/flutter.tar.xz     && git config --global --add safe.directory /opt/flutter     && flutter config --no-analytics --enable-web     && flutter precache --web

FROM flutter-sdk AS source
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get --enforce-lockfile
COPY . .

FROM source AS build
# Public compile-time configuration only. Never pass server ENV or secrets here.
ARG API_BASE_URL=/api/v1
ARG EVENTS_URL=/ws/v1/events
RUN flutter build web --release --wasm --no-pub --no-web-resources-cdn     --dart-define=DEV_MOCKS=false     --dart-define=API_BASE_URL=${API_BASE_URL}     --dart-define=EVENTS_URL=${EVENTS_URL}

FROM nginx:1.30.0-alpine@sha256:0272e4604ed93c1792f03695a033a6e8546840f86e0de20a884bb17d2c924883 AS runtime
COPY nginx/default.conf /etc/nginx/templates/default.conf.template
COPY nginx/proxy-headers.conf /etc/nginx/proxy-headers.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 8080 8443
HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=5     CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
