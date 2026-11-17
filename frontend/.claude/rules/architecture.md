# Architecture — Layers, Usecases, Repositories, Storage, GetIt

> **Scope:** Mandatory project conventions derived from the provided Musium rule set. Follow existing contracts and user requirements. Do not refactor unrelated code merely to enforce these rules.
> **Source fidelity:** The “Existing project conventions” sections reproduce the user's original rules. “Added safeguards” sections are additional recommendations and must be applied only when compatible with the real repository.

## Existing project conventions

### Preparation

- Read `pubspec.yaml`, `analysis_options.yaml`, project instructions, and the files in the affected module.
- Locate the existing `Usecase`, `Either`, `Failure`, storage abstractions, HTTP clients, and DI registrations. Reuse them; do not create duplicates.
- Use installed dependencies and supported Dart syntax. Do not add libraries or code generation unless required by the task.
- Change only code related to the task. Preserve the user's existing changes.

### Directory structure and dependency direction

- Place each feature in `lib/features/<feature>/` with the necessary `data`, `domain`, and `presentation` layers.
- Place shared components in `lib/core`. Do not import from `features` into `core`.
- Use `domain/repository` for contracts, `data/repository` for implementations, `domain/usecases` for use cases, and `domain/entity` for entities.
- Use `data/models`, `data/parsers`, `data/sources/remote`, and `data/sources/local` for their respective responsibilities.
- Place screens in `presentation/screens`, widgets in `presentation/widgets`, and UI controllers in `presentation/controllers`.
- Place each BLoC in `presentation/bloc/<name>_bloc/` alongside its events and state.
- Do not create empty layers or directories. Reuse the directories of an existing module; do not introduce parallel `screen/screens` or `widget/widgets` directories.
- For data operations, follow this flow: UI → BLoC/Cubit → Usecase → Repository → Data source.
- The domain layer must not depend on data, presentation, Dio, GetIt, or Flutter UI.
- Do not expose JSON, `Response`, data models, or external SDK objects in UI state.
- Handle local visual state in presentation without introducing unnecessary repositories or use cases.

### Usecase pattern

- Use the shared contract `abstract interface class Usecase<Result, Params>` with the method `Result call(Params params)`.
- The first generic parameter must specify the complete return type, including `Future` and `Either`; the second specifies the input parameters.
- Name each concrete class `<Action>Usecase` and declare it with `implements Usecase<...>`.
- Do not create a separate interface and `Impl` for every use case unless required by the task or an existing contract.
- Each use case must perform one operation.
- Inject the repository through the constructor. For a single dependency, use a positional parameter and a `const` constructor.
- Return `Future<Either<Failure, Result>>` for operations with expected failures.
- Use `NoParams` when there is no input. Every other input is a dedicated immutable `<Action>ParamsEntity` (`Equatable`, `const` constructor, `final` fields) in `features/<feature>/domain/entity/<action>_params_entity.dart` — even for a single value (e.g. `SendCodeParamsEntity(phone:)`). Never declare params classes inside use-case files and never create a `usecases/params/` directory. Reuse an existing entity when its fields and meaning match.
- Do not pass parameters through untyped Maps or Lists.
- Perform shared business validation and input transformations in the use case; do not duplicate them across screens.
- Return the Future directly for simple delegation. Add `async/await` when processing results, sequencing operations, or catching exceptions.
- Do not access GetIt, Dio, storage implementations, UI, or navigation from a use case.

### Repository pattern

- Declare the contract as `abstract interface class <Feature>Repository` and the implementation as `<Feature>RepositoryImpl implements <Feature>Repository`. An implementation backed by Supabase is `Supabase<Feature>RepositoryImpl` in `supabase_<feature>_repository_impl.dart`, and its remote is `Supabase<Feature>RemoteImpl` (e.g. `SupabaseProfileRepositoryImpl`, `SupabaseProfileRemoteImpl`). Mock-backed implementations keep the plain name.
- Inject data sources through named `required` constructor parameters and store them in private `final` fields.
- Return entities and primitives wrapped in `Either`; do not return data models or transport responses.
- Perform model-to-entity mapping and local/remote coordination in the repository implementation.
- Return success through `Either.right` and expected failures through `Either.left`.
- Preserve the type of an existing `Failure`; do not wrap it again in `UnexpectedFailure`.
- Check the type of a transport error's payload. Do not use an unchecked `error as Failure` cast.
- Do not turn request or parsing failures into successful empty lists.
- Do not place `BuildContext`, `emit`, navigation, or UI callbacks in repositories.

### Failure and Either (core)

- All shared error code lives in `lib/core/utils/error/` and nowhere else: `app_exception.dart` (technical `AppException` hierarchy thrown by data sources/storage), `failure.dart` (sealed `Failure` hierarchy returned through `Either.left`), `failure_mapper.dart` (`mapExceptionToFailure`, the only exception → `Failure` conversion, called from repository implementations), and `failure_message.dart` (`Failure.userMessage` for presentation). Add new shared exceptions, failures, or mapping there; never define a shared error type inside a feature or another `core` folder.
- Keep the distinction: data sources and storage throw `AppException` subtypes (or let `DioException` propagate); repositories convert them with `mapExceptionToFailure`; domain and presentation only see `Failure`.
- Remote sources throw, repositories catch:
  - Remote sources contain no `try`/`catch`, no `Either`, and no wrappers around the call: request, then `fromJson`. They may throw `ParsingException` for a result of the wrong shape.
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

- Only `Exception`s become failures; an `Error` (a programming defect) always propagates.
- Interceptors, Supabase specifics, feature error codes, and user messages: `.claude/docs/architecture/errors.md`.

### Dependency injection and screens (core)

- Use `AppDependencies` as the single composition root.
- `AppDependencies` owns a private container created with `GetIt.asNewInstance()`. Never use `GetIt.instance`/`GetIt.I`, and never store dependencies in static or top-level variables.
- Allow GetIt lookups only inside `AppDependencies`. Presentation obtains dependencies through `AppDependenciesProvider.of(context)`; pass dependencies to all other objects through constructors.
- Resolve dependencies with the single generic method `AppDependenciesProvider.of(context).getDep<SomeUsecase>()`. Do not add a getter per dependency to `AppDependencies`; a new use case only needs its registration in `_registerUsecases`.
- From presentation, resolve only use cases (and, in `main.dart`, the `GoRouter`). Never resolve repositories, data sources, storage, or HTTP clients in widgets.
- Every `BlocProvider` lives in the screen's `GoRouterWrapper.wrappedRoute`, never in the router. Full pattern, example, route registration, and GetIt lifetimes: `.claude/docs/architecture/di_and_screens.md`.

### Navigation and shared resources

- Reuse shared colors, typography, themes, and asset paths. Follow the existing localization approach.
- `AppRoutes` (`lib/app/router/app_routes.dart`) is an enum: one value per screen, named after the screen, holding its path (`login('/login')`, nested routes hold the relative segment `verifyCode('verify')`, path parameters use the static `...Param` constants `channel(':$channelIdParam')`). Its static constants hold path and query parameter names. Use `AppRoutes.x.name` / `AppRoutes.x.path` everywhere (router, `context.goNamed(AppRoutes.x.name)`, redirects); never write a route path or name as a string literal. Prefer navigating by name. A new screen gets a new enum value. Do not navigate from domain or data layers.

## Added safeguards

### Layer dependency invariants

- Imports must respect `presentation → domain ← data`: `presentation` uses domain abstractions; `data` implements domain contracts; `domain` has no dependency on either outer layer.
- Shared `lib/core` code must not depend on feature implementations. Avoid direct imports of another feature's `data/` or `presentation/` internals. If features must communicate, use an explicit domain-facing contract or application-level coordinator rather than reaching across layers.
- Add a Usecase when the operation belongs to application/business logic. Keep purely local widget toggles or animations in presentation, as required by the original rules.
- Search for existing classes and registrations before adding a new interface, model, or abstraction. New abstractions need a real use, not hypothetical future consumers.

### Architectural acceptance check

For each cross-layer change, verify: public contract preserved; parameter forwarding complete; `Model.toEntity()` performed at repository boundary; `Either` branches mapped correctly; DI registration and lifecycle correct; local and remote failure semantics preserved.

## More rules — read the file when the task touches its area

| Read | When the task touches |
|---|---|
| `.claude/docs/architecture/data_layer.md` | remote/local sources, HTTP, `AppApi`, models and JSON, mapping, pagination, repository/use-case details |
| `.claude/docs/architecture/errors.md` | exceptions, `Failure`, `mapExceptionToFailure`, interceptors, error codes, user error messages |
| `.claude/docs/architecture/di_and_screens.md` | `AppDependencies`, GetIt registrations, `AppDependenciesProvider`, `BlocProvider`, screen routes |
| `.claude/docs/architecture/forms.md` | screens with input fields, validators, form submission |
| `.claude/docs/architecture/local_storage.md` | preferences / secure storage, `StorageKeys` |
| `.claude/rules/local_database.md` | the drift response cache (always loaded) |
