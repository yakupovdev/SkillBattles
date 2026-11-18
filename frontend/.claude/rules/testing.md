# Testing and Quality Gates — Flutter / Dart

> **Scope:** Mandatory project conventions derived from the provided Musium rule set. Follow existing contracts and user requirements. Do not refactor unrelated code merely to enforce these rules.
> **Source fidelity:** The “Existing project conventions” sections reproduce the user's original rules. “Added safeguards” sections are additional recommendations and must be applied only when compatible with the real repository.

## Existing project conventions

### Tests

- Place tests in `test/`, mirroring the module structure, and use the `_test.dart` suffix.
- Use existing testing tools. Inject fakes/mocks through constructors.
- Do not use real network services or user storage in unit tests.
- Name tests after the subject, condition, and expected result.
- Test public behavior, failures, and meaningful boundaries rather than implementation internals.
- For modified asynchronous logic, test result ordering, repeated requests, and closure while awaiting a result.
- In widget tests, prepare dependencies and test a real screen scenario.
- Release resources created by tests and clean up DI registrations.

### Task completion

- Remove unfinished stubs, unused imports, and accidental unrelated changes.
- Check dependency injection, DI registrations, mapping, error handling, and nullable-field resets.
- Check asynchronous operation ordering and resource ownership.
- Format modified Dart files, run the analyzer, and run the tests required for the change.
- Report actual verification results. Identify existing failures and checks that were not run separately.

## Added safeguards

### Test locations and isolation

- Mirror production feature structure under `test/features/<feature>/` without reproducing irrelevant empty directories.
- Use the test frameworks and fake/mock libraries already present in `pubspec.yaml`. Do not add a new mocking or BLoC test package without a concrete need.
- Keep unit tests deterministic and independent of real internet, production credentials, user storage, device-dependent state, and actual clock time. Inject fakes or controllable implementations.
- Reset GetIt test registrations/scopes and cancel controllers, streams, timers, and subscriptions in teardown. Avoid test order dependencies. Never register into `GetIt.instance`; use `GetIt.asNewInstance()` and `AppDependencies.fromContainer(...)`.
- Form screen tests fill the form through the UI (`enterText`, picking from sheets), assert validator messages on submit, that invalid forms send nothing to the BLoC, and that the use case receives the expected `ParamsEntity`. BLoC tests add `<Action>Submitted(params)` directly.
- Repository tests use fake remotes that return models and throw configured exceptions (SDK exceptions such as `PostgrestException`/`AuthApiException`, or a `DioException` carrying an interceptor `Failure`). Check the resulting `Left` failure, feature code translations, that later steps (session writes) are skipped after a failure, and that an `Error` thrown by a fake propagates. Exhaustive status → `Failure` mapping is tested in `failure_mapper_test`/`error_interceptor_test`.
- Remote source tests build Dio like production (`AuthInterceptor`, then `ErrorInterceptor`) over `FakeHttpClientAdapter`, or a `SupabaseClient` over a `MockClient`, and assert returned models or thrown exceptions (`ParsingException`/`CheckedFromJsonException` for malformed bodies, a `DioException` whose `error` is the mapped `Failure`, SDK exceptions for Supabase).
- Field widgets: test that a tap on the label and on the box padding focuses the input, and assert borders with paint matchers (`paints..rrect(color:, strokeWidth:)`) instead of reaching into private `Container`/`BoxDecoration` internals.
- Shared generic widgets (e.g. `AppPickerField<T>`) are tested in `test/core/` with plain test data, not feature entities; find their sheet with `find.byType(BottomSheet)`.
- Cache and local database tests follow "Tests" in `local_database.md`: `TestResponseCache` (in-memory drift) for `ResponseCacheImpl` and local sources, `FakeResponseCache` behind the real local source for repositories.
- Model tests call `fromJson` directly and expect `CheckedFromJsonException` for malformed objects, and assert `toJson` keys, since field names are the API keys.
- Screen widget tests pump the screen directly under their own `BlocProvider(create: (_) => bloc)` with fakes; `wrappedRoute` only runs through `GoRouteExtension.wrappedRoute`, so it is skipped there. Router/flow tests exercise `wrappedRoute` through `RouterHarness`, which wraps the app in `AppDependenciesProvider`.

### Coverage by layer

- **Usecases:** success and `Failure` branches, parameter forwarding, boundary validation, and sequence of business operations where relevant.
- **Repositories:** data source selection, `Model.toEntity()` mapping including nested and list values, local/remote coordination, preservation of typed failures, malformed responses, and intentional fallback policies.
- **Remote/local sources:** endpoint parameters, request body/options/cancellation forwarding, JSON shape validation, missing keys, storage read/write/absence semantics, and any returned write-success flag.
- **BLoC/Cubit:** initial state, loading/success/failure, exact event-to-state sequences, independent operation statuses, retries, clearing nullable errors, immutable collections, stale-result protection, and closure during an awaited operation.
- **DI:** factory vs singleton lifetimes, async readiness when applicable, and disposal ownership.
- **Widgets:** real interactions and visible loading/empty/error/success states; navigation and notifications using the existing router/localization setup.
- **Integration tests:** focus on a small set of critical end-to-end scenarios, using test environments and deterministic service doubles where practical.

### Async and race-condition tests

- For overlapping requests, control completion order in the test: complete request B before A and verify A does not replace B when latest-result-wins is required.
- Test an operation that completes after BLoC/Cubit closure and verify no invalid emission or unhandled exception occurs.
- Verify that an async storage write is awaited when a subsequent action relies on it.
- Use fake clocks or controllable timers for debounce/retry where supported; avoid fragile real-time sleeps.

### Quality gates

- Before work, inspect `pubspec.yaml` and `analysis_options.yaml`, relevant test utilities, and existing tests for the affected feature.
- Format only changed Dart files using `dart format <changed paths>`; avoid unrelated formatting diffs.
- Run `flutter analyze` and relevant `flutter test` scopes; run the complete suite when change scope and environment warrant it. Use `dart analyze` if that is the project's established workflow.
- Consider `dart format --output=none --set-exit-if-changed <paths>` as a non-mutating formatting check.
- Do not remove, skip, or suppress failing tests to force green CI. Distinguish new failures from pre-existing failures based on actual evidence.
- Report the exact verification commands and their observed outcomes. If SDK, dependencies, device, or credentials are unavailable, state which checks could not run; do not claim success.

### Delivery checklist

- No unfinished placeholders, dead code, unused imports, accidental unrelated changes, or untracked API/serialization key changes.
- DI registrations are valid; repository methods map models/failures correctly; nullable resets and concurrency rules are correct.
- Documentation and tests reflect changed behavior.
- The completion report identifies changed files, what was tested, failing/pre-existing checks, limitations, and any compatibility or migration risks.
