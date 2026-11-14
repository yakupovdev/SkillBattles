# SkillBattles — v0.3 stage C

Промежуточная ветка обновления, **не готовый релиз v0.3**. Реализованы каталог,
scoring/streak, overtime, индивидуальная калибровка, рейтинговые сезоны и этап C:
Stripe TEST, entitlements, квоты и персональная выдача истории/ответов. Полные локальные
документы `SKILLBATTLES_BACKEND_V0_3.md` и `OPENAPI_V0_3.yaml` описывают конечный
контракт из 42 операций; наличие операции в них не означает, что она реализована.
Generated Swagger помечен версией `0.3.0-stage-c` и показывает фактический API.

Java 21, Spring Boot 3.5.16, MVC/JPA/Security Resource Server, PostgreSQL 17.12,
Flyway, MapStruct 1.6.3, Lombok, Validation, springdoc 2.10.0. Maven Wrapper 3.3.4
запускает Maven 3.9.12. Runtime не требует Node/Python, Redis или внешнего брокера.

## Что работает сейчас

- JWT access/refresh, ротация refresh, logout и изоляция токенов по назначению.
- Динамический каталог активных дисциплин из PostgreSQL: `SAT_MATH`, `SAT_RW`.
  Код дисциплины — строка, не Java/frontend enum. Вопросы — SINGLE_CHOICE, 4 опции.
- `mode=RANKED|PRIVATE` обозначает соревнование, `format=STANDARD` — формат.
- `GET /api/v1/battle-modes`: имена, формат, тайминги сложностей, пять основных
  раундов, сетки и обеспеченность контентом с отдельным MEDIUM-резервом.
- `GET /api/v1/ranks`: все 27 рангов Bronze I → Legend. Рейтинг 1000 — SILVER_I,
  Legend от 3200 без верхней границы. Snapshot/result используют коды справочника.
- Stripe TEST Checkout/Portal, signed webhooks, серверные entitlements, Free quota
  и history/answer access, персональный ACCOUNT_CHANGED, daily/weekly streak.
- Пять раундов, боевой streak, overtime, индивидуальный Elo K, lifetime-калибровка
  и квартальные сезоны ET с архивом пиков/итогов.
- Ranked matchmaking, private code duels, единая activity, готовность, таймеры,
  surrender/технические исходы, история, review, native STOMP и reconnect.
- Идемпотентность ответов, сериализация переходов, атомарность результата/Elo,
  after-commit события, rollback и сокрытие ответов до REVEAL сохранены.

## Отдельная база для обновления

V1–V7 сохранены, V8 добавляет подписки/receipt, quota ledger, qualifying days
и индексы истории по finishedAt. V7 добавляет калибровку, пики и архивы сезонов. V5 создаёт каталоги дисциплин/рангов, V6 переводит ключи на
`discipline_code`, добавляет topicCode и формат. V6 **отказывается** мигрировать
базу с вопросами или батлами v0.2. Совместимый адаптер старых snapshots не входит
в этап A; миграция ничего не удаляет. Используйте отдельную чистую dev/test БД,
не удаляйте существующую БД/volume и не редактируйте применённые миграции.

Для Compose создайте из корневого `.env.example` новый `.env.v03` (только если
его ещё нет). Укажите, например, `POSTGRES_DB=skillbattles_v03`,
`POSTGRES_PORT=55432`, `BACKEND_PORT=18083`, случайные POSTGRES_PASSWORD/JWT_SECRET.
JWT_SECRET — Base64 минимум 32 случайных байт. Генерация в PowerShell:

```powershell
$dbSecret = [Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(24))
$jwtSecret = [Convert]::ToBase64String([Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
# Сохраните значения только в локальный .env.v03; не публикуйте их.
Remove-Variable dbSecret,jwtSecret
```

Из корня, отдельный project name создаёт отдельный dev volume:

```powershell
docker compose -p skillbattles-v03 --env-file .env.v03 config --quiet
docker compose -p skillbattles-v03 --env-file .env.v03 up -d --build
docker compose -p skillbattles-v03 --env-file .env.v03 logs backend
docker compose -p skillbattles-v03 --env-file .env.v03 down
```

Не добавляйте `-v`: dev-данные должны сохраняться. Compose передаёт DB/JWT ENV
явно; Spring Boot сам `.env` не читает. Все процессы/БД хранят время в UTC.

Для JVM загрузите локальный файл ENV, затем **из backend/**:

```powershell
Get-Content ..\.env.v03 | ForEach-Object {
    if ($_ -match '^([A-Z][A-Z0-9_]*)=(.*)$') {
        [Environment]::SetEnvironmentVariable($Matches[1], $Matches[2], 'Process')
    }
}
$env:DB_URL = "jdbc:postgresql://localhost:$($env:POSTGRES_PORT)/$($env:POSTGRES_DB)"
$env:DB_USERNAME = $env:POSTGRES_USER
$env:DB_PASSWORD = $env:POSTGRES_PASSWORD
$env:SERVER_PORT = $env:BACKEND_PORT
.\mvnw.cmd spring-boot:run
```

DB_URL/DB_USERNAME/DB_PASSWORD обязательны для выбранной JVM-базы; JWT_SECRET —
для подписи HS256. JWT_ISSUER=`skillbattles`, JWT_ACCESS_TTL=`PT15M` (максимум
15 минут), JWT_REFRESH_TTL=`P7D`. Java 21 задаётся через JAVA_HOME.
Swagger: `/swagger-ui.html`, JSON `/v3/api-docs`, без авторизации.

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
импорта при старте сервера. **Из backend/**, ENV выбранной отдельной базы:

```powershell
.\mvnw.cmd -B -ntp verify
& "$env:JAVA_HOME/bin/java.exe" -jar target/backend-0.0.1-SNAPSHOT.jar --spring.profiles.active=question-import --questions.file=C:/data/questions.json
& "$env:JAVA_HOME/bin/java.exe" -jar target/backend-0.0.1-SNAPSHOT.jar --spring.profiles.active=question-import --questions.file=C:/data/questions.json --questions.apply=true
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

## Stripe TEST и entitlements

Stripe Java SDK **34.0.0**, API **2026-10-28.endive** зафиксированы. Используется
экземпляр StripeClient, без глобального API key; методы v1 через SDK rawRequest
с явным Stripe-Version. GET query передаётся в URL, POST — form-urlencoded.
Billing period читается из subscription.items.data[0].current_period_start/end,
а не из удалённых корневых полей старых Stripe API.

Операции: GET /api/v1/subscriptions/plans (public), GET /subscriptions/me,
POST /subscriptions/checkout, POST /subscriptions/portal (access JWT),
POST /subscriptions/webhook (только Stripe-Signature, без JWT) и
GET /api/v1/users/me/limits. Префикс всех subscription paths — /api/v1.
FREE: 0; PRO_MONTHLY: 799 USD cents/month; PRO_ANNUAL: 4799 USD cents/year.
Checkout request содержит только planCode и UUID requestId. Цена, userId,
customerId, price ID и return URLs от клиента не принимаются.

Без Stripe ENV приложение работает как Free, checkoutAvailable=false,
Checkout/Portal отвечают 503 BILLING_UNAVAILABLE. Публичной смены тарифа нет.
Настройки в backend/.env.billing.example; добавьте их в локальный .env.v03
и загрузите в JVM так же, как DB/JWT ENV, либо передайте через Compose:

| ENV | Значение |
|---|---|
| BILLING_MODE | Только TEST |
| STRIPE_SECRET_KEY | Предпочтительно restricted test key rk_test_; sk_test_ также поддерживается. Никогда live key |
| STRIPE_WEBHOOK_SECRET | whsec_ конкретного endpoint/Stripe CLI listener |
| STRIPE_PRICE_PRO_MONTHLY | Test recurring Price: USD 799, month, count=1 |
| STRIPE_PRICE_PRO_ANNUAL | Test recurring Price: USD 4799, year, count=1 |
| BILLING_SUCCESS_URL | Доверенный frontend success URL |
| BILLING_CANCEL_URL | Доверенный frontend cancel URL |
| BILLING_PORTAL_RETURN_URL | Доверенный frontend URL возврата из Portal |

Ключи/URLs — только server ENV. Redirect URLs требуют HTTPS, в localhost dev
разрешён HTTP. Checkout/Portal — hosted Stripe UI, frontend publishable key
не нужен. API проверяет фактические Price currency/amount/interval перед
Checkout. Настройте test Customer Portal в sandbox Dashboard. Используйте
отдельные test sandboxes для разработки и CI; родитель платит из аккаунта
учащегося, отдельной parent-модели нет. Нужны минимальные разрешения test key
для Customers, Prices, Checkout, Subscriptions/Invoices и Customer Portal.

Checkout резервируется в PostgreSQL по user/requestId, повтор того же payload
возвращает сохранённую session. Другой requestId при незавершённой покупке:
409 CHECKOUT_IN_PROGRESS. Существующая подписка блокирует вторую покупку:
409 SUBSCRIPTION_ALREADY_ACTIVE, менять её следует через Portal. Повторяйте
неопределившийся запрос после 503 с тем же requestId; он использует Stripe
idempotency key. После истечения 24h неопределённой резервации нужен новый ID.
Успешная paid activation закрывает резервацию; старое событие cancellation
не освобождает новый открытый Checkout. Клиентские return URLs/redirect success
никогда не предоставляют Pro. Billing network-запросы выполняются вне DB TX;
однопроцессный lock сериализует Checkout/webhooks, записи фиксируются короткими TX.

Webhook проверяет исходный raw UTF-8 body, Stripe-Signature и окно 300 секунд
через SDK и внедряемый Clock. Live events/objects отклоняются. Обрабатываются:
checkout.session.completed, checkout.session.async_payment_succeeded,
invoice.paid, invoice.payment_failed, customer.subscription.created/updated/deleted.
Receipt по eventId фиксируется с состоянием аккаунта в одной транзакции;
повтор — 204, при ошибке provider — 503 без receipt (Stripe повторит доставку).
Непривязанные customers/неиспользуемые типы событий игнорируются без выдачи прав.
Каждое изменение перечитывает актуальное состояние subscriptions/invoice у
provider под billing lock: старый invoice.paid не оживляет отменённый Pro.

Pro требует ACTIVE, подтверждённый paid invoice, разрешённый Price и текущее
время внутри оплаченного period. INCOMPLETE/PAST_DUE/UNPAID/CANCELED/EXPIRED —
без Pro. Scheduled cancellation сохраняет доступ до periodEnd; на самом end
доступ уже закрыт даже до webhook. Expiry job проверяет периоды раз в секунду.
Права не берутся из JWT. Операции аккаунта увеличивают version; ACCOUNT_CHANGED
публикуется персонально после commit. Его AccountState содержит own user,
subscription, limits и streaks. Клиент перечитывает snapshot/review после этого
события, даже если battle.version не изменился. Entitlement version в snapshot
инвалидирует старую персональную view; версии разных ресурсов не сравниваются.
Уже увиденные/скопированные ответы технически отозвать невозможно.

Локальный Stripe CLI listener (отдельный test sandbox):

```powershell
stripe listen --forward-to http://localhost:18083/api/v1/subscriptions/webhook --events checkout.session.completed,checkout.session.async_payment_succeeded,invoice.paid,invoice.payment_failed,customer.subscription.created,customer.subscription.updated,customer.subscription.deleted
```

Подставьте whsec_ именно этого listener в ENV и перезапустите backend.
Создайте Checkout через авторизованный REST, откройте возвращённый URL и
используйте только Stripe test payment methods. Для позитивной проверки нужен
customer, привязанный приложением: случайный stripe trigger с чужим customer
не должен повышать тариф. При разных sandbox/ключах CLI укажите нужный профиль
или окружение CLI, не публикуя ключ в истории shell.

Stripe Tax/automatic_tax не включены. Перед реальными платежами нужна отдельная
[налоговая настройка](https://docs.stripe.com/billing/taxes/collect-taxes);
этап C реализует только test billing и не считается production billing release.
Документация: [webhooks](https://docs.stripe.com/billing/subscriptions/webhooks),
[подпись](https://docs.stripe.com/webhooks/signature),
[sandboxes](https://docs.stripe.com/sandboxes).

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

## Временные отличия от конечного OPENAPI_V0_3.yaml

- Не реализованы age-screen, profile PATCH/password reset, полные базовые метрики
  accuracy/avg time/win streak, расширенная аналитика/leaderboard и функции D/E
  rematch/report/similar practice. Statistics матчей пока W/L/D/played, без
  фиктивных topicStats/ratingHistory. Pro entitlements задают права плана, но
  наличие права не означает, что отложенная операция уже доступна.
- mistakesOnly не реализован, review показывает mistakesOnly=false. Review
  сохраняет промежуточное поле format этапа A. Frontend-спецификация отсутствует;
  сокращённая замена не создавалась. Ориентируйтесь на фактический Swagger stage C.
- Billing — однопроцессный TEST. Реальные Checkout/Portal round trips проверяются
  только при наличии sandbox keys; подписанные fixtures и SDK payload tests их
  не заменяют. Provider lists обрабатываются с пагинацией. При нескольких
  открытых provider subscriptions адаптер отвечает fail-closed BILLING_UNAVAILABLE
  для reconciliation, не выбирая случайную подписку.
- Generated Swagger — 0.3.0-stage-c, не все 42 конечные операции. Ветка остаётся
  промежуточной и не является готовым релизом v0.3.

Следующий этап — D: полная базовая статистика, Pro-аналитика, leaderboard,
профиль и восстановление пароля; затем E.

## Проверки

К существующим проверкам scoring/overtime/калибровки/сезонов добавлены signed
webhook fixtures, SDK payload/version/period, duplicate/out-of-order/payment failure,
конкурентный Checkout, last ticket/refund/downgrade/start, ET midnight/DST,
last10-before-filter и все пути redaction, daily/weekly streak, реальные
REST/STOMP ACCOUNT_CHANGED и rollback. Используются отдельные PostgreSQL контейнеры.

Проверено на Java 21 / PostgreSQL 17.12: итоговый `verify` — **306 тестов,
0 failures/errors/skipped**, JAR собран; V8 и ddl-auto=validate проверены на чистых БД.
Реальные REST/STOMP из JAR, включая ACCOUNT_CHANGED и возврат quota после
рестарта/recovery, пройдены. Также проверены Compose config, JS/Python syntax
и `git diff --check`. Stripe sandbox keys в окружении отсутствовали: реальные
provider Checkout/Portal round trips не запускались. Stripe-проверки выполнены
на подписанных fixtures, тестовом provider adapter и SDK request/response fixtures.

Из backend/, Java 21 и Docker:

```powershell
.\mvnw.cmd -B -ntp '-Dtest=BillingPostgresTest,BillingRealtimePostgresTest,StripeBillingClientTest,StreakCalculatorTest' test
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
Runner принудительно исключает STRIPE_/BILLING_ deployment ENV, проверяет Free
fallback, квоту, masked review, ACCOUNT_CHANGED наряду с прежними flow. Он не
выполняет платежи даже при наличии ключей в пользовательском окружении.

Frontend-спецификация отсутствует; сокращённая замена не создавалась. Production-банк
не поставляется. До предметного демо нужны разрешённые/проверенные SAT-вопросы,
достаточные пулы всех требуемых сложностей, успешный dry-run/apply и frontend,
согласованный с фактическим этапом API.
