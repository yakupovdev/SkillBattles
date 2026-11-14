# SkillBattles backend

Технический каркас и авторизация: Java 21, Spring Boot 3.5.16, Spring MVC / JPA /
Security Resource Server, PostgreSQL 17.12, Flyway, Validation, Lombok, MapStruct 1.6.3,
springdoc 2.10.0. Maven Wrapper 3.3.4 запускает Maven 3.9.12. Остальные зависимости
зафиксированы BOM Spring Boot; их версии не переопределяются вручную.

Версии сверены с [Spring Boot 3.5](https://docs.spring.io/spring-boot/3.5/),
[матрицей springdoc](https://springdoc.org/v2/faq.html#_what_is_the_compatibility_matrix_of_springdoc_openapi_with_spring_boot),
[MapStruct](https://mapstruct.org/documentation/stable/reference/html/),
[PostgreSQL](https://www.postgresql.org/support/versioning/).
Boot 3.5.16 — последний OSS-релиз требуемой ветки 3.5.x; переход на другую ветку
потребует отдельной задачи. Батлы, рейтинги, контент, matchmaking и realtime пока не реализованы.

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

## Структура и проверки

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

Проверено 2026-11-14: сборка Java 21, `verify` (23 теста, без ошибок и пропусков,
включая PostgreSQL Testcontainers), затем 6 MVC-тестов после уточнения валидации
пароля, Docker-сборка и запуск через Compose с отдельным тестовым env-файлом,
HTTP smoke на порту 18080. Временный Compose-проект и его тестовая БД после проверки удалены.
