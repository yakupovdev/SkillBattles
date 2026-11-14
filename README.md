# SkillBattles

Flutter Web frontend и Java 21 / Spring Boot backend v0.3 с PostgreSQL. Один
backend-процесс: несколько replicas пока не поддерживаются. REST-контракт —
39 операций, OpenAPI `0.3.0`; функция похожих вопросов удалена.

## Локальный запуск

Нужны Docker Desktop с Linux containers и Docker Compose v2+. Flutter, Java,
Maven и PostgreSQL на хосте для основного запуска не требуются. Первая сборка
загружает Flutter SDK и зависимости; потребуется интернет и свободное место Docker.

Из корня репозитория один раз подготовьте **корневой** `.env`. В PowerShell 7:

```powershell
.\backend\scripts\Initialize-LocalEnv.ps1
```

Скрипт копирует `.env.example` только при отсутствии `.env`, генерирует только
незаполненные PostgreSQL/JWT secrets и сохраняет остальные значения. Можно
скопировать пример вручную и заполнить эти два секрета. Не меняйте пароль уже
созданного PostgreSQL volume редактированием ENV. Не публикуйте `.env` и вывод
раскрытого `docker compose config`; безопасная проверка — `config --quiet`.

```sh
docker compose config --quiet
docker compose up -d --build
docker compose ps
```

Compose ждёт готовности PostgreSQL, затем backend, затем запускает frontend.
При стандартных портах из `.env.example`:

| Адрес | Назначение |
| --- | --- |
| http://localhost:8081 | Приложение Flutter Web |
| http://localhost:8081/swagger-ui/index.html | Swagger через frontend proxy |
| http://localhost:8081/v3/api-docs | Фактический generated OpenAPI |
| http://localhost:8080 | Backend при прямом доступе для разработки |
| 127.0.0.1:55432 | PostgreSQL для локальных инструментов |

Порты задают `FRONTEND_PORT`, `BACKEND_PORT`, `POSTGRES_PORT`; опубликованы только
на loopback. При смене frontend-порта согласуйте `BILLING_SUCCESS_URL`,
`BILLING_CANCEL_URL`, `BILLING_PORTAL_RETURN_URL`, `PASSWORD_RESET_BASE_URL`.
В примере они ссылаются на `${FRONTEND_PORT}`. Существующие значения локального
`.env` скрипт инициализации не переписывает.

Браузер обращается к своему origin: REST `/api/v1`, native WebSocket
`/ws/v1/events`. Nginx сохраняет пути, проксирует Swagger и Upgrade, передаёт
проверенные forwarded headers. SPA-маршруты, включая `/auth/reset?token=...`
и `/billing/return?success=true|false`, поддерживают прямое открытие и reload.
Query-параметры с reset token не записываются в access log nginx.

Flutter SDK зафиксирован на `3.50.0` / Dart `3.14.0`, архив проверяется SHA-256;
nginx зафиксирован по версии и digest. Release-сборка содержит локальные web
resources и `DEV_MOCKS=false`. Только публичные URL задаются при сборке через
`--dart-define`: ENV готового frontend-контейнера не меняет Dart-код. Серверные
секреты передаются только backend/PostgreSQL, во frontend они не нужны.

## Управление

```sh
docker compose logs -f backend frontend
docker compose restart
docker compose up -d --build
docker compose down
```

`down` сохраняет named volume. Не добавляйте `-v`, не удаляйте существующие БД
или volumes для обновления. Миграции V1–V11 сохранены; V6 намеренно отклоняет
старую v0.2 БД с вопросами/батлами. Для такого случая нужна отдельная новая БД,
а причина ошибки должна быть установлена до любых действий с данными.

## Банк вопросов

Чистая схема содержит справочники, но не production-банк. Без достаточного
контента сервер честно возвращает `contentAvailable=false`. Для игр импортируйте
валидный банк через существующий offline importer; случайные вопросы при запуске
не добавляются. Схема JSON и правила объёма/сложностей описаны в
[backend/README.md](backend/README.md). Например, из корня PowerShell:

```powershell
# Замените путь на свой банк. Сначала dry run, затем явно apply.
docker compose cp C:/data/questions.json backend:/tmp/questions.json
docker compose exec -T backend java -jar app.jar --spring.profiles.active=question-import --questions.file=/tmp/questions.json --questions.apply=false
docker compose exec -T backend java -jar app.jar --spring.profiles.active=question-import --questions.file=/tmp/questions.json --questions.apply=true
```

Importer использует ту же конфигурацию БД, проверяет весь файл до записи и
завершается. Тестовые fixtures из `backend/src/test/resources` предназначены
только для отдельной тестовой БД.

## Stripe и почта

Только Stripe TEST Mode. Для оплаты нужны согласованные TEST key, Price IDs,
return URLs и настоящий webhook secret. При отсутствующей конфигурации billing
закрыт, Free-сценарии доступны. Не придумывайте `whsec` и не отключайте проверку
подписи. Локальный `stripe.exe` ранее блокировался Windows Application Control;
пустой `STRIPE_WEBHOOK_SECRET` не позволяет проверить Checkout → webhook → Pro.
Нужен разрешённый политиками ОС listener, пересылающий события на
`http://localhost:8080/api/v1/subscriptions/webhook`, и перезапуск backend после получения
его настоящего secret.
Скрипты настройки описаны в backend README; они используют корневой `.env`.

Для password reset нужны настоящие `SMTP_*`, `MAIL_FROM` и frontend URL
`PASSWORD_RESET_BASE_URL`. Без SMTP доставка письма не проверена. Отсутствие
доставки не обходится раскрытием reset token клиенту.

## Проверки

Backend на Java 21, из `backend/`: `./mvnw -B -ntp verify` (Windows:
`.\mvnw.cmd -B -ntp verify`). Для frontend без SDK на хосте:

```sh
docker build --target source -t skillbattles-frontend-check ./frontend
docker run --rm skillbattles-frontend-check flutter analyze
docker run --rm skillbattles-frontend-check flutter test --dart-define=OUT=/tmp
```

`OUT` нужен существующим screenshot-тестам, PNG остаются в одноразовом контейнере.
После основной сборки, при наличии Python 3 и Node.js 22+, из корня:

```sh
python backend/scripts/verify_compose.py
git diff --check
git diff --cached --check
```

Compose-проверка создаёт отдельный уникальный project/volume и случайные порты,
проверяет чистую схему, dry/apply импорт 19 test-only вопросов, две независимые
сессии REST/STOMP через frontend proxy, результат/review и перезапуск всего стека
с сохранением данных. Пользовательская БД не затрагивается. Тестовые контейнеры
и сеть удаляются, имя сохранённого тестового volume выводится в конце.

Локальный JVM launcher и Stripe/ENV скрипты остаются в `backend/scripts`.
Не запускайте JVM и Compose-backend одновременно на одном порту и БД.
