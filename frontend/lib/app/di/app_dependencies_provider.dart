import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';

/// Gives presentation access to [AppDependencies] (use cases only).
final class AppDependenciesProvider extends InheritedComponent {
  const AppDependenciesProvider({
    required this.dependencies,
    required super.child,
    super.key,
  });

  final AppDependencies dependencies;

  static AppDependencies of(BuildContext context) {
    final AppDependencies? dependencies = maybeOf(context);
    if (dependencies == null) {
      throw StateError('AppDependenciesProvider is missing above $context.');
    }
    return dependencies;
  }

  static AppDependencies? maybeOf(BuildContext context) =>
      (context.getElementForInheritedComponentOfExactType<AppDependenciesProvider>()?.component
              as AppDependenciesProvider?)
          ?.dependencies;

  @override
  bool updateShouldNotify(AppDependenciesProvider oldComponent) => dependencies != oldComponent.dependencies;
}
