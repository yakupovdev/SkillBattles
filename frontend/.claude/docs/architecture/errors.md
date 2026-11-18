# Errors — Failure and Either

> Part of the mandatory architecture rules: split out of `.claude/rules/architecture.md` (the full error-handling rules). Same scope and source-fidelity notes as there: "Existing project conventions" are the original rules, "Added safeguards" apply where compatible with the repository.

## Existing project conventions

### Failure and Either

- All shared error code lives in `lib/core/utils/error/` and nowhere else: `app_exception.dart` (technical `AppException` hierarchy thrown by data sources/storage), `failure.dart` (sealed `Failure` hierarchy returned through `Either.left`), `failure_mapper.dart` (`mapExceptionToFailure`, the only exception → `Failure` conversion, called from repository implementations), and `failure_message.dart` (`Failure.userMessage` for presentation). Add new shared exceptions, failures, or mapping there; never define a shared error type inside a feature or another `core` folder.
- Keep the distinction: data sources and storage throw `AppException` subtypes (or let `DioException` propagate); repositories convert them with `mapExceptionToFailure`; domain and presentation only see `Failure`.
- Remote sources throw, repositories catch:
  - `ErrorInterceptor` (`lib/core/utils/network/interceptors/error_interceptor.dart`) is the last Dio interceptor (before the logger). It maps every `DioException` with `mapExceptionToFailure` and stores the `Failure` as `DioException.error`; `mapExceptionToFailure` returns that stored failure unchanged.
  - `ApiClient` methods return the response body (`Future<Object?>`) and let the `DioException` propagate.
  - Supabase remotes take `SupabaseClient` through the constructor and call it directly (no wrapper). The SDK throws `AuthException`/`PostgrestException` after the HTTP client has returned the response, and `gotrue` wraps any exception thrown by the HTTP client into `AuthRetryableFetchException`, so Supabase errors cannot be mapped in an HTTP client interceptor: `mapExceptionToFailure` maps them.
  - Remote sources contain no `try`/`catch`, no `Either`, and no wrappers around the call: request, then `fromJson`. They may throw `ParsingException` for a result of the wrong shape.
  - Storage boundaries that callers use directly (`AuthSession.signIn`/`signOut`) catch `StorageException` themselves and return `Either<Failure, void>`.
- Each repository method that calls a remote has its own explicit `try`/`catch` (no guard/runner helpers): the whole success path inside `try`, and `on Exception catch (exception, stackTrace)` returning `Left(mapExceptionToFailure(exception, stackTrace))`. Feature-specific code translation (e.g. Supabase Auth codes → `AuthErrorCodes`) is applied to that failure in the repository.

  ```dart
  @override
  Future<Either<Failure, OtpChallengeEntity>> sendCode(String phone) async {
    try {
      final OtpChallengeModel model = await _remote.sendCode(phone);
      return Right(model.toEntity(phone: phone));
    } on Exception catch (exception, stackTrace) {
      return Left(mapExceptionToFailure(exception, stackTrace));
    }
  }
  ```

- When a repository saves a result locally, the local write returns what the caller needs (e.g. `ProfileMockLocal.setCurrentUser` returns the summary); do not write and then read the same value back.
- Only `Exception`s become failures; an `Error` (a programming defect) always propagates.
- Only feature-specific error vocabulary stays in the feature: API/field error code constants in `domain/entity/<feature>_error_codes.dart`, and failure → user text extensions (e.g. `AuthFailureMessage`) in that feature's presentation layer, falling back to `userMessage`. If such code becomes needed by a second feature, move it to `core/utils/error/`.
- Reuse the shared `Failure` hierarchy and the project's `Either` type.
- When creating the hierarchy, declare the base `Failure` as `sealed` and concrete failures as `final`.
- Distinguish connection, timeout, server, validation, storage, and unexpected failures when the distinction affects handling.
- Preserve meaningful error codes and data.
- Do not display `exception.toString()` or stack traces to users. Send technical details to logs.
- Do not use a null payload to identify the branch of a custom `Either`.
- Do not assume that `fold` awaits asynchronous callbacks. Follow its contract and explicitly await asynchronous work.
- Do not continue the success path after handling a failure.
