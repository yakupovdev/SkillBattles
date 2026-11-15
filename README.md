# SkillBattles

Flutter Web frontend и Java 21 / Spring Boot backend v0.3 с PostgreSQL. Один
backend-процесс: несколько replicas пока не поддерживаются. REST-контракт —
58 продуктовых операций и 2 публичные media GET/HEAD, OpenAPI `0.3.0`;
функция похожих вопросов удалена. Иллюстрации вопросов упакованы в backend image:
подробности в [handoff](backend/QUESTION_IMAGES_HANDOFF.md).
Добавлена REST-команда временных стикеров и событие сопернику: [контракт](backend/BATTLE_STICKERS_HANDOFF.md).
Друзья, базовые профили друзей и приглашения в существующие приватные комнаты —
[FRIENDS_HANDOFF.md](backend/FRIENDS_HANDOFF.md).

## Локальный запуск

Нужны Docker Desktop с Linux containers и Docker Compose v2+. Flutter, Java,
Maven и PostgreSQL на хосте для основного запуска не требуются. Первая сборка
загружает Flutter SDK и зависимости; потребуется интернет и свободное место Docker.

Из корня репозитория один раз подготовьте **корневой** `.env`. В PowerShell 7:

```powershell
.\backend\scripts\Initialize-LocalEnv.ps1
```

Скрипт копирует `.env.example` только при отсутствии `.env`, генерирует только
незаполненные PostgreSQL/JWT secrets и сохраняет остальные значения. Он также
подготавливает локальные HTTPS-сертификаты, сохраняя существующий локальный CA.
Для существующего `.env` сертификаты можно подготовить отдельно командой
`.\backend\scripts\Initialize-LocalHttps.ps1`. Не меняйте пароль уже
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
| https://localhost:8443 | Приложение Flutter Web |
| https://localhost:8443/swagger-ui/index.html | Swagger через frontend proxy |
| https://localhost:8443/v3/api-docs | Фактический generated OpenAPI |
| http://localhost:8081 | Перенаправление на HTTPS |
| http://localhost:8080 | Backend при прямом доступе для разработки |
| 127.0.0.1:55432 | PostgreSQL для локальных инструментов |

Порты задают `FRONTEND_PORT` (HTTP), `FRONTEND_HTTPS_PORT` (HTTPS), `BACKEND_PORT`,
`POSTGRES_PORT`. Frontend опубликован на `0.0.0.0`: устройства в общей сети
открывают `https://<LAN-IP компьютера>:8443`. Старый HTTP-адрес перенаправляет на HTTPS.
HTTPS нужен Flutter Secure Storage для сохранения токенов в secure context.
Backend и PostgreSQL опубликованы на loopback. При смене frontend-порта согласуйте `BILLING_SUCCESS_URL`,
`BILLING_CANCEL_URL`, `BILLING_PORTAL_RETURN_URL`, `PASSWORD_RESET_BASE_URL`.
В примере они ссылаются на `${FRONTEND_PORT}`. Существующие значения локального
`.env` скрипт инициализации не переписывает.

Один раз установите **публичный** `backend/.cache/local-tls/ca.crt` в доверенные
корневые сертификаты каждого устройства, с которого открывается приложение.
Для Windows / текущего пользователя, из корня PowerShell:

```powershell
Import-Certificate -FilePath .\backend\.cache\local-tls\ca.crt -CertStoreLocation Cert:\CurrentUser\Root
```

Сертификат также доступен по `http://<LAN-IP компьютера>:8081/local-ca.crt`;
сверьте его SHA-256 с выводом `Initialize-LocalHttps.ps1`. Скрипт сам доверие не
устанавливает. Не переносите файлы `.key` на другие устройства. Ключ локального
CA не передаётся контейнерам; nginx получает через read-only Compose secrets
только серверные certificate/key и публичный CA. Эти файлы игнорируются Git и
не входят в Docker images. Сертификат сервера действителен 90 дней; после смены
IP/обновления повторите инициализацию и `docker compose restart frontend`.

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
или volumes для обычного обновления. Flyway выполняет V1–V12, V14 и V15; V13 теперь только в тестах.
V1–V11 сохранены без изменения checksums; отдельной baseline-миграции нет.
V6 намеренно отклоняет
старую v0.2 БД с вопросами/батлами. Для такого случая нужна отдельная новая БД,
а причина ошибки должна быть установлена до любых действий с данными.

## Банк вопросов

`V12` содержит **239 вопросов** из предоставленных SAT Markdown: 119 Math
и 120 Reading & Writing. Удалённый `SAT_MATH:15ce8207` не восстанавливается.
Отдельный импорт для начала игры не нужен. Все 216 оставшихся исходных
наборов A–D сохранены; для 23 числовых Math-вопросов по согласованию добавлены
три неверных варианта, правильные ответы и объяснения сохранены. Полный аудит —
в [backend/QUESTION_BANK.md](backend/QUESTION_BANK.md). `V14` добавляет 22 ревизии
с изображениями: 239 активных вопросов, 261 seed-ревизия. Все 23 PNG включены
в backend image; один файл отложен без привязки к удалённому вопросу.
По подтверждению владельца устаревшая проверка количества V12 исправлена 240 → 239.
Для существующей БД перед обновлением нужно явно сверить checksum/content V12;
автоматический repair или сброс данных не выполняется.

`V13__seed_local_demo_accounts.sql` перенесён без изменения SQL в
`backend/src/test/resources/db/migration/`: демоаккаунты создаются только в тестах
и отсутствуют в runtime JAR/образах. На уже использованной локальной БД с V13
Flyway обнаружит отсутствующую применённую миграцию. Для этого изменения используйте
отдельную чистую локальную БД; текущие данные/volume автоматически не удаляются,
`repair` не запускается. Новая Heroku Postgres начинает с чистой схемы.

Для дополнительного контента остаётся offline importer. Схема JSON и правила объёма/сложностей описаны в
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
Часть старых экранных тестов ожидает development mock backend, отсутствующий
в текущей DI: `DEV_MOCKS=true` их не исправляет. Это отдельный долг тестов;
release Dockerfile собирает с `DEV_MOCKS=false` и реальными remote clients.
После основной сборки, при наличии Python 3 и Node.js 22+, из корня:

```sh
python backend/scripts/verify_compose.py
git diff --check
git diff --cached --check
```

Compose-проверка создаёт отдельный уникальный project/volume и случайные порты,
проверяет чистую схему V1–V12 + V14–V15, 239 активных вопросов и 261 seed-ревизию. Только внутри этой
тестовой БД seed-банк деактивируется, затем проверяется dry/apply импорт 19 test-only вопросов, две независимые
сессии REST/STOMP через frontend proxy, результат/review и перезапуск всего стека
с сохранением данных. Пользовательская БД не затрагивается. Тестовые контейнеры
и сеть удаляются, имя сохранённого тестового volume выводится в конце.

Локальный JVM launcher и Stripe/ENV скрипты остаются в `backend/scripts`.
Не запускайте JVM и Compose-backend одновременно на одном порту и БД.

## Первый деплой на Heroku через GitHub

Цель: Cedar app `skill-battles`, один Basic web dyno (512 МБ) и Heroku Postgres
Essential-0. Ветка в подключённом `yakupovdev/SkillBattles` — `develop`, Automatic
Deploys оставьте выключенным. Команды ниже предназначены для ручного следующего
шага: эта подготовка не создаёт ресурсы, не меняет Heroku, не делает commit/push.

### Образ и runtime

Корневые `Dockerfile.heroku` и `heroku.yml` собирают Flutter 3.50.0 / Dart 3.14.0
(архив с SHA-256, зависимости из lockfile), затем Java 21 JAR со frontend внутри
`classpath:/static/`. Runtime содержит только JRE и приложение. Nginx, Flutter SDK,
Maven, второй web-процесс и Docker Compose в Heroku не запускаются.
Dockerfile не использует BuildKit cache mounts или другие расширения синтаксиса.
`heroku.yml` использует Dockerfile CMD без отдельного `run`, как описано в
[документации Heroku](https://devcenter.heroku.com/articles/build-docker-images-heroku-yml).
Config Vars не нужны во время сборки, frontend получает только относительные
публичные пути и `DEV_MOCKS=false`. Старые Dockerfile и Compose сохранены.

Профиль `heroku` слушает `0.0.0.0:${PORT}`, учитывает forwarded headers от Heroku
HTTPS router, оставляет Flyway enabled и Hibernate `ddl-auto=validate`.
`DATABASE_URL` обязателен: URI postgres/postgresql преобразуется в JDBC URL,
userinfo декодируется отдельно (включая `%xx` и буквальный `+`), credentials не
попадают в JDBC URL. По умолчанию TLS `sslmode=require`; слабые режимы отвергаются.
`verify-ca`/`verify-full` сохраняются, если явно заданы с необходимым доверием к CA.
См. [подключение Heroku Postgres](https://devcenter.heroku.com/articles/connecting-heroku-postgres).
Локальные `DB_*` в этом профиле не используются. Hikari: максимум 5 соединений,
минимум 1, connection timeout 10 секунд; остаётся запас в лимите Essential-0 для
миграций и служебных подключений.

Spring отдаёт frontend с COOP `same-origin` / COEP `require-corp`, MIME
`application/wasm` и `application/javascript` для `.mjs`. Только реальные клиентские
маршруты получают SPA fallback, в том числе `/auth`, `/auth/reset`, `/billing/return`,
`/play/search`, `/play/duel`, `/profile[/edit]`, `/leaderboard`, `/history`, `/pro`,
`/friends`, `/friends/{uuid}`, `/battle/{uuid}`, `/result/{uuid}`. Неизвестные файлы возвращают 404; `/api`, `/ws`,
`/media`, `/v3` и Swagger исключены из frontend security chain/fallback. API сохраняет
JSON 401/404 и JWT-проверки. Native STOMP `/ws/v1/events`, JWT в CONNECT, персональные
подписки, heartbeat и запрет клиентского SEND остаются прежними. При HTTPS клиент
выбирает `wss`; изображения загружаются с `/media/questions/...` того же origin.

JVM CMD: heap 64–224 МБ, metaspace до 128 МБ, code cache до 48 МБ, direct buffers
до 32 МБ, stack 512 КБ, 2 доступных процессора; Tomcat 4–40 потоков. Это оставляет
часть 512 МБ для native расходов, дополнительных потоков и библиотек; суммы лимитов
не являются гарантией RSS. Java получает SIGTERM напрямую; graceful shutdown —
10 секунд на фазу (почтовая очередь имеет собственные 5 секунд). Не добавляйте
непроверенные `JAVA_TOOL_OPTIONS` поверх этих настроек.

### Локальный `.env.heroku` и Config Vars

Подготовлен отдельный **игнорируемый** корневой `.env.heroku`. Исходный `.env`
остаётся конфигурацией локального Compose. В новый файл перенесены только подходящие
JWT, Stripe TEST key/Price IDs и игровые настройки. Ни локальный пароль БД, ни порты
Compose, ни Docker DNS туда не переносятся. Для повторного создания при отсутствии
файла: `./backend/scripts/Initialize-HerokuEnv.ps1`. Скрипт существующий файл не
перезаписывает и значения не печатает. Не передавайте файл в frontend/build args.

Публичный домен в локальной конфигурации не найден. Возьмите **реальный HTTPS origin**
из Heroku app → Settings → Domains and certificates / Open app. В таблице `PUBLIC_ORIGIN`
означает этот адрес без завершающего `/`, это обозначение, а не дополнительный Config Var.
Не выводите домен из имени app: Heroku может использовать суффикс в hostname.

| Config Var | Значение / источник |
| --- | --- |
| `SPRING_PROFILES_ACTIVE` | `heroku` |
| `DATABASE_URL` | Создаётся подключённым Heroku Postgres, вручную не копировать/не заменять |
| `PORT` | Выдаёт платформа каждому dyno; вручную не задавать |
| `JWT_SECRET` | Уже перенесён из локального `.env`, Base64 минимум 32 случайных байта |
| `JWT_ISSUER` | Перенесён; default `skillbattles` |
| `JWT_ACCESS_TTL`, `JWT_REFRESH_TTL` | Перенесены; defaults `PT15M`, `P7D` |
| `BILLING_MODE` | `TEST` |
| `STRIPE_SECRET_KEY` | Существующий TEST key из `.env`; никогда не передавать браузеру |
| `STRIPE_PRICE_PRO_MONTHLY`, `STRIPE_PRICE_PRO_ANNUAL` | Существующие TEST Price IDs того же Stripe account/sandbox |
| `STRIPE_WEBHOOK_SECRET` | **Неизвестен**: signing secret нового TEST endpoint в Stripe Workbench |
| `BILLING_SUCCESS_URL` | **Заполнить**: `PUBLIC_ORIGIN/billing/return?success=true` |
| `BILLING_CANCEL_URL` | **Заполнить**: `PUBLIC_ORIGIN/billing/return?success=false` |
| `BILLING_PORTAL_RETURN_URL` | **Заполнить**: `PUBLIC_ORIGIN/pro` |
| `PASSWORD_RESET_BASE_URL` | **Заполнить**: `PUBLIC_ORIGIN/auth/reset` |
| `PASSWORD_RESET_TTL` | Перенесён; поддерживаемое значение `PT20M` |
| `SMTP_HOST`, `SMTP_PORT` | **Неизвестны**: внешний SMTP host и порт из настроек провайдера, не mailhog/localhost |
| `SMTP_USERNAME`, `SMTP_PASSWORD` | **Неизвестны**: учётные данные провайдера |
| `SMTP_AUTH`, `SMTP_STARTTLS` | **Уточнить у провайдера**: обычно требуются auth/STARTTLS, не копировать локальные флаги вслепую |
| `MAIL_FROM` | **Неизвестен**: подтверждённый отправитель SMTP-провайдера |
| `SEASON_SCAN_MS`, `SEASON_SCHEDULING_ENABLED` | Перенесены; defaults `60000`, `true` |
| `MATCHMAKING_SEARCH_SECONDS`, `PRIVATE_DUEL_SECONDS` | Перенесены; defaults `90`, `600` |
| `READY_TIMEOUT_SECONDS`, `COUNTDOWN_SECONDS`, `REVEAL_SECONDS` | Перенесены; defaults `30`, `3`, `5` |
| `RECONNECT_GRACE_SECONDS`, `QUESTION_HISTORY_BATTLES` | Перенесены; defaults `30`, `5` |

`DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, `POSTGRES_*`, `SERVER_PORT`, `BACKEND_PORT`,
`FRONTEND_*`, `COMPOSE_PROJECT_NAME`, `API_BASE_URL`, `EVENTS_URL` не переносите в Config Vars.
Forwarded headers, Hikari и JVM уже настроены в профиле/образе.

Для переноса откройте `.env.heroku` **в локальном редакторе**, затем Heroku →
Settings → Reveal Config Vars. Перенесите каждую нужную пару отдельно, убирая
внешние кавычки формата dotenv (в UI значение вводится без них). Не копируйте
комментарии, пустые неизвестные поля и закомментированные `SMTP_*`; не меняйте
`DATABASE_URL`, не создавайте `PORT`. Не используйте shell history, скриншоты,
`heroku config` или вывод файла для пересылки секретов. После заполнения SMTP
задайте порт и оба флага по документации выбранного провайдера.

Без webhook/return URLs billing сохраняет `BILLING_UNAVAILABLE`, Free-сценарии
работают. В Stripe **TEST** Workbench создайте destination
`PUBLIC_ORIGIN/api/v1/subscriptions/webhook` и подпишите события
`checkout.session.completed`, `checkout.session.async_payment_succeeded`, `customer.subscription.created`,
`customer.subscription.updated`, `customer.subscription.deleted`,
`invoice.paid`, `invoice.payment_failed` (сверьте обработчик при дальнейших изменениях).
Скопируйте **его** signing secret в `STRIPE_WEBHOOK_SECRET`; локальный listener
имеет другой secret. Подпись обязательна; возврат на success URL сам Pro не выдаёт.
Включите TEST Customer Portal для того же account. Без SMTP password reset
возвращает предусмотренный `EMAIL_SERVICE_UNAVAILABLE`, токен клиенту не раскрывается.
Реальные Stripe Checkout → webhook → Pro и доставка письма требуют отдельных
проверок после заполнения внешней конфигурации.

### Порядок первого ручного деплоя

1. Проверьте личный Heroku account → Billing/Credits и письмо о подключении
   [Heroku for GitHub Students](https://www.heroku.com/students/). Программа описывает
   кредит $13/месяц на 24 месяца; подключённый GitHub сам по себе кредит не подтверждает.
   Проверьте текущие цены Basic и Essential-0 в Dashboard перед созданием ресурсов,
   доступный кредит, дату окончания и другие расходы аккаунта.
2. После локальной проверки самостоятельно отправьте в `develop`: `Dockerfile.heroku`,
   `heroku.yml`, `.dockerignore`, `.gitignore`, README, новые Heroku Java/config/tests,
   скрипты `Initialize-HerokuEnv.ps1`, `verify_heroku.py`, изменение `verify_compose.py`,
   и перенос V13 из main в test resources. Удаление старого пути V13 должно попасть
   в тот же commit. `.env`, `.env.heroku`, `.cache`, TLS keys, target и локальные
   спецификации не отправляйте. Текущая рабочая ветка автоматически не меняется.
3. В Heroku CLI выполните следующие команды **самостоятельно**. Создание Postgres
   платное; сначала проверьте, что нужный add-on ещё не подключён.

   ```sh
   heroku login
   heroku addons --app skill-battles
   heroku addons:create heroku-postgresql:essential-0 --app skill-battles
   heroku pg:wait --app skill-battles
   heroku stack:set container --app skill-battles
   heroku features:disable preboot --app skill-battles
   ```

4. Заполните Config Vars по таблице. В Deploy выберите GitHub repository
   `yakupovdev/SkillBattles`, ветку `develop`; **Manual deploy → Deploy Branch**.
   Automatic Deploys не включайте. Сборка идёт в корневом context по `heroku.yml`;
   `heroku-24` переключается на `container`, Java buildpack здесь не используется.
5. После появления web process в Resources выберите **Basic**, количество **1**,
   подтвердите либо выполните:

   ```sh
   heroku ps:type web=basic --app skill-battles
   heroku ps:scale web=1 --app skill-battles
   heroku ps --app skill-battles
   heroku logs --tail --app skill-battles
   heroku open --app skill-battles
   ```

6. Проверьте HTTPS сайт, прямые `/auth/reset` и `/billing/return`, Swagger
   `/swagger-ui/index.html`, `/v3/api-docs`, регистрацию/login/refresh, два браузера
   и WebSocket `wss` `/ws/v1/events` с CONNECT JWT. Проверьте изображения, REST ACK
   стикеров, друзей и приглашения в комнаты. Смотрите RAM/CPU
   в Metrics (если доступны для плана), `heroku logs` на R10/R14/R15, время старта,
   `heroku pg:info --app skill-battles` на connections. Не публикуйте сырые логи
   и вывод Config Vars.

Не включайте Preboot, autoscaling и второй backend: состояние очередей/комнат,
presence, непринятых приглашений, cooldown/receipts стикеров хранится в памяти.
Ежедневный restart Cedar его теряет. Реальный recovery отменяет **все** сохранённые
нетерминальные батлы с `SERVER_INTERRUPTION`, без изменения Elo; уже начатая
ranked quota остаётся списанной. Активный матч не продолжается после рестарта.
Аккаунты, завершённые результаты/review и статистика остаются в PostgreSQL.

### Воспроизводимые локальные проверки Heroku

Из корня (Docker Desktop Linux containers, Python 3, Node.js 22+, OpenSSL; на Windows
скрипт также находит OpenSSL из Git):

```sh
docker build --platform linux/amd64 -f Dockerfile.heroku -t skillbattles-heroku-check .
python backend/scripts/verify_heroku.py
docker build -f Dockerfile.heroku --target frontend-source -t skillbattles-heroku-frontend-check .
docker run --rm skillbattles-heroku-frontend-check flutter analyze
docker run --rm skillbattles-heroku-frontend-check flutter test --dart-define=OUT=/tmp
```

Из `backend/`: `./mvnw -B -ntp clean verify` (Windows `.\mvnw.cmd`). `clean` убирает
старую V13 из target/classes. Контейнерная проверка использует свою tmpfs PostgreSQL
с TLS, пароль с URL-encoded символами, случайный PORT и лимит web 512 МБ без swap;
проверяет чистую/сохранённую БД, auth, SPA/assets, реальные REST/STOMP, изображения,
стикеры, recovery, небольшой HTTP load и SIGTERM. Фикстуры меняются только в этой
БД. Секреты пользовательского `.env` не читаются. Отчёт без секретов — локальный
`backend/.cache/heroku-check-report.json`; локальная скорость CPU/диска не гарантирует
тот же старт и RAM на Heroku. Cedar требует bind к PORT в пределах
[60 секунд](https://devcenter.heroku.com/articles/dyno-startup-behavior).

Проверено локально 2026-11-15:

Эти измерения относятся к версии до rebase на `develop` с друзьями и новым frontend;
для объединённой версии время старта, память и Flutter-проверки нужно измерить заново.

- Единый linux/amd64 образ собран; чистая TLS PostgreSQL: 13 миграций V1–V12 + V14,
  239 активных вопросов / 261 seed-ревизия, демоаккаунтов нет.
- Готовность вместе с первым OpenAPI: **6,78 с** на чистой БД, **6,81 / 6,91 с**
  на сохранённой БД. Лимит контейнера **512 МиБ**, swap отключён.
- Реальные auth/REST/native STOMP, два игрока, Free/Pro gates, все 23 PNG,
  стикеры, SPA/MIME/COOP/COEP, JSON 401/404 и recovery после restart прошли.
- Короткая нагрузка: **240 HTTP-запросов**, параллельность **8**, **0,14 с**, без ошибок.
  Пиковый выборочный JVM RSS **340,3 МиБ**, cgroup memory.peak **327,3 МиБ**.
  Метрики имеют разный учёт shared pages; это локальный smoke test, не оценка
  максимальной ёмкости Heroku. OOM не было, увеличивать dyno для этого сценария не потребовалось.
- SIGTERM: **0,58 с**, выполнены shutdown hooks / graceful shutdown, штатный HotSpot
  exit code **143**. Никакого SIGKILL или shell-посредника.
- Java 21 Maven verify: **430 тестов**, 0 ошибок/пропусков; после последней правки
  web/CLI-конфигурации повторно прошли 6 Heroku-тестов с Maven verify.
  Существующие Dockerfile и изолированный HTTPS Compose REST/STOMP/restart прошли.
- Flutter release и analyze прошли; **287 тестов прошли, 8 упали** на устаревших
  экранных/mock ожиданиях. Текущая DI не подключает старый mock backend; отдельный
  запуск с `DEV_MOCKS=true` дал те же ошибки. Клиентский код не изменён.
- Docker context исключает env/локальные ключи/служебные файлы, необходимые assets
  включены; проверка значений локальных секретов в изменениях и `git diff --check` прошли.

Провайдерские Stripe/SMTP сценарии и работа именно в инфраструктуре Heroku ещё не
проверены: нужны перечисленные выше внешние настройки и первый ручной деплой.
