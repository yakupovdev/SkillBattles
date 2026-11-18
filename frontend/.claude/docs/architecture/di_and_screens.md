# DI and Screens — GetIt, AppDependencies, BlocProvider, Routes

> Part of the mandatory architecture rules: split out of `.claude/rules/architecture.md` (dependency injection and screen wiring). Same scope and source-fidelity notes as there: "Existing project conventions" are the original rules, "Added safeguards" apply where compatible with the repository.

## Existing project conventions

### GetIt and dependency injection

- Use `AppDependencies` as the single composition root.
- Split registration into private methods for storage, clients, sources, repositories, use cases, BLoCs, and the router.
- Register repositories, sources, and storage under their interfaces; register use cases under their concrete classes when no separate contract exists.
- Use `registerLazySingleton` for shared services, sources, repositories, and stateless use cases when their lifetime matches the application.
- Do not register BLoCs/Cubits in GetIt. Screens construct them in `BlocProvider(create:)` from use cases exposed by `AppDependencies` (see "Screens, BlocProvider and AppDependenciesProvider").
- Use `registerSingletonAsync` for asynchronous dependencies; declare registration dependencies through `dependsOn`.
- Await `allReady()` before using asynchronous dependencies.
- Initialize DI once per application launch. In tests, use isolated registrations and clean them up afterward.
- `AppDependencies` owns a private container created with `GetIt.asNewInstance()`. Never use `GetIt.instance`/`GetIt.I`, and never store dependencies in static or top-level variables.
- Allow GetIt lookups only inside `AppDependencies`. Presentation obtains dependencies through `AppDependenciesProvider.of(context)`; pass dependencies to all other objects through constructors.
- Assign resource disposal to a single owner. In a GetIt dispose callback, dispose the supplied instance; do not perform another lookup.
- Do not duplicate a GetIt singleton with a static singleton inside its implementation.

### Screens, BlocProvider and AppDependenciesProvider

- `AppDependenciesProvider` (`lib/app/di/app_dependencies_provider.dart`) is an `InheritedWidget` that wraps the whole app in `main.dart`, around `EasyBookingApp`. Access it with `AppDependenciesProvider.of(context)` (throws when missing) or `maybeOf(context)`.
- Resolve dependencies with the single generic method `AppDependenciesProvider.of(context).getDep<SomeUsecase>()`. Do not add a getter per dependency to `AppDependencies`; a new use case only needs its registration in `_registerUsecases`.
- From presentation, resolve only use cases (and, in `main.dart`, the `GoRouter`). Never resolve repositories, data sources, storage, or HTTP clients in widgets.
- Every `BlocProvider`/`MultiBlocProvider` lives in the screen's own file in `presentation/screens/`, never in the router. A screen that needs a BLoC/Cubit implements `GoRouterWrapper` (`lib/core/utils/extensions/go_router_extension.dart`):

  ```dart
  final class LoginScreen extends StatefulWidget implements GoRouterWrapper {
    const LoginScreen({this.from, super.key});

    final String? from;

    @override
    Widget wrappedRoute(BuildContext context) {
      final AppDependencies dependencies = AppDependenciesProvider.of(context);
      return BlocProvider<LoginBloc>(
        create: (_) =>
            LoginBloc(sendCode: dependencies.getDep<SendCodeUsecase>()),
        child: this,
      );
    }
    // createState()/build() read the BLoC from context as usual.
  }
  ```

  Read the dependencies in `wrappedRoute`, not inside `create`. Add a start event in `create` (`..add(<Started>Event(...))`) when the BLoC needs route arguments; keep those arguments as screen fields.
- Do not create separate `<Name>View` widgets to host the UI; the screen itself is the UI and is the `child` of its provider.
- Register every screen route with `GoRouteExtension.wrappedRoute(name: AppRoutes.x.name, path: AppRoutes.x.path, wrappedBuilder: (_, GoRouterState state) => XScreen(...))`; it calls `wrappedRoute` for any `GoRouterWrapper` and passes other screens through unchanged. A plain `GoRoute` is only for a route without a screen (the root redirect). Route builders only parse/validate route parameters; router files must not import `flutter_bloc`, `get_it`, BLoCs, use cases, or `AppDependencies`.

## Added safeguards

### GetIt and lifecycle

- `AppDependencies` is the single app-level composition root, created once in `main` with `await AppDependencies.init()`. Keep its registrations arranged by dependency order: primitives/storage/clients → sources → repositories → usecases → router.
- Register each contract once in a scope; duplicate registrations and hidden static singletons require explicit justification.
- Await asynchronous registrations' `allReady()` before the corresponding dependency is accessed, and model required initialization dependencies with the project's supported GetIt APIs.
- Each screen's `BlocProvider(create:)` creates an independent BLoC/Cubit and closes it with the route. Do not dispose global services or externally owned BLoCs from a screen.
- Use explicit dependency injection in domain/data constructors. A GetIt lookup is allowed only inside `AppDependencies`.
- In tests, build dependencies with `GetIt.asNewInstance()` + `AppDependencies.fromContainer(...)` (see `test/helpers/router_harness.dart`), wrap the tree in `AppDependenciesProvider`, and reset the container in tear-down.
