import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/theme/app_skeleton_theme.dart';
import 'package:skill_battles/app/theme/app_theme.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/features/account/domain/usecases/get_account_state_usecase.dart';
import 'package:skill_battles/features/account/domain/usecases/watch_account_changes_usecase.dart';
import 'package:skill_battles/features/account/presentation/bloc/account_bloc/account_bloc.dart';
import 'package:skill_battles/features/auth/domain/usecases/is_signed_in_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/logout_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/watch_signed_in_usecase.dart';

/// Root widget: the app-level account BLoC, theme, skeleton look and the
/// router (owned by `AppDependencies`).
final class SkillBattlesApp extends StatelessWidget {
  const SkillBattlesApp({required this.router, super.key});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<AccountBloc>(
      create: (_) => AccountBloc(
        getAccountState: dependencies.getDep<GetAccountStateUsecase>(),
        watchAccountChanges: dependencies.getDep<WatchAccountChangesUsecase>(),
        watchSignedIn: dependencies.getDep<WatchSignedInUsecase>(),
        logout: dependencies.getDep<LogoutUsecase>(),
        isSignedIn: dependencies.getDep<IsSignedInUsecase>()(const NoParams()),
      )..add(const AccountStarted()),
      child: MaterialApp.router(
        title: 'SkillBattles',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
        builder: (BuildContext context, Widget? child) =>
            AppSkeletonTheme(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
