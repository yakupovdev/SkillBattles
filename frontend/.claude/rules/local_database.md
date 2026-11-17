# Local Database — drift, Response Cache, Offline Fallback

> **Scope:** Mandatory conventions for everything stored in the local SQLite database (drift). They add to `.claude/docs/architecture/local_storage.md`, `architecture.md` ("Repository pattern") and `testing.md`; where they are more specific, they win. The `flutter-localdb` agent owns this area.

## What exists

- `lib/core/utils/database/app_database.dart` — `AppDatabase`, the only drift database (`@DriftDatabase`). It takes its `QueryExecutor` through the constructor: `driftDatabase(name: AppDatabase.fileName, ...)` from `drift_flutter` in `AppDependencies` (file `easy_booking.sqlite` in the application support directory), `NativeDatabase.memory()` in tests.
- `lib/core/utils/database/tables/` — one file per drift table. Today only `cached_responses.dart`.
- `lib/core/utils/database/response_cache.dart` — `ResponseCache` / `ResponseCacheImpl`: copies of server answers as JSON, addressed by owner (the signed-in user's id) + `scope` + `key`. Deletes by key, by scope, and by key prefix (`deleteKeyPrefix`, for the pages of one list).
- `lib/core/utils/database/cache_scopes.dart` — `CacheScopes`: every scope name, grouped by feature (the `StorageKeys` of the cache).
- `lib/core/utils/error/failure_cache_fallback.dart` — `Failure.allowsCacheFallback`.
- `lib/core/utils/session/response_cache_session_sync.dart` — clears the cache on sign-out and at a signed-out start; prunes entries older than `retention` (30 days) at a signed-in start.
- `lib/features/<feature>/data/sources/local/<feature>_local.dart` — `<Feature>Local` / `<Feature>LocalImpl`, the feature's typed facade over `ResponseCache`.

## Caching policy: network first, cache fallback

- A repository **read** calls the remote, saves the model through the feature's local source, and returns the entity. When the remote throws and the mapped failure has `allowsCacheFallback` (`ConnectionFailure`, `TimeoutFailure` — the server was not reached), it returns the cached model mapped to the entity. Without a cached copy, and for every other failure, it returns the failure: any answer of the server, an error included, is newer than the cache.
- A repository **write** never falls back. When it returns a model that a read also returns, it saves that model, so the cache shows the new state (`saveSettings` also saves the property inside the settings). When it makes a cached copy wrong and returns nothing to replace it with, it deletes that copy — also a copy in another scope of the feature: the draft and the booked nights after a booking is created, the channels overview after a channel is synced, the profile summary after the profile, the plan, or the team changed, the guest after a contract was created. For every new write, go through the feature's scopes and decide for each one: saved, deleted, or unaffected.
- A cached model is mapped exactly like a fresh one, at the current `now`.
- The cache never fails a call: `ResponseCache` logs a storage or parsing exception and reports a miss (`null`) or `false`. An entry that no longer parses is deleted; a failed storage read keeps it.
- SQLite already runs off the UI isolate (`driftDatabase` from `drift_flutter` opens a background connection), but the payload returns as text. `ResponseCacheImpl.read` decodes and parses a payload of at least `ResponseCacheImpl.backgroundDecodeLength` (50 000) characters with `Isolate.run`; smaller ones stay inline, where the hop costs more than it saves. An exception inside the isolate comes back as plain text and ends exactly like an inline one (logged, entry deleted, miss); a failed isolate start is a miss that keeps the entry; an `Error` propagates. Do not add isolates around small answers. Repositories do not wrap local calls in their own `try`/`catch` and ignore the `bool` of a save on purpose.
- Every repository method keeps its own explicit `try`/`catch` (no shared runner), in this shape:

  ```dart
  @override
  Future<Either<Failure, HomeOverviewEntity>> getOverview() async {
    try {
      final HomeOverviewModel model = await _remote.getOverview();
      await _local.saveOverview(model);
      return Right(model.toEntity());
    } on Exception catch (exception, stackTrace) {
      final Failure failure = mapExceptionToFailure(exception, stackTrace);
      final HomeOverviewModel? cached = failure.allowsCacheFallback
          ? await _local.getOverview()
          : null;
      return cached == null ? Left(failure) : Right(cached.toEntity());
    }
  }
  ```

- The repository's class comment states what it keeps, the fallback, and what its writes do to the cache.
- Repository and use-case contracts stay `Future<Either<Failure, T>>`. Showing the cache first and refreshing after it (streams) is a different policy: it changes contracts and BLoCs and needs the user's approval first.

## Feature local sources

- One `<Feature>Local` / `<Feature>LocalImpl` per feature, in one file, injected with `ResponseCache` (`const <Feature>LocalImpl({required this._cache})`). A feature whose remote serves several repositories shares one local (`CalendarLocal`).
- Per cached answer: `Future<XModel?> getX(...)` (`null` when nothing is cached) and `Future<bool> saveX(...)` (whether it was stored). Deletes return `Future<bool>` too. They never throw.
- The local source serializes with the model: `json: model.toJson()` and `fromJson: XModel.fromJson`. `ResponseCache` only encodes and decodes JSON text.
- Scope names come from `CacheScopes`; add a constant there for every new cached answer, with a comment saying what the key is. Never write a scope as a string literal.
- The key tells answers of one scope apart: the entity id, or the request arguments exactly as they are sent to the remote (a search query character for character; a day plus a filter as `2026-11-12/favorites`). An answer that exists once per user has the empty key.
- A list answer smaller than the whole list is cached per page, every loaded page, not only the first. Its key is the request arguments joined with `/` and ending with the cursor exactly as sent, empty for the first page (`<propertyId>/<period>/<cursor>`, the period as sent; `<query>/<cursor>`). This relies on server cursors never containing `/` (booking cursors are `<timestamp>~<uuid>`, guest and contract cursors digits); a query may contain `/`, so a chain reset can drop another query's pages, which only costs a fetch. A new cursor format with `/` needs a different key. When the first page is a separate answer (the guest directory is the first page of the guest and contract lists), it keeps its own scope and key (`<query>`) and the later pages get their own scopes.
- A page is read back by the cursor that asked for it, so offline the BLoC walks the cached chain with the `nextCursor` of each cached page. To keep that chain consistent, saving a fresh **first page** first deletes the cached pages of the same list (`deleteKeyPrefix` with the arguments before the cursor, e.g. `<propertyId>/<period>/` or `<query>/`) and stores nothing when that delete fails. Later pages are saved as they come.
- A write that changes a paged list deletes all of its pages. Inside the owning feature, delete exactly the affected lists (`PropertiesLocal.deleteBookings(propertyId)` drops every period of the property with `deleteKeyPrefix('<propertyId>/')`). From another feature, or when any search result can change, delete the whole scope (`CacheScopes.propertyBookingPages`; all queries of the guest lists: `CacheScopes.guestLists`). Decide from what the server function does, side effects included, not from its name: changing a calendar link or a channel link cancels imported bookings (`private.release_imported`), and creating a contract marks the guest's latest booking as having one, so `saveCalendars`, `saveChannelLink`, and `createContract` delete booking pages too.
- When a list answer contains the same full model as the single-item answer, keep one copy: the list is the source and the item is read from it (`PropertiesLocalImpl`).
- Local sources do not return `Either`, do not map to entities, and do not decide the fallback: the repository does.
- A write in one feature that makes another feature's cached copy wrong deletes it through its own local source, with a method over the `CacheScopes` constant (`BookingsLocal.deletePropertyBookings`, `ContractsLocal.deleteGuestLists`). Never import another feature's local source or repeat its key format; delete the whole scope instead.
- `fromJson` passed to `ResponseCache.read` must be sendable to another isolate: a constructor tear-off (`XModel.fromJson`) or a static/top-level function, never a closure that captures an object.

## Models that are cached

- A response model that is cached generates both directions: `@JsonSerializable(checked: true, explicitToJson: true)`, the `fromJson` factory, and `Map<String, dynamic> toJson() => _$XToJson(this);`. Every nested model of a cached model does the same. Models that are not cached keep `createToJson: false`.
- `toJson` must write what `fromJson` reads. A field with a `@JsonKey(fromJson: reader)` that changes the type or the format needs the matching `toJson:` writer next to the reader:
  - `readInstant` / `readInstantOrNull` → `writeInstant` / `writeInstantOrNull` (UTC ISO-8601 with `Z`);
  - `readCalendarDate` → `writeCalendarDate` (`YYYY-MM-DD`);
  - a private reader (`_timeOfDay`, `_cityFromId`, `_channelOfSource`, `_localDateTimeOrNull`) → a private writer in the same file. A moment is always written in UTC with `Z`, so it is the same moment after the device changes its time zone.
  - Readers that only validate (`readNonEmptyString`, `readNonNegativeInt`) and `readLocalDateTime` (the default `toIso8601String()` of a local `DateTime` has no offset) need no writer.
- After changing a model run `dart run build_runner build` and commit the `.g.dart` files.
- A model change needs no database migration: an old entry that no longer parses is deleted on read and fetched again.

## Schema and migrations

- Tables live in `lib/core/utils/database/tables/<table>.dart` and are listed in `@DriftDatabase(tables: ...)`. After any table change raise `AppDatabase.schemaVersion` and regenerate.
- The database holds only data that can be fetched again, so `onUpgrade` (which also runs for a downgrade) drops every table and creates the schema again. Keep it that way while this is true.
- Before adding a table whose rows cannot be fetched again (data created on the device), replace that `onUpgrade` with step-by-step migrations (`drift_dev schema dump` + generated steps and migration tests) — this is an architectural change that needs the user's approval.
- Prefer a new scope in `cached_responses` over a new table. Add a typed table only when the app must query the data in SQL (search, sort, join, partial updates); then access it through a class in `lib/core/utils/database/` or a drift DAO, never from a repository or the UI.
- Only code under `lib/core/utils/database/` and `AppDependencies` imports `package:drift` or `drift_flutter`. Features see `ResponseCache` (or another interface declared there).

## Ownership, privacy, lifetime

- Every entry belongs to the user who was signed in when it was written; reads and writes without a signed-in user do nothing. `ResponseCacheImpl` gets the id through `ownerId` (the Supabase user in `AppDependencies`).
- Signing out clears the cache (`ResponseCacheSessionSync`). Do not cache anything that must outlive the session, and never cache credentials, tokens, or one-time codes (auth answers are not cached).
- The log line of a cache failure has the operation and the scope only; never the key or the payload.
- `AppDatabase` and `ResponseCache` are lazy singletons registered in `_registerStorage`; the database is closed by its GetIt dispose callback. Feature locals are registered in `_registerSources`.

## Tests

- `ResponseCacheImpl` and `AppDatabase`: `test/core/utils/database/`, over `NativeDatabase.memory()` through `test/helpers/test_response_cache.dart` (`TestResponseCache`). `deleteKeyPrefix` with `%`, `_`, upper case, and non-ASCII keys; a payload over the background threshold read back, and rejected and deleted.
- Local sources: `test/features/<feature>/data/sources/local/<feature>_local_test.dart`, over `TestResponseCache`: `null` when nothing is saved, each model read back equal (`toEntity()` and `toJson()`), keys, deletes, the owner, an entry that no longer parses.
- Repositories: built with the real `<Feature>LocalImpl(cache: FakeResponseCache())` (`test/helpers/fake_response_cache.dart`). For every read: the answer is kept; it is returned for `ClientException` and `TimeoutException`; the failure is returned when nothing is kept; a server failure is returned although a copy is kept; the fresh answer is returned when `cache.succeeds = false`. For every write: what it saves or deletes, and that a failed write changes nothing. For a paged read: each page under its cursor, a fresh first page drops the kept later pages of its list only, and offline page N is found by the cursor of page N-1.
- Models: `fromJson(json).toJson()` parses again to the same entity and the same map, and `jsonEncode(model.toJson())` does not throw.
- `RouterHarness` registers a `FakeResponseCache` behind every feature local.
