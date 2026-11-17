# syntax=docker/dockerfile:1.7
# Same SDK as `.fvmrc` (Flutter 3.47.9 ships Dart 3.13.7).
FROM dart:3.13.7 AS source
WORKDIR /app
RUN dart pub global activate jaspr_cli 0.23.5
ENV PATH="/root/.pub-cache/bin:${PATH}"
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get --enforce-lockfile
COPY . .

FROM source AS build
# Public compile-time configuration only. Never pass server ENV or secrets here.
ARG API_BASE_URL=/api/v1
ARG EVENTS_URL=/ws/v1/events
RUN jaspr build \
    --dart-define=API_BASE_URL=${API_BASE_URL} \
    --dart-define=EVENTS_URL=${EVENTS_URL}

# Debian-based nginx: the Jaspr server executable links against glibc.
FROM nginx:1.30.0 AS runtime
COPY nginx/default.conf /etc/nginx/templates/default.conf.template
COPY nginx/proxy-headers.conf /etc/nginx/proxy-headers.conf
COPY --chmod=755 nginx/start.sh /start.sh
# The server finds its static files in `web/` next to the executable.
COPY --from=build /app/build/jaspr/app /app/app
COPY --from=build /app/build/jaspr/web /app/web
EXPOSE 8080 8443
HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=5 \
    CMD curl -fsS -o /dev/null http://127.0.0.1:8080/healthz && curl -fsS -o /dev/null http://127.0.0.1:3000/ || exit 1
# nginx defaults to SIGQUIT; start.sh forwards SIGTERM to both processes.
STOPSIGNAL SIGTERM
ENTRYPOINT ["/start.sh"]
CMD []
