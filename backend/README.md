# SkillBattles — backend v0.3

Реализованы этапы A–E и 54 продуктовых REST-операции контракта v0.3, включая приглашения на реванш,
друзей, их базовые профили, приглашения в существующие комнаты и временные стикеры. Вместе с публичными
GET/HEAD иллюстраций это 56 HTTP-операций в полном OpenAPI. Generated Swagger
имеет версию `0.3.0` и строится из действующих controllers/DTO. Контрактная
проверка сопоставляет маршруты, успешные статусы, request/response-поля,
типы и единый ErrorResponse. Локальные спецификации остаются игнорируемыми Git.
Stripe и покупка Pro удалены из backend. При регистрации пользователь получает
бессрочный Pro (`isPro=true`); оплата и внешние ключи не требуются.

Текущий runtime применяет V1–V12, V14 и V15, без отдельного baseline.
Миграция демо-пользователей V13 удалена, новые установки не создают аккаунты.
`V12` содержит 239 вопросов (удалённый `SAT_MATH:15ce8207` не восстанавливается).
[QUESTION_BANK.md](QUESTION_BANK.md)
описывает происхождение контента, 23 согласованных преобразования в A–D и
проверки сохранности данных. `V14` добавляет nullable `image_key` и 22 ревизии 2
с изображениями: 239 активных логических вопросов, 261 сохранённая seed-ревизия.
Предыдущие ревизии и старые JSONB батлов не переписываются.

## Друзья и приглашения в комнату

`V15__add_friends.sql` добавляет nullable уникальный `users.friend_code` и
постоянный aggregate `friend_relations`. Старые миграции не меняются, seed-друзей
нет. Новая регистрация получает SecureRandom-код из 12 символов; существующий
пользователь — при первом `GET /api/v1/users/me/friend-code`. Код стабилен,
глобально уникален и не переиспользуется после soft delete. Коллизия повторяет
целую транзакцию, включая регистрацию, без частичных аккаунтов/рейтингов/токенов.
SQL diagnostics с кодами подавлены; обработчик пишет только класс исключения.

Все новые REST-операции требуют access JWT и имеют `Cache-Control: no-store`.
`POST /friend-requests {friendCode}` создаёт запрос, а не дружбу. Получатель
явно принимает/отклоняет; встречный запрос не принимается автоматически.
Повторный собственный PENDING возвращает 200, новый — 201. Списки друзей и
INCOMING/OUTGOING запросов имеют page/size; терминальные запросы читаются по id.
`DELETE /friends/{friendId}` доступен обеим сторонам; friendId — UUID другого
пользователя, а не relationshipId. Новый запрос после завершения получает новый id.

`GET /friends/{friendId}` возвращает только PublicPlayer, friendsSince и базовые
дисциплинарные статистики. Набор полей одинаков для всех Free/Pro комбинаций;
email, возраст, friendCode, entitlements, история и аналитика не возвращаются.
Расчёты используют текущие rating/season/rank правила и StatisticsCalculator;
проценты/время без данных — null. После удаления дружбы профиль недоступен.

Хост сначала создаёт обычную комнату `POST /duels`, затем отправляет
`POST /duels/{duelId}/invitations {friendId,requestId}`. Принимается именно эта
комната через общий join core; создаётся один PRIVATE battle, затем оба проходят
обычный Ready. До принятия invitee не получает room code или доступ GET комнаты.
Получение инвайта не занимает получателя и не отменяет его текущую активность.
Busy/content failures сохраняют PENDING и чужие reservations.

TTL приглашения — min(60 секунд, исходный срок комнаты), без продления при retry.
Одна PENDING цель на комнату; requestId receipts привязаны к host/room/recipient,
включая новые requestId, ссылающиеся на тот же PENDING. Вход по коду приглашённого
даёт ACCEPTED для того же battleId; вход другого — CANCELLED/DUEL_FILLED без
раскрытия чужого battleId. Cancel/expiry комнаты и удаление дружбы согласованы с
приглашениями; уже принятый батл не отменяется удалением дружбы.

FRIENDSHIP_CHANGED и DUEL_INVITATION_CHANGED используют тот же STOMP envelope,
`/ws/v1/events` и `/user/queue/events`. Только after commit, оба разрешённых
участника и их текущие сессии; unchanged retries не публикуются. Новые GET
восстанавливают pending lists/известный ресурс. Друзья и запросы сохраняются в БД;
комнаты, инвайты и receipts — в существующем staged registry одного процесса и
теряются при backend restart. Принятый батл восстанавливается через activity/snapshot.

Лимиты существующего RequestRateLimiter: 20 попыток friend-code запросов и 30
новых room-invites за 20 минут на пользователя, разные purpose keys. Retry инвайта
не расходует new-send limit. Cooldown пары/того же room-target после завершения —
60 секунд; 429 RATE_LIMITED с Retry-After. Accept/decline/remove/чтение не
блокируются send limiter. Отдельного брокера, inbox, WS или внешней интеграции нет.

Полные маршруты, примеры и recovery: [FRIENDS_HANDOFF.md](FRIENDS_HANDOFF.md).

## Иллюстрации вопросов

23 оригинальных PNG находятся в `src/main/resources/question-images/{disciplineCode}/{sourceId}/{sha256}.png`
и включаются Maven в JAR, затем в Docker image. Никаких дополнительных сервисов,
volumes, ENV или ручного копирования после запуска не требуется. 22 привязки готовы;
изображение `SAT_MATH:15ce8207` сохранено без привязки к удалённому вопросу.

`QuestionResponse` и `ReviewQuestionResponse` содержат обязательное nullable
`imageUrl`, например `/media/questions/SAT_MATH/3f5a3602/224eefc655e44ddac7e07d499e9fad2ba90e28bd8db675e8cd15b31156b7a203.png`.
Это origin-relative URL из замороженной ревизии; без картинки возвращается `null`.
REST и `BATTLE_CHANGED` используют один снимок, включая overtime. Правильные ответы,
объяснения и доступ к истории продолжают определяться Free/Pro-политикой.

Публичные GET/HEAD `/media/questions/{disciplineCode}/{sourceId}/{sha256}.png`
возвращают PNG с `nosniff` и `Cache-Control: public, max-age=31536000, immutable`
(порядок директив не значим). HEAD не имеет тела; неизвестный ключ даёт 404,
GET — существующий ErrorResponse, HEAD — без тела. Поддерживается Last-Modified/304.
Nginx проксирует media на том же HTTPS origin с сохранением COOP/COEP.

Чтобы добавить изображение, сохраните новые оригинальные байты под новым SHA-256
ключом и создайте следующую ревизию вопроса через новую миграцию или JSON-импорт.
Optional `imageKey` в импорте принимает только packaged PNG с правильным externalKey;
старые JSON без поля валидны. Не заменяйте файл по старому ключу и сохраняйте все
ранее опубликованные assets для истории. Повтор одной ревизии идемпотентен;
изменение содержимого или imageKey под прежней версией — revision conflict.

Обычный запуск из корня: `docker compose up -d --build`. Для существующей БД
с ранее применённым другим V12 необходима отдельная проверка Flyway checksum:
в этой задаче по подтверждению владельца исправлена оставшаяся проверка количества
240 → 239. Автоматический repair/сброс рабочей БД не выполняется.
Контракт и передача фронтендеру: [QUESTION_IMAGES_HANDOFF.md](QUESTION_IMAGES_HANDOFF.md).

Java 21, Spring Boot 3.5.16, MVC/JPA/Security Resource Server, PostgreSQL 17.12,
Flyway, MapStruct 1.6.3, Lombok, Validation, springdoc 2.10.0. Maven Wrapper 3.3.4
запускает Maven 3.9.12. Runtime не требует Node/Python, Redis или внешнего брокера.

## Что работает сейчас

- JWT access/refresh, ротация refresh, logout и изоляция токенов по назначению.
- Возрастная проверка регистрации по ET, профиль PATCH и одноразовый password reset.
- Полная базовая статистика, Pro topicStats/ratingHistory и сезонный leaderboard.
- Pro mistakesOnly, приватный реванш и идемпотентные жалобы.
- Динамический каталог активных дисциплин из PostgreSQL: `SAT_MATH`, `SAT_RW`.
  Код дисциплины — строка, не Java/frontend enum. Вопросы — SINGLE_CHOICE, 4 опции.
- `mode=RANKED|PRIVATE` обозначает соревнование, `format=STANDARD` — формат.
- `GET /api/v1/battle-modes`: имена, формат, тайминги сложностей, пять основных
  раундов, сетки и обеспеченность контентом с отдельным MEDIUM-резервом.
- `GET /api/v1/ranks`: все 27 рангов Bronze I → Legend. Рейтинг 1000 — SILVER_I,
  Legend от 3200 без верхней границы. Snapshot/result используют коды справочника.
- Бессрочный Pro при регистрации, серверные entitlements, Free quota
  и history/answer access, персональный ACCOUNT_CHANGED, daily/weekly streak.
- Пять раундов, боевой streak, overtime, индивидуальный Elo K, lifetime-калибровка
  и квартальные сезоны ET с архивом пиков/итогов.
- Ranked matchmaking, private code duels, единая activity, готовность, таймеры,
  surrender/технические исходы, история, review, native STOMP и reconnect.
- Идемпотентность ответов, сериализация переходов, атомарность результата/Elo,
  after-commit события, rollback и сокрытие ответов до REVEAL сохранены.

## Отдельная база для обновления

Runtime применяет V1–V12, V14 и V15; миграция демо-аккаунтов V13 удалена. Исторические V1–V11 не переписаны;
дополнительного B11 нет. После всей цепочки остаются 14 итоговых таблиц, без
practice_sessions и старых subject-колонок. Для обновления существующей V11-БД
не нужны `repair`, ручное изменение history или удаление данных.

Далее `V12__seed_sat_question_bank.sql` содержит 239 вопросов и дополняет topics
двух дисциплин. Повторный запуск не меняет seed-вопросы;
коллизия другой ревизии вопроса останавливает миграцию вместо перезаписи.
Ни runtime, ни тестовая цепочка миграций больше не создают демо-пользователей.
Для старой локальной БД с применённой V13 используйте отдельную чистую БД:
автоматический repair/удаление не выполняется. Heroku-образ, Config Vars и команды
первого деплоя описаны в [корневом README](../README.md#первый-деплой-на-heroku-через-github).

Историческая цепочка: V9 добавляет данные age-screen, reset hashes и ratingReachedAt;
V10 сохранена без изменения checksum; V11 удаляет только устаревшую таблицу
practice_sessions. Таблица question_reports и остальные данные сохраняются. V8 добавляет подписки/receipt, quota ledger, qualifying days
и индексы истории по finishedAt. V7 добавляет калибровку, пики и архивы сезонов. V5 создаёт каталоги дисциплин/рангов, V6 переводит ключи на
`discipline_code`, добавляет topicCode и формат. V6 **отказывается** мигрировать
базу с вопросами или батлами v0.2. Совместимый адаптер старых snapshots не входит
в этап A; миграция ничего не удаляет. Используйте отдельную чистую dev/test БД,
не удаляйте существующую БД/volume и не редактируйте применённые миграции.

## Единая локальная конфигурация

Все способы запуска используют **только корневой `.env`**. Общий запуск поднимает
PostgreSQL, backend и Flutter Web frontend с nginx proxy; инструкция — в корневом
README. `.env.example` содержит все используемые приложением ENV и
пояснения; действующих секретов в нём нет. Первичная подготовка из корня:

```powershell
.\backend\scripts\Initialize-LocalEnv.ps1
```

Скрипт сохраняет имеющиеся значения и генерирует только отсутствующие пароль
PostgreSQL/JWT secret криптографическим RNG, без вывода значений. JWT_SECRET —
Base64 минимум 32 случайных байт. Внешние ключи самостоятельно не генерируются.
Не меняйте пароль уже инициализированного PostgreSQL volume простым редактированием
ENV: это не изменяет пароль роли в БД. Данные/volumes не удаляйте.

По умолчанию COMPOSE_PROJECT_NAME=`skillbattles-local`, отдельная БД
`skillbattles_v03`, PostgreSQL публикуется на 127.0.0.1:55432, backend —
127.0.0.1:8080, frontend — `0.0.0.0:8443` (HTTPS, `FRONTEND_HTTPS_PORT`),
HTTP `0.0.0.0:8081` (`FRONTEND_PORT`) перенаправляет на HTTPS. Подготовку
локального CA и установку доверия на устройствах см. в корневом README.
Браузер открывает https://localhost:8443; Swagger доступен на этом же origin по
`/swagger-ui/index.html`, OpenAPI — `/v3/api-docs`. Backend доверяет forwarded
headers от локального nginx; proxy перезаписывает переданные клиентом заголовки.
Compose автоматически читает корневой `.env` из корня проекта.
Не передавайте альтернативный ENV-файл и не печатайте раскрытый `compose config`:

```powershell
docker compose config --quiet
docker compose up -d --build
docker compose ps
docker compose logs backend
docker compose down
```

Не добавляйте `-v`: dev-данные должны сохраняться. Compose передаёт приложению
явно перечисленные DB/JWT/игровые ENV; имя БД и credentials берутся из
POSTGRES_*. В контейнере DB_URL указывает на `postgres:5432`, SERVER_PORT=8080,
BACKEND_PORT задаёт опубликованный порт. Все процессы/БД хранят время в UTC.

Spring Boot сам `.env` не читает. Для JVM используется безопасный parser:
только KEY=value, комментарии, кавычки и ссылки `${NAME}` внутри этого файла.
Одинарные кавычки сохраняют `$`/`#` буквально; командная подстановка, dot-source
ENV и Invoke-Expression не используются. Ссылки на неизвестные ключи/циклы,
повторы ключей и некорректные строки отклоняются до установки environment.
Для локальной Java 21 задайте JAVA_HOME, затем **из корня**:

```powershell
docker compose up -d postgres
.\backend\scripts\Start-Backend.ps1 -Action Check
.\backend\scripts\Start-Backend.ps1
# Или уже собранный JAR:
.\backend\scripts\Start-Backend.ps1 -Action Jar
```

Не запускайте контейнер backend и JVM одновременно на одном порту/БД.
Host launcher формирует DB_URL/DB_USERNAME/DB_PASSWORD из POSTGRES_* (localhost
и опубликованный порт), SERVER_PORT — из BACKEND_PORT. JWT_SECRET нужен
для подписи HS256. JWT_ISSUER=`skillbattles`, JWT_ACCESS_TTL=`PT15M` (максимум
15 минут), JWT_REFRESH_TTL=`P7D`. Java 21 задаётся через JAVA_HOME.
Swagger: `http://localhost:8080/swagger-ui.html`, JSON `/v3/api-docs`, без авторизации.
REST: `http://localhost:8080/api/v1`, WebSocket: `ws://localhost:8080/ws/v1/events`.
Frontend получает только явно выбранные публичные URLs, а не серверный ENV;
API/WebSocket должны идти через same-origin dev proxy с поддержкой Upgrade.
Wildcard CORS/origins не добавлены. SMTP/reset ENV описаны ниже.

## Каталог, сетки и конфигурация

Таблица `disciplines` хранит code, displayName, description, active,
displayOrder, STANDARD/SINGLE_CHOICE, optionsCount=4, questionCount=5,
baseQuestionSeconds, overtimeSeconds, JSONB timings/schedules/topics.
Определение неизвестного или неактивного кода не даёт начать матч:
409 DISCIPLINE_UNAVAILABLE. Старые MATH/ENGLISH не являются алиасами новых кодов.
Каталог исключает неактивные дисциплины. Неизвестный history-filter — 400.

| Дисциплина | Base | EASY ×0.75 | MEDIUM ×1 | HARD ×1.5 | Overtime |
|---|---:|---:|---:|---:|---:|
| SAT_MATH | 60s | 45s | 60s | 90s | 30s |
| SAT_RW | 48s | 36s | 48s | 72s | 24s |

Базы в каталоге и scoring: EASY=800, MEDIUM=1000, HARD=1200. Сетка по **меньшему** замороженному рейтингу пары:

| Рейтинг | Основные раунды |
|---|---|
| 0–999 | E,E,E,M,M |
| 1000–1899 | E,E,M,M,H |
| 1900–2799 | E,M,M,H,H |
| 2800+ | M,M,H,H,H |

При создании фиксируются 5 вопросов по сетке, индивидуальные лимиты времени,
basePoints, варианты, контент/объяснения, сезон, предматчевые рейтинги/калибровка
и каталог рангов. Отдельно сохраняется отличный от них MEDIUM-резерв.
Он раскрывается только при ничьей после пяти REVEAL; до открытия не попадает
в просмотренные вопросы/history review.
Изменение конфигурации не пересчитывает созданный матч.

Availability каждой сетки проверяет необходимое число вопросов каждой сложности
**плюс один MEDIUM**. Общий contentAvailable учитывает сетки, возможные при
меньшем рейтинге пары для данного игрока. При формировании реальной пары набор
перепроверяется. CONTENT_UNAVAILABLE не создаёт частичный батл/резервацию.

Добавление дисциплины того же формата — изменение данных, не enum/renderer:
создайте корректную строку `disciplines` со стабильным уникальным code,
метаданными/таймингами/сетками, первоначально active=false; импортируйте банк,
затем включите active. Поддерживаются только STANDARD/SINGLE_CHOICE/4 опции.
Начальная загрузка может использовать конфигурацию существующей дисциплины
как шаблон. Новый формат ответа требует отдельной задачи.

Рейтинги активных дисциплин инициализируются значением 1000 через идемпотентный
INSERT ON CONFLICT DO NOTHING. Startup backfill обрабатывает активных пользователей;
login/refresh, catalogue/statistics и создание батла подхватывают недостающие
рейтинги при использовании. После включения дисциплины перезапуск выполняет
полный backfill; повторная инициализация не сбрасывает Elo. Деактивация не удаляет
старые рейтинги/историю. Коды каталога стабильны и не переиспользуются.

Глобальные `app.battle`: ready-timeout-seconds=30, countdown-seconds=3,
reveal-seconds=5, reconnect-grace-seconds=30, question-history-battles=5.
Прежние app.battle.math/english и MATH/ENGLISH question count/time ENV удалены:
дисциплины и сложности настраиваются данными каталога.

## Локальный JSON-импорт

Только локальный профиль `question-import`, без HTTP upload и без автоматического
импорта при старте сервера. **Из корня**, с тем же `.env`:

```powershell
.\backend\scripts\Start-Backend.ps1 -Action Verify
.\backend\scripts\Start-Backend.ps1 -Action ImportQuestions -QuestionsFile C:/data/questions.json
.\backend\scripts\Start-Backend.ps1 -Action ImportQuestions -QuestionsFile C:/data/questions.json -Apply
```

Сначала dry-run, затем явный apply. В Linux используйте `"$JAVA_HOME/bin/java"`.
Схема — непустой JSON-массив:

```json
[{
  "externalKey": "unique-bank-key",
  "contentVersion": 1,
  "disciplineCode": "SAT_MATH",
  "topicCode": "LINEAR_EQUATIONS",
  "topicName": "Linear equations",
  "difficulty": "EASY",
  "prompt": "English question supplied by the content owner",
  "options": [{"key":"A","text":"First"},{"key":"B","text":"Second"},{"key":"C","text":"Third"},{"key":"D","text":"Fourth"}],
  "correctOptionKey": "A",
  "explanation": "Explanation supplied by the content owner"
}]
```

Это пример схемы, не production-контент. Допустимы EASY/MEDIUM/HARD; ровно 4
различных A/B/C/D, один правильный ключ. disciplineCode/topicCode соответствуют
`^[A-Z][A-Z0-9_]{1,63}$`; дисциплина должна существовать, но может быть неактивной
для подготовки банка. topicCode имеет одно topicName в пределах batch/дисциплины.
Metadata тем агрегируется в каталоге в общей транзакции с импортом.

Неизвестные поля/сложности, повторные JSON-ключи и неявные numeric/string coercions
отвергаются. Одинаковая externalKey/contentVersion идемпотентна; изменение
существующей ревизии — QUESTION_REVISION_CONFLICT, исправление требует новой
contentVersion. Только одна ревизия externalKey активна, включая разные сложности.
Импорты и подбор всех сложностей одного батла используют общую PostgreSQL advisory
lock: смена сложности новой ревизии во время подбора не создаёт повтор externalKey.
Ошибка/rollback не оставляют
частичные вопросы или темы. Dry-run не меняет вопросы/темы, но Flyway обновляет схему.

Анти-повторы применяются отдельно к требуемым сложностям: последние 5 начавшихся
батлов каждого участника по disciplineCode, только реально открытые раунды.
Сначала вопросы, новые обоим, затем oldest latest-show-to-either, равные давности
случайны. Ревизии объединяются по externalKey. Малый достаточный банк использует
fallback; история не создаёт ложный CONTENT_UNAVAILABLE.

## REST, realtime и гарантии

Queue/duel create принимает `{"disciplineCode":"SAT_MATH","format":"STANDARD"}`.
Фильтры истории используют disciplineCode/mode. Вопросы содержат topicCode,
topicName, difficulty; snapshot player — rankCode, statistics — disciplines с
rankCode/rankName. Result rankBefore/rankAfter — коды из справочника.
Ошибки HTTP/STOMP: code/message/fieldErrors/resetsAt (пока resetsAt=null).
Access JWT требуется для business API и GET /ranks; refresh — только refresh/logout.

Native WebSocket `/ws/v1/events`, STOMP 1.2 без SockJS; handshake same-origin,
токен только в CONNECT `Authorization: Bearer <accessToken>`. После CONNECTED:
SUBSCRIBE `destination:/user/queue/events`, `id:events`, `ack:auto`.
Клиентские SEND, чужие destinations и прямые /topic/**, /queue/** запрещены.
HTTP handshake не даёт доступа к подпискам. Cookie-auth/Basic не используются;
token-only ChannelInterceptor не включает message-level CSRF, origin checks сохранены.

`heart-beat:5000,5000`; детектирование потери около 10 секунд, grace 30 секунд,
таймеры не останавливаются. Presence возникает после CONNECT+SUBSCRIBE.
Новая gameplay-сессия заменяет старую; поздний disconnect не отключает замену.
На expiry access соединение закрывается, refresh по REST и reconnect обязательны.

Личные QUEUE_CHANGED/PRIVATE_DUEL_CHANGED/BATTLE_CHANGED после commit:
`{eventId,type,resourceId,version,occurredAt,data}`. Snapshot персональный,
ответ соперника/правильность/текущие очки скрыты до REVEAL. События недолговечны:
подписаться → GET /users/me/activity → соответствующий snapshot → merge по version.
Все действия — REST. Для frontend нужен same-origin proxy /api/** и WS Upgrade /ws/**.

Один процесс. Registry очередей/комнат теряется после restart; незавершённые
батлы отменяются SERVER_INTERRUPTION без Elo. Терминальные snapshots/result/review
сохраняются в PostgreSQL и не меняются после обновления источника вопроса.
Pessimistic battle lock, account-activity lock до commit/rollback, stable rating
lock order и settledAt продолжают защищать от двойного ответа/матча/Elo.

## Очки, overtime и калибровка

Правильный обычный ответ: замороженная база сложности +
`floor(200 × clamp(deadlineMs-receivedAtMs,0,limitMs)/limitMs)` + streakBonus.
Для серии 1/2/3/4/5+ бонусы 0/100/150/200/300. Ошибка и timeout дают 0 и
сбрасывают серию. Это отдельная боевая серия; до REVEAL score/streak/correct
не меняются в персональном snapshot. На deadline ответ опоздал; время только серверное.

При равенстве после пяти раундов открывается сохранённый MEDIUM, number=6,
isOvertimeRound=true, questionCount остаётся 5. Используются QUESTION/REVEAL и
отдельный overtimeSeconds. Ждём обоих ответов или deadline: один правильный
выигрывает, при двух правильных решает меньший elapsedMs; равенство времени
или отсутствие правильных — DRAW/NORMAL. Победитель получает только один
tieBreakPoint, reason=OVERTIME_WIN. База/скорость/streak overtime равны 0;
боевая серия в нём не меняется. Surrender/disconnect завершают матч по forfeit,
включая completed=false для незавершённого раунда, без подделки очков.

Первые пять FINISHED ranked по дисциплине: индивидуальный K=64, шестой и далее
K=32. DRAW/SURRENDER/DISCONNECT учитываются; PRIVATE/CANCELLED — K=0, без расхода
калибровки. HALF_UP отдельно каждому, after=max(0,before+delta), сумма дельт может
быть ненулевой. Result хранит фактические K/before/after/delta/remaining, ranks,
rulesVersion=0.3 и старый seasonId. Settlement и lifetime-счётчик атомарны.

## Рейтинговые сезоны

Кварталы America/New_York: Fall Sep1, Winter Dec1, Spring Mar1, Summer Jun1.
WINTER_2026 начинается в декабре 2026. Границы — ET midnight, в API UTC с учётом DST.
GET /api/v1/seasons/current возвращает глобальный календарный сезон.
GET /api/v1/users/me/seasons?disciplineCode=SAT_MATH&page=0&size=20 возвращает
собственные завершённые сезоны (data/pagination, size≤100), новые сначала.

Рейтинг сбрасывается HALF_UP(1000 + 0.5 × (oldRating-1000)). Архив хранит неизменные
final/peak/rank и календарные границы; seasonPeak начинается с reset-рейтинга.
All-time peak не повышается искусственно сбросом, lifetime-калибровка сохраняется.

Сформированный ranked, включая ready check, удерживает замороженные рейтинг/сезон
до терминального исхода. При смене квартала statistics показывает
seasonRolloverPending=true для этой дисциплины; рейтинг матча не сбрасывается.
После settlement батл сохраняется, затем архив/rollover выполняются в той же
транзакции перед новым ranked. Result остаётся в старом сезоне с прежним after;
statistics уже может показывать новый сезон и reset. PRIVATE не задерживает rollover.
Ожидающая очередь обновляет рейтинг перед подбором. Пропущенные кварталы
закрываются по порядку, повторные/конкурентные вызовы не применяют reset повторно.

Переходы используют внедряемый Clock. Production scheduler проверяет аккаунты
раз в SEASON_SCAN_MS=60000; SEASON_SCHEDULING_ENABLED=true по умолчанию.
Проверка перед ranked и чтением catalogue/season/statistics работает независимо от scheduler.
Тесты отключают фоновый сезонный scan и явно двигают Clock. Redis/брокер не нужны.
Создание пары блокирует рейтинги обоих аккаунтов и фиксирует единый сезон,
чтобы переход квартала между подготовкой участников не смешивал рейтинги разных сезонов.

## Pro без оплаты

Новая регистрация создаёт постоянное право Pro в той же транзакции, что аккаунт,
рейтинги и токены. `isPro=true` возвращается в auth/profile и публичных карточках.
Pro включает безлимитные ranked-матчи, всю историю, правильные ответы, объяснения,
расширенную аналитику и фильтр ошибок. Срока окончания и платёжной активации нет.
Существующие аккаунты сохраняют свой `pro_active`; login/refresh не меняют его.

`GET /api/v1/subscriptions/me` (access JWT) сохранён для чтения прав:
`planCode=PRO`, `status=ACTIVE`, `billingMode=NONE`, оба `currentPeriod*` равны null,
`cancelAtPeriodEnd=false` у Pro. У существующего Free: `planCode=FREE`, `status=NONE`.
Форма ответа сохранена для потребителей account state.

Удалены операции:

| Метод и путь | Прежнее назначение |
| --- | --- |
| GET /api/v1/subscriptions/plans | Каталог Free/Pro тарифов и цен |
| POST /api/v1/subscriptions/checkout | Создание или повтор Stripe Checkout для покупки Pro |
| POST /api/v1/subscriptions/portal | Открытие Stripe Portal для управления оплатой/подпиской |
| POST /api/v1/subscriptions/webhook | Приём подписанных Stripe-событий и обновление оплаченного Pro |

SDK, интеграционные клиенты/обработчики, scheduler срока подписки, платёжные DTO,
настройки и скрипты Stripe удалены. Swagger больше не содержит эти операции и
`stripeSignature`. Старые DDL-миграции, включая V8, сохранены без изменения checksum;
неиспользуемые платёжные колонки/receipt-таблица не участвуют в работе приложения.
Удаление V13 не удаляет уже существующих пользователей из БД.

## Free quota, история и ответы

Пять неотменённых ranked starts за ET-день суммарно по дисциплинам.
PRIVATE безлимитен. Проверка перед очередью и атомарно перед первым QUESTION;
поиск/Ready не расходуют попытку. Ledger уникален по battle/user и учитывает
старты Pro. Статус подписок обоих игроков блокируется на время проверки/commit:
с downgrade нет окна гонки. Новый ET-день и expiry Pro проверяются заново.
Недостаток перед асинхронным стартом — CANCELLED/QUOTA_EXHAUSTED, без частичных
записей и Elo; оба аккаунта освобождаются. CANCELLED после старта возвращает
попытки один раз в ledger исходного дня, включая server interruption; surrender
и одиночный disconnect с поражением не возвращают. Overtime — часть того же старта.
429 DAILY_LIMIT_REACHED содержит resetsAt и Retry-After до следующего ET midnight,
включая DST (день может быть 23/25 часов). GET /users/me/limits — текущие права,
использовано/осталось; Pro remaining=null. Контент/presence проверяются отдельно.

Free history сначала выбирает 10 последних terminal батлов по finishedAt DESC,
id DESC, затем применяет filters/sort/page. historyLimit=10; у Pro null и вся
история. Прямые snapshot/result/review и повторный surrender для своего закрытого
батла — 403 HISTORY_ACCESS_REQUIRED; чужой —404. Текущий nonterminal доступен.
Покупка открывает старые данные, downgrade закрывает их снова, без удаления.
Базовые счётчики статистики используют всю историю. Чтение результатов не меняет Elo.

До REVEAL для всех скрыты правильность/очки текущего ответа и выбор соперника.
После REVEAL Free видит свой выбор и correct/points/time обоих, но
opponent selectedOptionId=null и correctOptionId=null. Pro видит оба выбора и
correctOptionId после закрытия раунда. Explanation отсутствует в live question/
reveal у всех; только terminal review отдаёт её Pro. Free review explanation и
correctOptionId — null. Правила одинаковы для overtime и неполного forfeit-раунда.
Все REST и личные STOMP projection строятся отдельно для получателя из новых DTO,
свежих entitlements и answerAccess, не из общего Pro snapshot. Ответы имеют
Cache-Control:no-store. Public isPro badge также вычисляется по текущим правам.

## Daily/weekly streak

Qualifying FINISHED определяется по finishedAt в America/New_York: normal,
overtime и draw — обоим; surrender/disconnect — только победителю.
PRIVATE учитывается, CANCELLED — никому. Уникальная запись user/ET-date не
дублируется при callback/retry; она сохраняется атомарно с финализацией.
Пропуск дня обрывает daily, yesterday сохраняет текущую серию до конца today.
Weekly — последовательные завершённые недели Пн–Вс с 4+ разными qualifying днями;
текущая неделя показывает отдельный прогресс 0..7/target4. Нет freezes/щитков.
Это общие streaks по дисциплинам, отдельно от combat streak и будущего win streak.
Statistics и AccountState показывают реальные значения, не имитацию аналитики.

## Возраст, профиль и восстановление пароля

Регистрация требует birthYear>=1900 и birthMonth=1..12. birthDay нужен только
в текущем ET-месяце 13-летия; переданный день всегда проверяется на существование
даты. В день 13-летия регистрация разрешена, младше 13 — 403 AGE_RESTRICTED,
будущая/несуществующая дата — 400 VALIDATION_ERROR. Верхнего возрастного запрета
нет. Данные рождения не входят в API-профиль, leaderboard или realtime. Один
age-screen не доказывает полного соответствия COPPA.

`PATCH /api/v1/users/me`: nickname и/или currentPassword+newPassword. Пустое
обновление, явные null, неполная пара, неизвестные поля/email отклоняются.
Nickname уникален среди активных аккаунтов без учёта регистра. Смена/reset пароля
отзывает все refresh; access JWT работает до expiry без новой проверки пользователя
в БД на каждом запросе. Ответ PATCH содержит passwordChanged/reauthenticationRequired.

`POST /api/v1/auth/password-reset/request` принимает email и даёт одинаковый 202
для существующего/неизвестного адреса. Поиск аккаунта и SMTP выполняются асинхронно
отдельным ограниченным executor. Ошибка доставки не меняет ответ и не раскрывает
наличие аккаунта. При ненастроенном adapter или полной очереди — одинаковый
503 EMAIL_SERVICE_UNAVAILABLE. Rate limiting: 3 запроса/email, 30/IP за 20 минут;
confirm — 30/IP. Register/login — 30/60 запросов/IP за 20 минут. Используется
remote address без доверия произвольному X-Forwarded-For. Лимиты однопроцессные,
обнуляются после restart; 429 содержит Retry-After.

`POST /api/v1/auth/password-reset/confirm`: token+newPassword, 204. 32 случайных
байта кодируются Base64url; в БД только SHA-256 hash. TTL ровно PT20M, повтор/expiry —
400 INVALID_RESET_TOKEN. Условный UPDATE и user lock обеспечивают однократное
применение вместе со сменой password hash и отзывом refresh. Token не возвращается API.

Все настройки только в корневом `.env` и `.env.example`: SMTP_HOST, SMTP_PORT,
SMTP_USERNAME, SMTP_PASSWORD, SMTP_AUTH, SMTP_STARTTLS, MAIL_FROM,
PASSWORD_RESET_BASE_URL, PASSWORD_RESET_TTL=PT20M. Внешние credentials не созданы.
SMTP_HOST и MAIL_FROM локально пока пусты: доставка выключена. В Compose
PASSWORD_RESET_BASE_URL указывает на frontend `/auth/reset`.
Доверенный frontend URL — абсолютный http(s), без query/fragment; письмо добавляет
`?token=...`. После обмена frontend удаляет token из адресной строки.
Локально возможен Mailpit: SMTP_HOST=localhost, SMTP_PORT=1025, SMTP_AUTH=false,
SMTP_STARTTLS=false, локальный MAIL_FROM и frontend reset route. В Docker нужен
доступный контейнеру SMTP hostname. Автотесты используют mail adapter/JavaMailSender
mocks и никому не отправляют письма.

## Статистика и leaderboard

Метрики по всей истории FINISHED независимо от лимита Free: W/L/D, played,
winRatePercent, currentWinStreak/bestWinStreak, accuracyPercent, avgAnswerTimeMs,
questionCount. LOSS/DRAW обрывают win streak, CANCELLED исключены. Completed questions
включают wrong/timeouts/overtime; incomplete forfeit — только принятые ответы.
Будущие раунды исключены. Среднее время — только отправленные ответы, без timeout;
без данных проценты/среднее равны null. Проценты округлены HALF_UP до 2 знаков,
среднее время — до целых миллисекунд.

Free получает topicStats/ratingHistory=null. Pro видит темы по всей истории,
weak при неокруглённой accuracy<65% и >=5 samples, последние 30 ranked outcomes
в хронологическом порядке с seasonId и before/after/delta. Сезонный сброс не
создаёт точку графика. Ранги/пики/calibration и daily/weekly streak доступны всем.

`GET /api/v1/leaderboards/{disciplineCode}` — текущий ET-сезон, top50 и отдельная me.
Порядок rating DESC → ratingReachedAt ASC → userId ASC, позиции ROW_NUMBER.
Calibration включена; deleted и rollover-pending исключены. Подготавливаются только
устаревшие строки сезона, без обхода текущих аккаунтов по одному на каждом чтении.
Pro влияет только на badge. me может быть null при pending.

## Review, rematch и reports

`GET /api/v1/battles/{id}/review?mistakesOnly=true` — Pro. Оставляет неправильные
и неотвеченные показанные раунды, включая incomplete. false доступен Free.
Owner/history gating действует также на прямые чтения и жалобы/реванши. Free в
REST/STOMP не получает correctOptionId/explanation/выбор соперника.

POST/GET/DELETE `/api/v1/battles/{id}/rematch`: участники terminal PRIVATE.
Первое согласие резервирует activity на 60 секунд; второе атомарно создаёт один
новый PRIVATE. Повторы не продлевают срок. Expiry/cancel освобождают activity;
CANCELLED/EXPIRED consent нельзя начать повторно. Новая сетка/вопросы/анти-повторы,
оба игрока снова проходят Ready. Общий lock с очередью/комнатами защищает commit/rollback.
REMATCH_CHANGED приходит обоим после commit. Memory-consents теряются при restart.

POST `/api/v1/battles/{id}/rounds/{roundId}/report`: показанный revealed/terminal
раунд, reason=INCORRECT_ANSWER|UNCLEAR_QUESTION|TYPO|OTHER, comment<=1000, OTHER требует
непустой comment. Первый report(user,battle,round) — 201, точный повтор — 200 с тем же
объектом, другой payload — 409 REPORT_ALREADY_EXISTS. Контент/результат/Elo не меняются.

## Входящие приглашения на реванш

`GET /api/v1/users/me/rematch-invitations`, access Bearer JWT, без body/query и
пагинации. Ответ: `{data: [{sourceBattleId, requester: {id,isPro,nickname},
disciplineCode, expiresAt, version}], serverTime}`. Всегда присутствуют оба
верхних поля, пустой `data` — нормальный 200, `Cache-Control: no-store`.
Owner определяется только из JWT sub. Учитываются только входящие WAITING со
строгим `expiresAt > serverTime`, порядок expiresAt/sourceBattleId. Исходящие,
чужие, MATCHED/CANCELLED/EXPIRED и обычные комнаты не включаются.

Снимок и expiration используют Clock под существующей registry-блокировкой;
nickname и Pro-флаги затем загружаются двумя пакетными запросами вне блокировки.
Минимальный список доступен Free/Pro и не расширяет history/answer access.
Принять — прежний POST `/battles/{sourceBattleId}/rematch`, отклонить — прежний
DELETE (204, CANCELLED). Входящее приглашение не резервирует получателя, не
покидает его activity и не отменяет другие приглашения. Исходные 60 секунд не
продлеваются. После MATCHED оба проходят Ready; DELETE возвращает 409
MATCH_ALREADY_FOUND и не удаляет созданный матч.

Используется прежний `REMATCH_CHANGED` на `/user/queue/events`, включая начальный
WAITING обоим участникам после commit. Wire-поля RematchResponse и envelope не
изменены. На клиентском startup/reconnect: слушатель → CONNECT/SUBSCRIBE → новый
GET и GET `/users/me/activity`. События могут теряться, дублироваться и менять
порядок; клиент объединяет их по sourceBattleId/version и поколению reconnect.
Список incoming не восстанавливает потерянный MATCHED: для него нужны activity
и snapshot нового battleId. При backend restart непринятые приглашения теряются;
персистентный созданный батл использует существующее recovery, включая отмену
незавершённого матча с SERVER_INTERRUPTION. Поддерживается один процесс backend.

Полный generated контракт после `verify`: `backend/target/generated-openapi.json`.
Точный контракт, примеры и сценарий двух аккаунтов —
[REMATCH_NOTIFICATIONS_HANDOFF.md](REMATCH_NOTIFICATIONS_HANDOFF.md).

## Контракт и передача frontend

Swagger `/v3/api-docs` содержит 54 продуктовых REST-операции и 2 media GET/HEAD. OpenAPI 3.1 может
представлять nullable как `type: [integer, null]`, эквивалент nullable=true целевого
OpenAPI 3.0.3. Имена схем могут отличаться; публичные поля и типы сверяются.

Frontend нужно передать generated OpenAPI и следующие изменения:
- birthYear/birthMonth/условный birthDay; reset route без логирования token;
- PATCH profile, reauthenticationRequired и очистку сессии после смены пароля;
- nullable метрики/advanced-поля, leaderboard/rematch/report routes;
- review без промежуточного format; AnswerAccess: canViewCorrectAnswer,
  canViewExplanation, entitlementVersion; Entitlements сохраняет plural-поля;
- QueueEntryResponse.error=null либо ErrorResponse при async cancellation;
- activity.resourceKind=null|DUEL|REMATCH и REMATCH_CHANGED в прежнем envelope;
- same-origin proxy REST/WebSocket, серверные права/версии и повторный Ready.

Согласованная с frontend функция similar practice удалена: нет трёх routes,
Practice DTO/mapper/service/repository/entity, соответствующего entitlement и прав в
описаниях Pro. Остальные права не менялись. Версия API осталась 0.3.0.
V11 удаляет только practice_sessions; V10 и более старые миграции не редактируются.
Frontend не изменён, отдельной frontend-спецификации в репозитории нет.
Предоставленный банк включён в V12; покупка Pro и Stripe удалены.

## Проверки

Итоговая проверка после согласованного удаления функции, 2026-11-15:
`clean verify` на Java 21 / PostgreSQL 17.12 — **349 тестов, 0 failures/errors/skipped**.
Проверены чистая схема V11 и upgrade V10 → V11 с удалением только practice-данных,
сохранением пользователей/батлов/жалоб и неизменным checksum V10. Hibernate работает
с `ddl-auto=validate`. Все 39 REST-операций и формы request/response/ErrorResponse
сверены; в generated OpenAPI нет удалённых routes, Practice DTO и canPracticeSimilar.
Версия API сохранена 0.3.0, цены и остальные права Free/Pro не изменились.

В собранном JAR нет классов удалённой функции. Из него пройдены реальные HTTP/STOMP
ranked/private, profile, leaderboard, reports, Pro gates, rematch consent/activity/events/cancel,
перезапуск и recovery. Runner использовал отдельную tmpfs PostgreSQL и случайный
loopback-порт; собственные процессы/контейнер удалены. Синтаксис smoke script и
`git diff --check` проверены. Внешняя SMTP-доставка этими проверками не подтверждается.

К существующим проверкам scoring/overtime/калибровки/сезонов добавлены
Pro при регистрации, отсутствие платёжных ручек, last ticket/refund/downgrade/start, ET midnight/DST,
last10-before-filter и все пути redaction, daily/weekly streak, реальные
REST/STOMP ACCOUNT_CHANGED и rollback. Используются отдельные PostgreSQL контейнеры.

Новые проверки: границы возраста ET, profile validation/uniqueness/refresh revocation,
reset privacy/replay/race/expiry, all-history statistics/Pro gating, leaderboard ties/top50/pending,
mistakesOnly, rematch races/expiry/cancel/rollback, report idempotency/races, отсутствие удалённых routes/entitlement и миграция
V10 → V11 с сохранением пользователей, батлов и жалоб. Реальный STOMP проверяет REMATCH_CHANGED.
Тесты не используют внешние SMTP credentials.

Из backend/, Java 21 и Docker:

```powershell
.\mvnw.cmd -B -ntp '-Dtest=EntitlementsPostgresTest,AccountRealtimePostgresTest,AuthPostgresTest,StreakCalculatorTest' test
.\mvnw.cmd -B -ntp verify
git diff --check
```

Проверки используют только изолированные PostgreSQL/Testcontainers и явно
тестовые вопросы. При отсутствии Docker интеграционные тесты будут skipped —
такой прогон не подтверждает БД/конкурентность. H2 вместо PostgreSQL не используется.
Fixtures `src/test/resources/fixtures/stage2-questions-test-only.json` обновлены:
19 заданий SAT_MATH/SAT_RW с EASY/MEDIUM/HARD; это не production-банк.

После сборки, Python 3.10+ и Node.js 22+:

```powershell
python scripts/verify_e2e.py
```

Runner создаёт собственную PostgreSQL в tmpfs (без Docker volumes), явно выполняет
dry-run/apply fixtures, запускает JAR на loopback-порту, проходит реальные
REST/STOMP ranked/private, retry/conflict, reconnect, review/history и перезапуск.
Время вопросов берётся из каталога; countdown/reveal только в runner сокращены до
1 секунды. Удаляются только созданные runner процессы и tmpfs-контейнер; пользовательские
БД/volumes не затрагиваются. Логи — target/e2e-*.log. Пароли/JWT не выводятся.
Runner также проверяет PRIVATE overtime с одним tieBreakPoint, калибровку ranked,
согласованность сезонных полей и сохранение новых матчей после рестарта.
Runner проверяет Pro при регистрации, отсутствие платёжных routes,
ACCOUNT_CHANGED, profile/reset availability, leaderboard, report и rematch consent/activity/REMATCH_CHANGED наряду с прежними flow.

Текущий банк: V12 содержит 239 SAT-вопросов; удалённый источник не восстанавливается,
с достаточными пулами всех сложностей обеих дисциплин. Оригиналы и изменения
23 наборов вариантов описаны в QUESTION_BANK.md. В изолированном runner эти
seed-вопросы сохраняются, но деактивируются перед импортом детерминированных fixtures;
пользовательская БД этим runner не затрагивается. Дополнительный банк по-прежнему
можно загрузить через dry-run/apply importer.


## Временные стикеры в батле

`POST /api/v1/battles/{id}/stickers`, access Bearer JWT. Тело только
`{"stickerId":"gg","submissionId":"<UUID>"}`. Девять точных ID:
`gg`, `fire`, `facepalm`, `lol`, `hmm`, `too_slow`, `ez`, `wait_what`, `crying`.
Доступ одинаков для Free/Pro, RANKED/PRIVATE и обеих дисциплин. Новые отправки
разрешены только в WAITING_READY, COUNTDOWN, QUESTION, REVEAL.

200 возвращает `battleId, submissionId, senderUserId, stickerId, sentAt, nextAllowedAt`.
Это приём команды, а не подтверждение доставки/прочтения. Соперник получает
`BATTLE_STICKER` через существующий native STOMP `/user/queue/events`;
отправитель не получает echo. Envelope.version — отдельный счётчик стикеров батла,
не battle.version. Команды STOMP SEND по-прежнему запрещены.

Cooldown ровно 4000 мс на пользователя, общий для вкладок/сеансов/батлов.
429 `STICKER_COOLDOWN` содержит точный `resetsAt` и `Retry-After` с округлением
секунд вверх, минимум 1. Frontend тихо синхронизирует таймер; другие окончательные
ошибки обозначает Not sent. Все ответы проходят существующий no-store filter.

Принятые submissionId хранятся 120 секунд в памяти процесса: одинаковый payload
возвращает первоначальный ACK, включая повтор после окончания батла, без нового
события/кулдауна. Изменённый payload — 409 IDEMPOTENCY_CONFLICT. На рестарте
состояние стикеров исчезает. Доставка best-effort: offline/drop не отменяет ACK,
повтор не переотправляет событие. Истории/replay, SQL-записей и миграций нет.
Таймеры/счёт/Elo/квоты/presence не меняются. Анимации принадлежат frontend.

Подробный контракт и проверки: [BATTLE_STICKERS_HANDOFF.md](BATTLE_STICKERS_HANDOFF.md).
Focused проверки из backend/: `./mvnw.cmd -B -ntp '-Dtest=BattleStickerStateTest,BattleStickerRealtimeTest,BattleStickersPostgresTest' test`.
Существующие runners `scripts/verify_e2e.py` и `scripts/verify_compose.py`
также проверяют стикеры и очистку их receipts при реальном рестарте JAR.
