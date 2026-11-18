# Data Layer — Sources, HTTP, Pagination, Models

> Part of the mandatory architecture rules: split out of `.claude/rules/architecture.md` (data sources, HTTP, pagination, models, repository and use-case details). Same scope and source-fidelity notes as there: "Existing project conventions" are the original rules, "Added safeguards" apply where compatible with the repository.

## Existing project conventions

### Data sources and HTTP

- Use interface/implementation pairs: `ItemsRemote` / `ItemsRemoteImpl`, `ItemsLocal` / `ItemsLocalImpl`.
- Keep a source contract and its small implementation in the same file.
- Inject HTTP clients, SDKs, and storage through constructors. Reuse the existing shared client abstraction.
- Limit a source to external service calls, reads/writes, and parsing external formats.
- Return the model (`Future<XModel>`, or `Future<void>`), never `Either`: a remote source only sends the request and converts the JSON into the model. Errors propagate as exceptions; see `errors.md`.
- Centralize URL settings, headers, timeouts, and transport error handling.
- Every API path, header name, and hand-written request key lives in `AppApi` (`lib/core/utils/network/app_api.dart`), grouped by feature: endpoints (`AppApi.sendCode`), keys of request maps built in sources (`AppApi.phoneKey`), field keys reported in validation `errors`, and `AppApi.baseUrl` (from `--dart-define=API_BASE_URL`). Sources and interceptors reference these constants; no string literal endpoints or keys anywhere else. Model JSON keys are not listed there: they come from model field names. A key shared by several features is declared once. Domain field-key classes (e.g. `AccountFields`) alias the `AppApi` constants instead of repeating the strings.
- Large network bodies are already decoded off the UI isolate: postgrest buffers each answer with `http.Response.fromStream`, whose `contentLength` is the real byte count whatever the HTTP client reported, and decodes a body over 10 000 bytes in its JSON isolate. Remote sources stay "request, then `fromJson`" and add no isolates of their own.
- Forward every parameter declared by the API: query, body, options, cancellation, and callbacks. Do not silently ignore arguments.
- Validate JSON structure before accessing fields, indexing collections, or casting types.
- Move complex response parsing into a parser within the relevant feature.
- Do not add `try/catch` blocks that only rethrow an exception without doing anything else.
- Place test fakes and mocks in `test/`, not in production sources.

### Pagination

- Page only lists that grow without bound (a property's bookings per period, guests, contracts). Bounded lists (properties, team, channels, calendar weeks, today's tasks, capped searches) stay whole.
- The server returns `nextCursor` as opaque text (`null` on the last page). The client never parses or builds a cursor; it sends it back verbatim. The first page is requested with no cursor; the page size is the single `pageSize` constant in `lib/core/utils/pagination/page_size.dart`.
- One page is a `PageEntity<T>` (`lib/core/utils/pagination/page_entity.dart`: unmodifiable `items`, `nextCursor`, `hasMore`, `followedBy`/`appendUnique` for appending without duplicate ids). The params entity of a paged use case carries the cursor (`GetGuestPageParamsEntity(query:, cursor:)`).
- BLoC per paged list: the existing `loadStatus` drives the first page (skeleton, error, refresh); a separate load-more status and failure per list (`loadMoreStatus`/`loadMoreFailure`, `guestsLoadMoreFailure`) drives the next pages. `<List>NextPageRequested` uses `droppable()` and is ignored without a `nextCursor`, while the first page loads, or while a load-more runs. A version counter drops a load-more result when a refresh, new query, property, or period started after it. A refresh replaces the list with the new first page; appended pages skip items whose id is already shown.
- Every loaded page is cached under its cursor (see `local_database.md`, "Feature local sources").

### Entities, models, mapping

- Name domain entities `<Name>Entity` and data models `<Name>Model`.
- Use `const` constructors, named parameters, and `final` fields.
- Use `Equatable` for entity value equality; include all meaningful fields in `props`.
- Do not add UI controllers, context, callbacks, or external SDK objects to entities.
- Preserve semantic types: `Duration`, `DateTime`, and numbers. Handle display formatting separately.
- Keep JSON serialization in the data layer.
- Every model uses `json_serializable` (`@JsonSerializable`, `part '<file>.g.dart';`, `_$<Model>FromJson` / `_$<Model>ToJson`). No hand-written `fromJson`/`toJson` bodies.
  - Never use `@JsonKey(name: ...)`. Name each field exactly like its API key (`city`, not `cityId` for the key `city`; `errors`, not `fieldErrors`), so the generated key is the field name. Renaming a model field changes the API contract; check the generated `.g.dart` keys after a rename.
  - `@JsonKey` is only for behavior: `required: true`, `fromJson:`/`toJson:` readers, `defaultValue:`, `includeIfNull:`.
  - Response models: `@JsonSerializable(checked: true, createToJson: false)` with `factory X.fromJson(Map<String, dynamic> json) => _$XFromJson(json);`. Mark mandatory keys `required: true`. Invariants the generator cannot express (non-negative int, non-empty string) go in a private top-level `@JsonKey(fromJson: ...)` reader in the same file that throws `ParsingException`.
  - Request models: `@JsonSerializable(createFactory: false)` with `Map<String, dynamic> toJson() => _$XToJson(this);` and a `fromEntity(<Action>ParamsEntity)` factory.
  - Generate only the direction that is used (`createToJson: false` / `createFactory: false`). A response model that is cached uses both: `@JsonSerializable(checked: true, explicitToJson: true)` with `toJson()` (see `local_database.md`).
  - Generated `fromJson` throws `CheckedFromJsonException`; the repository's `mapExceptionToFailure` turns it into `ParsingFailure` with only class, key, and error text (never the raw map, which can hold tokens).
  - Remote sources read a body with `XModel.fromJson(asJsonObject(json))` (`lib/core/utils/network/json_object.dart`); `asJsonObject` rejects a body that is not a JSON object with `ParsingException`.
  - After changing a model run `dart run build_runner build --delete-conflicting-outputs` and commit the `.g.dart` files. Never edit `.g.dart` by hand.
- Implement model-to-entity conversion as a `toEntity()` method on the model. Convert nested models through their own `toEntity()` methods.
- Convert model lists in the repository using `map(...).toList()`.
- Add `fromJson`, `toJson`, `fromEntity`, and `copyWith` only when required by actual operations.
- Follow the project's existing serialization approach. Do not introduce a second generation mechanism or parallel DTOs for the same task.

## Added safeguards

### Usecase contract details

- Honor the shared project's generic signature exactly: `Usecase<Result, Params>` and `Result call(Params params)`. `Result` is the *full* declared type (for example, `Future<Either<Failure, List<ItemEntity>>>`).
- For a no-argument operation, use the existing `NoParams` type and pass its project-defined instance/value; do not invent a second `NoParams`.
- Params are `<Action>ParamsEntity` value objects in `domain/entity/`; validate required business invariants at the correct use-case/domain boundary, without duplicating the same validation in multiple screens. Make a field non-nullable when the form guarantees it (e.g. a selected city).
- Preserve typed failures returned by the repository. A simple delegation should not wrap or reinterpret `Either` unnecessarily.
- Business side effects involving multiple steps should have an intentional order and explicitly defined failure behavior. Do not silently perform only some requested writes when the operation implies atomicity.

### Repository consistency

- Specify for each repository method whether it reads remote, reads local, caches a response, or coordinates local and remote. Preserve the established source-of-truth and freshness strategy.
- Do not silently convert network, parsing, permission, or cache failures into success. If a fallback is intentional, document the fallback policy and return semantics.
- Catch external exceptions at the established boundary and convert them to the shared `Failure` hierarchy only there, preserving existing failures and useful error metadata.
- Avoid catch-all exception wrappers that make cancellation or expected failures indistinguishable from programming defects.
- Keep transport-specific types (`Response`, SDK payloads, JSON, `Model`) out of domain contracts and UI state.

### Remote sources and parsing

- Validate response shape before casts or indexing: nullability, collection type, required keys, enum values, and numeric conversions.
- Apply API-provided pagination/query/filter/cancellation parameters consistently at each boundary. Do not drop `CancelToken`, options, headers, callbacks, or body values when forwarding.
- Use the existing shared HTTP client for headers, auth, base URLs, transport errors, and timeouts; do not create an independent client without necessity.
- Keep parsers deterministic and free of UI and navigation effects.
