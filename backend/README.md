# SkillBattles backend

Авторизация, вопросы/импорт, движок батлов и realtime: Java 21, Spring Boot 3.5.16, Spring MVC / JPA /
Security Resource Server, PostgreSQL 17.12, Flyway, Validation, Lombok, MapStruct 1.6.3,
springdoc 2.10.0. Maven Wrapper 3.3.4 запускает Maven 3.9.12. Остальные зависимости
зафиксированы BOM Spring Boot; их версии не переопределяются вручную.

Версии сверены с [Spring Boot 3.5](https://docs.spring.io/spring-boot/3.5/),
[матрицей springdoc](https://springdoc.org/v2/faq.html#_what_is_the_compatibility_matrix_of_springdoc_openapi_with_spring_boot),
[MapStruct](https://mapstruct.org/documentation/stable/reference/html/),
[PostgreSQL](https://www.postgresql.org/support/versioning/).
Boot 3.5.16 — последний OSS-релиз требуемой ветки 3.5.x; переход на другую ветку
потребует отдельной задачи. Ranked matchmaking, приватные дуэли по коду и текущая
активность реализованы; полноценные history/review endpoints относятся к этапу 6.

## Локальная конфигурация

Из корня репозитория скопируйте `.env.example` в `.env`. Заполните
`POSTGRES_PASSWORD` и `JWT_SECRET` случайными значениями; `.env` исключён из Git.
Например, PowerShell генерирует значения без вывода в консоль:

```powershell
Copy-Item .env.example .env
$dbSecret = [Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(24))
$jwtSecret = [Convert]::ToBase64String([Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
$content = (Get-Content -Raw .env).Replace('POSTGRES_PASSWORD=', "POSTGRES_PASSWORD=$dbSecret").Replace('JWT_SECRET=', "JWT_SECRET=$jwtSecret")
Set-Content -LiteralPath .env -Value $content -Encoding utf8
Remove-Variable dbSecret,jwtSecret,content
```

Эта команда предназначена для первой настройки: не перезаписывайте существующий `.env`.
Не используйте примерные/тестовые ключи из тестов приложения.

| Переменная | Значение / назначение |
|---|---|
| `POSTGRES_DB` | `skillbattles`, имя БД в Compose |
| `POSTGRES_USER` | `skillbattles`, пользователь БД в Compose |
| `POSTGRES_PASSWORD` | Обязательный локальный пароль БД для Compose |
| `POSTGRES_PORT` | `5432`, порт БД на localhost |
| `BACKEND_PORT` | `8080`, порт контейнера backend на localhost |
| `DB_URL` | Для JVM: `jdbc:postgresql://localhost:5432/skillbattles` |
| `DB_USERNAME` | Для JVM: `skillbattles` |
| `DB_PASSWORD` | Обязательный пароль БД для JVM |
| `SERVER_PORT` | `8080`, порт процесса Spring Boot |
| `JWT_SECRET` | Обязательный Base64-ключ HS256, минимум 32 случайных байта |
| `JWT_ISSUER` | `skillbattles` |
| `JWT_ACCESS_TTL` | ISO-8601 Duration, `PT15M`, положительное целое число секунд, максимум 15 минут |
| `JWT_REFRESH_TTL` | ISO-8601 Duration, `P7D`, положительное целое число секунд |

## Docker Compose

Команды выполняются **из корня**:

```powershell
docker compose config --quiet
docker compose up -d --build
docker compose logs backend
docker compose down
```

Compose читает корневой `.env` для подстановки и явно передаёт `DB_*` / `JWT_*`
в окружение backend. БД и опубликованный API привязаны к `127.0.0.1`.
Данные PostgreSQL сохраняются в именованном томе при `down`.
Flyway применяет миграции, Hibernate проверяет схему через `ddl-auto=validate`.
Приложение, JDBC и PostgreSQL используют UTC. Dockerfile собирает приложение
в JDK 21, запускает в JRE 21 от пользователя без root; тесты запускаются отдельно.

## JVM и Maven Wrapper

Java 21 должна быть указана в `JAVA_HOME`. Все Maven-команды выполняются **из backend/**.

```powershell
Set-Location backend
.\mvnw.cmd -B -ntp verify
.\mvnw.cmd -B -ntp -DskipTests package
```

На Linux/macOS эквивалент — `./mvnw -B -ntp verify`.
Wrapper и Maven скачивают свои файлы при первом запуске: нужен доступ к Maven Central.
`verify` включает unit/MVC-тесты и PostgreSQL Testcontainers-тесты. При отсутствии
Docker пропускаются только `AuthPostgresTest`; такой прогон не подтверждает
миграции и конкурентное поведение БД. H2 не используется.

Для запуска JVM поднимите БД **из корня**: `docker compose up -d postgres`.
Spring Boot сам не загружает корневой `.env`. Затем **из backend/** загрузите
простой незаключённый в кавычки формат `.env.example` в окружение PowerShell
и задайте переменные подключения:

```powershell
Get-Content ..\.env | ForEach-Object {
    if ($_ -match '^([A-Z][A-Z0-9_]*)=(.*)$') {
        [Environment]::SetEnvironmentVariable($Matches[1], $Matches[2], 'Process')
    }
}
$env:DB_URL = "jdbc:postgresql://localhost:$($env:POSTGRES_PORT)/$($env:POSTGRES_DB)"
$env:DB_USERNAME = $env:POSTGRES_USER
$env:DB_PASSWORD = $env:POSTGRES_PASSWORD
$env:SERVER_PORT = $env:BACKEND_PORT
.\mvnw.cmd spring-boot:run
# Или после сборки:
# java -Duser.timezone=UTC -jar target/backend-0.0.1-SNAPSHOT.jar
```

В другом shell экспортируйте те же `DB_*` / `JWT_*` средствами своего shell.
Подстановка Compose сама по себе не задаёт окружение JVM, запущенной на хосте.

## API и авторизация

Swagger: [http://localhost:8080/swagger-ui.html](http://localhost:8080/swagger-ui.html).
OpenAPI: [http://localhost:8080/v3/api-docs](http://localhost:8080/v3/api-docs).
Оба доступны без токена. В Authorize есть отдельные схемы accessBearer и refreshBearer.

| Метод и путь | Вход | Результат |
|---|---|---|
| `POST /api/v1/auth/register` | JSON `{email, password, nickname}`, публичный | 201, пользователь и пара JWT |
| `POST /api/v1/auth/login` | JSON `{email, password}`, публичный | 200, пользователь и пара JWT |
| `POST /api/v1/auth/refresh` | `Authorization: Bearer <refreshToken>`, без тела | 200, новая пара JWT |
| `POST /api/v1/auth/logout` | `Authorization: Bearer <refreshToken>`, без тела | 204, отзыв этой сессии |
| `GET /api/v1/users/me` | `Authorization: Bearer <accessToken>` | 200, `{id, email, nickname, createdAt}` |
| `GET /api/v1/users/me/statistics` | `Authorization: Bearer <accessToken>` | 200, статистика по MATH и ENGLISH |
| `GET /api/v1/battle-modes` | `Authorization: Bearer <accessToken>` | 200, настройки обоих предметов и наличие контента |
| `GET /api/v1/battles/{id}` | Access JWT участника | 200, персональный BattleSnapshot |
| `POST /api/v1/battles/{id}/readiness` | Access JWT, `{ready:true}`, live realtime presence | 200, BattleSnapshot |
| `POST /api/v1/battles/{id}/answers` | Access JWT, `{roundId,optionId,submissionId}` | 200, AnswerReceipt без правильности и очков |
| `POST /api/v1/battles/{id}/surrender` | Access JWT участника, без тела | 200, BattleSnapshot |
| `GET /api/v1/battles/{id}/result` | Access JWT участника | 200, персональный BattleResult; до завершения 409 |

Регистрация сразу выполняет вход. Email обрезается по краям и приводится к lowercase;
email и nickname уникальны без учёта регистра среди активных пользователей. Nickname:
3–24 ASCII-буквы/цифры/`_`/`-`. Пароль: 8–72 символа по API-контракту,
дополнительно 8–72 UTF-8 байта, без trim, BCrypt.
Неизвестные JSON-поля отклоняются. Времена в API имеют UTC-суффикс `Z`.

Подпись — явно разрешённый HS256, проверяются issuer, audience, token_use,
subject UUID, jti и временные claims без допуска просрочки. Access и refresh
не взаимозаменяемы. В БД хранится только SHA-256 refresh, UUID пользователя,
срок и время отзыва. У каждого JWT свой случайный jti. Refresh атомарно
отзывается условным UPDATE; отзыв старого и сохранение нового входят в одну
транзакцию processor. Конкурентный повторный refresh даёт одного победителя.
Пользователь блокируется перед token row, в том же порядке, что при удалении.

Logout отзывает только переданный refresh; повторное использование возвращает 401.
Другие сессии продолжают работать. Выданный access остаётся действительным
до истечения срока; его аутентификация не обращается к БД. `/users/me`
загружает активный профиль и после soft delete возвращает 404. Login и refresh
удалённого пользователя отклоняются. Для будущего удаления аккаунта есть
`AuthProcessor.deleteUser`: soft delete и отзыв всех refresh в общей транзакции;
HTTP endpoint удаления в этот этап не входит. Повторное удаление — 404.
Активные уникальные индексы позволяют повторно использовать email/nickname.

Ошибки имеют единый формат `{code, message, fieldErrors: [{field, message}]}`,
включая ошибки фильтров Security. Нет ролей, cookie-аутентификации и HTTP-сессий.
CSRF отключён для Bearer API. CORS пока не настроен; фронтенду с другим origin
нужен dev proxy или отдельное согласование разрешённых origins.

## Этап 2: вопросы, импорт, рейтинги и режимы

`GET /api/v1/battle-modes` возвращает MATH и ENGLISH. По умолчанию это
3 вопроса × 95 секунд и 4 вопроса × 70 секунд; ready timeout 30 секунд,
countdown 3 секунды, reveal 5 секунд. `contentAvailable=true` означает, что
есть минимум нужное число разных активных вопросов сложности MEDIUM.
Пустой/недостаточный банк даёт `false`, без подстановки выдуманного контента.
При создании батла банк проверяется повторно; недавняя история не уменьшает
доступность контента, если подходящих уникальных вопросов достаточно.

Настройки в `application.yml`: `app.battle.math` / `app.battle.english`
(`question-count`, `question-limit-seconds`), а также `ready-timeout-seconds`,
`countdown-seconds`, `reveal-seconds`. Для JVM поддерживаются переменные
`MATH_QUESTION_COUNT`, `MATH_QUESTION_LIMIT_SECONDS`, `ENGLISH_QUESTION_COUNT`,
`ENGLISH_QUESTION_LIMIT_SECONDS`, `READY_TIMEOUT_SECONDS`, `COUNTDOWN_SECONDS`,
`REVEAL_SECONDS`. Для контейнера задайте эти Spring properties через его
окружение или конфигурацию; корневой `.env` сам по себе не передаёт дополнительные
переменные внутрь контейнера. Все значения должны быть положительными.

Регистрация атомарно создаёт два независимых рейтинга по 1000. Миграция V2
добавляет их активным пользователям, зарегистрированным до этапа 2.
Rank вычисляется из рейтинга: Rookie 0–1099, Challenger 1100–1299,
Strategist 1300–1499, Expert 1500–1799, Master от 1800.
`GET /api/v1/users/me/statistics` возвращает оба предмета, rating/rank и
отдельные `ranked` / `privateMatches` с `wins`, `losses`, `draws`, `played`.
С этапа 3 счётчики строятся по завершённым батлам; CANCELLED исключаются,
PRIVATE не изменяет Elo и ranked-счётчики. Оба endpoint требуют access JWT.

### Локальный импорт JSON

Импорт выключен при обычном запуске. Нет HTTP endpoint импорта или выдачи
банка вопросов. Профиль `question-import` запускает команду без HTTP-сервера
и завершает JVM после обработки. Используются те же `DB_*` и `JWT_*`, что
при обычном запуске JVM; загрузите их в окружение по инструкции выше.

Команды **из backend/** после сборки:

```powershell
# Проверка всего файла и конфликтов с БД, без изменения записей вопросов:
& "$env:JAVA_HOME/bin/java.exe" -jar target/backend-0.0.1-SNAPSHOT.jar --spring.profiles.active=question-import --questions.file=C:/data/questions.json

# Применение после успешной проверки:
& "$env:JAVA_HOME/bin/java.exe" -jar target/backend-0.0.1-SNAPSHOT.jar --spring.profiles.active=question-import --questions.file=C:/data/questions.json --questions.apply=true
```

В Linux/macOS используйте `"$JAVA_HOME/bin/java"` вместо PowerShell-вызова.
При ошибке процесс завершается с ненулевым кодом. Flyway при старте профиля
по-прежнему обновляет схему; dry-run относится к данным вопросов. В отчёте
`inserted` для dry-run — число ревизий, которые были бы добавлены.

Верхний уровень файла — непустой JSON-массив. Схема одного элемента:

```text
{
  externalKey: nonblank string, maximum 200 characters,
  contentVersion: positive integer,
  subject: MATH | ENGLISH,
  topic: nonblank string, maximum 200 characters,
  difficulty: MEDIUM,
  prompt: nonblank plain text,
  options: [{key: A, text: nonblank string}, ... B, C, D],
  correctOptionKey: one of the four keys,
  explanation: nonblank plain text
}
```

Имена и строковые значения в реальном JSON должны быть в двойных кавычках.
Неизвестные поля, неизвестные enum, дробная версия, повторные JSON-свойства,
повторные пары externalKey/contentVersion, пустые тексты и некорректные
варианты отклоняются. Ключи вариантов — ровно A/B/C/D; их порядок сохраняется.
`externalKey` регистрозависим и не нормализуется. Проверка английского языка,
правильности ответа и качества объяснения остаётся редакторской задачей.

Весь пакет проверяется до записи и применяется одной транзакцией. Импорты
сериализуются advisory lock PostgreSQL, включая отдельные JVM.
Одинаковая ревизия повторно не меняет данные, UUID или аудит. Изменение контента
существующей ревизии отклоняется с `QUESTION_REVISION_CONFLICT`: увеличьте
contentVersion. Новая старшая ревизия становится активной, предыдущая
отключается и сохраняется. Импорт старой версии не откатывает активную версию;
повтор ранее отключённой ревизии не включает её обратно. В одном файле можно
передать несколько различных версий одного externalKey — активной будет старшая.
UUID вариантов детерминированы externalKey + contentVersion + key.
На один externalKey учитывается максимум одна активная ревизия.

Реальный банк не поставляется и не загружается автоматически. Файл
`src/test/resources/fixtures/stage2-questions-test-only.json` предназначен только
для автоматических проверок; он не является проверенным учебным контентом.

JDBC напрямую передаёт `LocalDateTime`, чтобы UTC-аудит не сдвигался при
запуске JVM в другой часовой зоне ([настройка Hibernate](https://docs.hibernate.org/orm/6.6/javadocs/org/hibernate/cfg/MappingSettings.html#JAVA_TIME_USE_DIRECT_JDBC)).
Ранее сохранённые данные этой настройкой не переписываются.

## Этап 3: движок батлов

Миграция V3 добавляет агрегат `battles`: участники с FK на пользователей,
предмет/режим/фаза, дедлайны, версия, JSONB-снимки игроков, вопросов,
вариантов, раундов и принятых ответов, а также результат и `settledAt`.
История не удаляется каскадом при удалении пользователя. Ревизии банка
после создания матча не меняют его снимки; будущие вопросы и объяснения
в текущий HTTP-снимок не попадают.

Внутренний `BattleProcessor.create(CreateBattleDto)` — граница для будущего
matchmaking. Он блокирует пользователей в стабильном порядке, запрещает
совпадающих участников и второй активный батл, выбирает N различных активных
MEDIUM-вопросов и фиксирует их порядок/варианты и настройки времени.
При нехватке контента возвращается CONTENT_UNAVAILABLE без частичного батла.
Публичного endpoint создания, тестового HTTP API и production-банка нет.

При подборе учитываются последние 5 начавшихся батлов каждого участника по
выбранному предмету, включая RANKED/PRIVATE и отменённые после старта матчи.
Порядок определяется стартом первого раунда. Не начавшийся матч не занимает
окно, а заранее выбранные, но не начавшиеся раунды не считаются показанными.
Сначала случайно выбираются вопросы, которых не было ни у одного участника
в его окне. Недостающие места заполняются ранее встречавшимися вопросами:
от наиболее давнего последнего показа любому из игроков к наиболее свежему;
при одинаковом времени выбор случайный. Все ревизии externalKey считаются
одним вопросом, включая ранее показанные неактивные/soft-deleted ревизии.
История не уменьшает доступный банк: CONTENT_UNAVAILABLE означает только
недостаток подходящих уникальных активных MEDIUM-вопросов в целом.
Правило одинаково для обоих режимов, выбранный порядок фиксируется один раз.

Историю читает BattleService через собственный repository и DTO. Идентичность
ревизий разрешает QuestionService через свой repository; существующие снимки
батлов менять не требуется. Публичный API и формат BattleSnapshot сохранены.

Переходы: WAITING_READY → COUNTDOWN → QUESTION → REVEAL → следующий QUESTION
либо FINISHED. Последний REVEAL длится те же 5 секунд. Scheduler сверяет
сохранённые дедлайны с внедряемым `Clock`; при запоздалом вызове проходит
просроченные переходы по исходной шкале времени. Повторный/пустой poll не
меняет версию. HTTP-чтение также согласует состояние с дедлайнами под блокировкой.

Только один ответ участника на раунд. `submissionId` идентифицирует принятую
команду в пределах батла: тот же участник/round/option получает первоначальный
receipt даже после смены раунда или завершения; конфликт — IDEMPOTENCY_CONFLICT.
Другой submission после ответа — ANSWER_ALREADY_SUBMITTED. Неверный вариант —
INVALID_OPTION; точное равенство deadline уже поздно. Время приёма фиксируется
фильтром до Security/MVC и передаётся в processor, а не принимается из JSON.
Время батла нормализуется к микросекундам, чтобы PostgreSQL round-trip не менял
публичный дедлайн из-за округления наносекунд.
Ожидание блокировки не уменьшает бонус своевременно поступившего запроса;
уже зафиксированное закрытие раунда не отменяется.

Правильный ответ: 1000 + floor(100 × remainingMs / limitMs), от 1000 до 1100.
Ошибка/таймаут: 0. До REVEAL счёт, correctCount и streak показывают только
ранее раскрытые раунды. Сопернику виден факт ответа, но не выбранный вариант,
правильность или текущие очки. Свой выбор виден его владельцу. Таймаут хранится
отдельно от неверного ответа: selection/elapsedMs равны null.

Surrender до первой QUESTION отменяет матч; после старта завершает поражением
сдавшегося независимо от накопленных очков. Незавершённый раунд не добавляет
очки в итог. Нормальная ничья определяется равенством счёта. Elo с K=32
использует замороженные рейтинги выбранного предмета и HALF_UP, с нижней
границей 0 и фактическими дельтами в ответе. PRIVATE/CANCELLED рейтинги не меняют.

Каждая мутация сериализуется PESSIMISTIC_WRITE-блокировкой батла. Processor
удерживает общую транзакцию на результат и изменение двух рейтингов;
рейтинги блокируются в стабильном порядке, а `settledAt` защищает от повторного
начисления. Ошибка после flush рейтингов откатывает весь результат. Терминальные
состояния неизменяемы. Событие `BattleChangedEvent` публикуется после commit
и содержит только id/version/time — получатель строит отдельную персональную
проекцию для каждого участника.

### Граница realtime/presence

`PresenceService.current(userId)` возвращает только актуальное
аутентифицированное realtime-соединение с активной подпиской, sessionId и сроком JWT.
Реальный in-memory adapter подключается в обычном серверном профиле. До успешного
CONNECT и SUBSCRIBE readiness возвращает REALTIME_CONNECTION_REQUIRED.

Transport adapter вызывает `BattleProcessor.tick` через отдельный executor
при смене актуальной сессии/presence. Отложенные disconnect callbacks
обновляют только соответствующую текущую generation в adapter; движок читает
его актуальное состояние, а не доверяет sessionId от HTTP-клиента.
Батл хранит текущую session identity и срок JWT; после истечения токена или
потери соединения начинается grace 30 секунд. Таймеры вопросов не останавливаются;
при равенстве grace deadline истечение выигрывает у reconnect. После grace:
DISCONNECT с поражением, если оппонент online; оба offline — BOTH_DISCONNECTED
без Elo. До старта используется отмена. При запуске приложения все сохранённые
нетерминальные матчи отменяются с SERVER_INTERRUPTION без изменения рейтингов.
Ранее завершённые матчи сохраняются. Профиль question-import не запускает
scheduler/recovery, WebSocket и presence-monitor и не прерывает активные батлы работающего сервера.

Дополнительные настройки:

| Настройка | По умолчанию |
|---|---|
| `app.battle.reconnect-grace-seconds` / `RECONNECT_GRACE_SECONDS` | 30 |
| `app.battle.question-history-battles` / `QUESTION_HISTORY_BATTLES` | 5; положительное число начавшихся батлов на участника и предмет |
| `app.battle.scheduling.enabled` | true; в детерминированных тестах false |
| `app.battle.scheduling.poll-ms` | 500 |

Scheduler начинает обработку после recovery. Ошибка одного батла не останавливает
остальные; повторный poll повторяет транзакцию. Обработка рассчитана на один
экземпляр приложения согласно MVP. Публичное создание матчей через очередь и
приватные коды добавлено на этапе 5; отдельного тестового endpoint создания нет.

Проверки **из backend/**:

```powershell
.\mvnw.cmd -B -ntp '-Dtest=BattleEngineTest' test
.\mvnw.cmd -B -ntp '-Dtest=BattlePostgresTest' test
.\mvnw.cmd -B -ntp verify
```

Unit-тесты используют управляемое время без sleep. PostgreSQL-тесты проверяют
снимки, персональное сокрытие ответов, HTTP-валидацию, гонки ответов/дедлайна,
повторы scheduler, surrender/finalization, отдельные рейтинги и статистику,
rollback после flush рейтинга и отсутствие событий при rollback.

## Этап 4: realtime и восстановление

Native WebSocket: `ws://localhost:8080/ws/v1/events` (за TLS — `wss://<host>/ws/v1/events`),
STOMP 1.2, встроенный simple broker. SockJS и внешний брокер не используются.
HTTP handshake публичный, без токенов в URL. Все query parameters запрещены.
Единственная подписка — `/user/queue/events`, `ack:auto`, одна на gameplay-сеанс.
SUBSCRIBE на чужие user destinations, `/queue/**`, `/topic/**` и клиентские SEND
запрещены. Действия игрока выполняются через существующий REST API.

CONNECT и SUBSCRIBE (обозначение `^@` заменяется настоящим байтом NULL):

```text
CONNECT
accept-version:1.2
host:localhost
heart-beat:5000,5000
Authorization:Bearer <accessToken>

^@
```

После CONNECTED:

```text
SUBSCRIBE
id:events
destination:/user/queue/events
ack:auto

^@
```

Access JWT проверяется в ChannelInterceptor тем же decoder, что и REST:
подпись, issuer, audience, purpose, срок действия. Refresh JWT для CONNECT
запрещён. Авторизация устанавливается для конкретной STOMP-сессии, заголовок
с токеном удаляется до передачи сообщения обработчикам. Cookie-сессий нет.
Message-level CSRF намеренно не включён: используется собственный token-only
interceptor без `@EnableWebSocketSecurity`/`CsrfChannelInterceptor`.
Это отдельно от servlet CSRF; проверка origin на handshake сохранена.
Ошибки протокола/авторизации отправляются как STOMP ERROR с JSON ErrorResponse,
затем соединение закрывается. Не включайте логирование STOMP frames с credentials.

Heartbeat в обе стороны — 5 секунд (`heart-beat:5000,5000`); клиент должен предлагать
положительные интервалы не больше 5000 мс. После 10 секунд без входящих данных
monitor обнаруживает потерю, после неё даётся 30 секунд reconnect grace.
Проверка выполняется каждые 500 мс. CONNECT должен поступить за 10 секунд.
Настройки находятся в `app.realtime` в application.yml; grace — в `app.battle`.
Новый CONNECT с успешной подпиской заменяет старый gameplay-сеанс и закрывает
старое соединение. Поздний disconnect старой сессии не отключает новую.
UNSUBSCRIBE также снимает presence. Таймеры батла и сохранённые ответы продолжают
действовать при потере соединения. Время обнаружения disconnect и поступления
reconnect учитывается даже при задержке обработки блокировкой БД.

Соединение закрывается при истечении access JWT. Клиент получает новый access
через `POST /api/v1/auth/refresh` с refresh Bearer и повторяет CONNECT/SUBSCRIBE.
Истёкший access не продлевает авторизацию уже открытого соединения.

Событие BATTLE_CHANGED содержит полный персональный BattleSnapshot в `data`.
Например, уведомление о готовности первого участника:

```json
{
  "eventId": "f2055366-92cf-4ff2-a0e0-55e69107ac9d",
  "type": "BATTLE_CHANGED",
  "resourceId": "ef704725-47b7-4aa7-9309-06fb82095062",
  "version": 2,
  "occurredAt": "2026-11-14T12:00:01Z",
  "data": {
    "id": "ef704725-47b7-4aa7-9309-06fb82095062",
    "subject": "MATH",
    "mode": "RANKED",
    "phase": "WAITING_READY",
    "version": 2,
    "serverTime": "2026-11-14T12:00:01Z",
    "questionCount": 3,
    "readyDeadline": "2026-11-14T12:00:30Z",
    "countdownEndsAt": null,
    "nextRoundStartsAt": null,
    "players": [
      {"id": "32c21096-2666-4c78-a7dc-81cb0e14abcc", "nickname": "PlayerOne", "rating": 1000, "rank": "Rookie", "ready": true, "connected": true, "score": 0, "correctCount": 0, "streak": 0, "answeredCurrentRound": false, "reconnectDeadline": null},
      {"id": "0bd4bf21-e05b-44e4-aada-5959b6d6f1f9", "nickname": "PlayerTwo", "rating": 1000, "rank": "Rookie", "ready": false, "connected": true, "score": 0, "correctCount": 0, "streak": 0, "answeredCurrentRound": false, "reconnectDeadline": null}
    ],
    "round": null,
    "result": null
  }
}
```

Readiness, countdown, начало вопроса, принятие ответа, reveal, presence,
завершение и отмена порождают уведомления только после успешного commit.
Проекция строится отдельно для каждого игрока из закоммиченного состояния.
До REVEAL она скрывает выбор соперника, правильность и начисления текущего ответа.
БД и отправка по сети разделены: отправка не удерживает транзакцию результата/Elo.
События не являются durable log: возможны повторы, пропуски и объединение быстрых
изменений в актуальный snapshot. Для восстановления:

1. Подключиться и подписаться на `/user/queue/events`, начать буферизовать события.
2. Выполнить `GET /api/v1/users/me/activity` с access JWT, затем GET найденного
   queue entry / duel / battle. Если ID батла уже известен — `GET /api/v1/battles/{id}`.
3. Применить snapshot и буфер по `resourceId`/`version`: состояние заменяется
   только более новой версией. `serverTime` используется для синхронизации часов.
4. После REST-мутаций и reconnect снова запросить snapshot; принятый ответ и
   исходный дедлайн сохраняются.

Same-origin остаётся обязательным для браузера. Frontend dev server должен
проксировать `/api/**` и WebSocket upgrade `/ws/**` к backend, согласованно
передавая Host/Origin. В production reverse proxy должен поддерживать Upgrade
и Connection и не обрывать heartbeat-соединения. Wildcard origins не открываются.

Дополнительная проверка реального транспорта **из backend/** (нужен Docker):

```powershell
.\mvnw.cmd -B -ntp '-Dtest=RealtimePostgresTest' test
```

## Этап 5: очередь, приватные коды и активность

Все endpoints требуют access Bearer JWT; тела запросов строго соответствуют
существующему контракту 0.2. Refresh JWT здесь не принимается.

| Метод и путь | Тело запроса | Результат |
|---|---|---|
| `POST /api/v1/matchmaking/entries` | `{"subject":"MATH"}` | 201 QueueEntryResponse; возможен быстрый MATCHED |
| `GET /api/v1/matchmaking/entries/{id}` | — | 200; только владелец |
| `DELETE /api/v1/matchmaking/entries/{id}` | — | 204; повтор CANCELLED/EXPIRED также 204 |
| `POST /api/v1/duels` | `{"subject":"ENGLISH"}` | 201 DuelResponse с кодом |
| `POST /api/v1/duels/join` | `{"code":"K7P9XZ"}` | 200 MATCHED с battleId |
| `GET /api/v1/duels/{id}` | — | 200; host или назначенный guest |
| `DELETE /api/v1/duels/{id}` | — | 204; только host, до матча |
| `GET /api/v1/users/me/activity` | — | 200 ActivityResponse |

Ranked-поиск использует рейтинг выбранного предмета и самого давно ожидающего
подходящего соперника. Разница рейтингов должна укладываться в окна обоих:
±100 до 15 секунд, ±200 от 15 до 30 секунд, затем ±400. В 90 секунд поиск истекает.
Self-match и повторное назначение исключены. Батл создаётся существующим движком
с теми же снимками вопросов и защитой от повторов и начинается с WAITING_READY.
Readiness требует действующей realtime-подписки обоих игроков.

Приватный код — 6 криптографически случайных uppercase-букв/цифр без неоднозначных
символов, срок 10 минут. Join обрезает пробелы и приводит код к uppercase.
Присоединение атомарно назначает guest и создаёт PRIVATE battle без изменения Elo.
Повторный join завершённой/занятой комнаты не создаёт новый батл. Код и терминальная
комната сохраняются до рестарта; коды в этом процессе не переиспользуются.

Основные ошибки: `ACTIVITY_CONFLICT`, `CONTENT_UNAVAILABLE`, `MATCH_ALREADY_FOUND`,
`SELF_JOIN_NOT_ALLOWED`, `DUEL_NOT_JOINABLE` — 409; неизвестный код/чужой ресурс —
404 (`DUEL_NOT_FOUND` / `QUEUE_ENTRY_NOT_FOUND`); истёкший код — 410 `DUEL_EXPIRED`.
После MATCH_ALREADY_FOUND отмена выполняется через surrender батла. Нехватка
контента не оставляет нового entry, guest или частичного батла. Существующая
WAITING-комната допускает join после восстановления банка.
Очередь, потерявшая доступный контент, переходит в CANCELLED; клиент может
перепроверить `/battle-modes` и при новой попытке получить CONTENT_UNAVAILABLE.

Аккаунт одновременно имеет одну очередь, ожидающую комнату или незавершённый
батл. Для однопроцессного MVP registry сериализует переходы общей блокировкой
до commit/rollback БД. Изменения памяти становятся видимы и события публикуются
только после commit; rollback сохраняет прежние очередь/комнату. Результат и Elo
по-прежнему фиксируются транзакцией движка. Завершённый батл, отмена и expiry
освобождают активность; отдельного дублирующего in-memory флага BATTLE нет.

ActivityResponse: `{"type":"NONE","resourceId":null,"battleId":null}`;
для QUEUE/PRIVATE_DUEL заполнен resourceId, для BATTLE оба ID равны ID батла.
Он пригоден для восстановления после reload и пропущенных уведомлений:
CONNECT → SUBSCRIBE → activity → соответствующий GET snapshot → merge по версиям.
Не нужно считать события очереди и события батла единой упорядоченной лентой.

QUEUE_CHANGED получает только владелец entry; PRIVATE_DUEL_CHANGED — host и
назначенный guest. Envelope прежний, `data` содержит полный контрактный ответ,
version совпадает с ним. При MATCHED у обоих участников доступен battleId.
Коды не отправляются посторонним подписчикам. События остаются недолговечными
уведомлениями; REST является источником актуального состояния.

Настройки: `app.matchmaking.search-seconds` / `MATCHMAKING_SEARCH_SECONDS` = 90,
`app.matchmaking.duel-seconds` / `PRIVATE_DUEL_SECONDS` = 600;
`app.matchmaking.scheduling.poll-ms` = 500. Для управляемых тестов можно отключить
`app.matchmaking.scheduling.enabled` и вызывать poll с внедряемым Clock.
Scheduler использует отдельный поток и начинает работу после battle recovery.
Профиль question-import его не запускает.

Очереди, комнаты и их терминальные snapshots находятся в памяти одного процесса
и теряются после рестарта; их GET затем возвращает 404, activity — NONE.
Сохранённые незавершённые батлы отменяются существующим SERVER_INTERRUPTION recovery;
завершённые результаты сохраняются. Масштабирование на несколько экземпляров
и очистка долгоживущего registry не входят в MVP. Production-банк не добавлен.

Проверка сценариев этапа 5 **из backend/** (Docker/PostgreSQL):

```powershell
.\mvnw.cmd -B -ntp '-Dtest=MatchmakingPostgresTest' test
.\mvnw.cmd -B -ntp verify
```

## Архитектура и проверки

Пакеты разделены по слоям: `controller`, `dto`, `mapper`, `processor`, `service`,
`entity`, `repository`, `config`, `exception`, `handler`. Сервисы имеют интерфейс
и Impl и работают со своим единственным repository; JPA entity не выходят
из service в processor/controller. MapStruct использует constructor injection
и `unmappedTargetPolicy=ERROR`, служебные поля при создании явно игнорируются.
`BaseEntity` содержит UUID, аудит `LocalDateTime` в UTC и soft delete.
`PageResponse<T>` возвращает `data` и `pagination`; базовый размер страницы 20,
максимум 100. При добавлении списковых API используйте page с нуля и
сортировку по умолчанию `createdAt,desc`; сейчас списковых endpoints нет.

Unit/MVC-тесты проверяют purpose/expiry/signature JWT, UTF-8 пароль,
ошибки Security, валидацию, нормализацию ключей и auth-оркестрацию.
`AuthPostgresTest` проверяет Flyway + Hibernate validate, полный auth-цикл,
конкурентный refresh, независимость сессий, soft delete, активную уникальность
и публичность Swagger. Используются только случайные локальные тестовые аккаунты.

На уже запущенном локальном сервере можно проверить HTTP-цикл (из `backend/`, Python 3.10+):

```powershell
python scripts/smoke_auth.py
# Если порт отличается:
python scripts/smoke_auth.py --url http://127.0.0.1:18080
```

Скрипт создаёт одного случайного тестового пользователя в указанной локальной БД,
проверяет регистрацию, профиль, login, refresh/replay/logout, независимость сессий
и Swagger. Токены и пароли не выводятся; удаление аккаунта через HTTP пока не предусмотрено.

При создании каркаса 2026-11-14 проверены: сборка Java 21, `verify` (23 теста, без ошибок и пропусков,
включая PostgreSQL Testcontainers), затем 6 MVC-тестов после уточнения валидации
пароля, Docker-сборка и запуск через Compose с отдельным тестовым env-файлом,
HTTP smoke на порту 18080. Временный Compose-проект и его тестовая БД после проверки удалены.

Для этапа 2 проверено: `.\mvnw.cmd -B -ntp verify` — 45 тестов, без ошибок
и пропусков, включая 12 PostgreSQL-интеграционных сценариев (auth + этап 2).
Проверены обновление V1 → V2 с backfill, атомарность регистрации, независимость
рейтингов, ранги, оба новых API, недостаточный банк, ревизии, идемпотентность
без изменения аудита, конкурентные импорты, активная уникальность и UTC.
Отдельно реальный JAR запущен с профилем `question-import`: dry-run оставил
0 вопросов; применение добавило 7 тестовых записей; повтор оставил 7;
невалидный файл завершился с ненулевым кодом. Временная PostgreSQL удалена.

Для этапа 3 проверено 2026-11-14: итоговый `verify` — 82 теста, 0 ошибок и
пропусков. Из новых: 24 теста чистого движка и 13 PostgreSQL-сценариев.
Проверены точные границы времени/бонуса, неизменность объявленного дедлайна
после PostgreSQL round-trip, снимки, персональное сокрытие, гонки,
однократное Elo и rollback после flush рейтинга. На отдельной временной
PostgreSQL запущен обычный JAR с включённым scheduler/recovery, проверены
реальные HTTP auth/API и профиль импорта без HTTP-сервера. Процесс и временная
БД после проверки удалены. На этом этапе проверки движка использовали внутреннее
создание матча и test-only presence. Реальный adapter добавлен на этапе 4.

Защита от недавних повторов проверена итоговым `verify`: 92 теста, без ошибок
и пропусков. Добавлены 3 unit-теста приоритетов/случайных равных давностей
и 7 PostgreSQL-сценариев: оба участника и режима, окно начавшихся батлов,
предметы, непоказанные раунды, настраиваемый размер окна, fallback,
неактивные/soft-deleted ревизии и маленький банк. Формат публичного API не изменён.

Для этапа 4 итоговый `verify` — 117 тестов, 0 ошибок и пропусков.
Из новых: 20 PostgreSQL-сценариев с настоящими native WebSocket/STOMP-подключениями
и 5 проверок границ presence в чистом движке. Проверены JWT/refresh/expiry,
запрет подписок и SEND, same-origin, изоляция игроков и сокрытие ответов,
readiness, commit/rollback, замена сеанса, unsubscribe/DISCONNECT, reconnect,
heartbeat timeout и однократное Elo. Heartbeat/expiry и опрос БД работают
на отдельных scheduler; уведомления обрабатываются отдельным executor.
Дополнительно проверен собранный Java 21 JAR: обычный запуск с scheduler/recovery,
HTTP auth/API и dry-run `question-import` без HTTP/WebSocket-сервера.
Временные процессы и PostgreSQL после проверки удалены. Публичный контракт,
порядок вопросов и защита от недавних повторов сохранены.

Для этапа 5 итоговый `verify` — 145 тестов, 0 ошибок и пропусков.
Добавлены 28 PostgreSQL-сценариев: границы и взаимность окон, FIFO и предметные
рейтинги, ownership/HTTP-валидация, конкурирующие активности, cancel/match/expiry,
параллельные и повторные join, блокировка до внешнего commit/rollback,
ошибка после flush, освобождение активности и восстановление после рестарта.
Настоящие STOMP-подключения проверяют QUEUE_CHANGED/PRIVATE_DUEL_CHANGED,
приватность, commit/rollback, общий battleId и неизменность Elo в PRIVATE.
Проверен собранный JAR с обычными scheduler/recovery: все восемь новых routes,
Bearer security и поля ответов в generated OpenAPI, ranked/private HTTP flow,
activity и явный dry-run/apply test-only fixtures без web-сервера импорта.
Временные процессы и БД удалены; публичный контракт 0.2 не изменён.
