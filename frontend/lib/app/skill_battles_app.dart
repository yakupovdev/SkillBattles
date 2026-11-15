import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/theme/app_skeleton_theme.dart';
import 'package:skill_battles/app/theme/app_theme.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/features/account/domain/usecases/get_account_state_usecase.dart';
import 'package:skill_battles/features/account/domain/usecases/get_activity_usecase.dart';
import 'package:skill_battles/features/account/domain/usecases/watch_account_changes_usecase.dart';
import 'package:skill_battles/features/account/presentation/bloc/account_bloc/account_bloc.dart';
import 'package:skill_battles/features/auth/domain/usecases/is_signed_in_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/logout_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/watch_signed_in_usecase.dart';
import 'package:skill_battles/features/battle/presentation/widgets/sticker_compositions_scope.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/cancel_rematch_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/get_rematch_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/get_result_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/request_rematch_usecase.dart';
import 'package:skill_battles/features/battle_result/domain/usecases/watch_rematches_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/accept_duel_invitation_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/accept_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/decline_duel_invitation_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/decline_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_duel_invitation_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friend_requests_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_incoming_duel_invitations_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_room_invitations_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/watch_duel_invitation_changes_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/watch_friendship_changes_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/watch_signed_in_user_usecase.dart';
import 'package:skill_battles/features/notifications/presentation/bloc/notification_bloc/notification_bloc.dart';

/// Root widget: the app-level account and notification BLoCs, theme,
/// skeleton look and the router (owned by `AppDependencies`).
final class SkillBattlesApp extends StatelessWidget {
  const SkillBattlesApp({required this.router, super.key});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<AccountBloc>(
          create: (_) => AccountBloc(
            getAccountState: dependencies.getDep<GetAccountStateUsecase>(),
            watchAccountChanges: dependencies
                .getDep<WatchAccountChangesUsecase>(),
            watchSignedIn: dependencies.getDep<WatchSignedInUsecase>(),
            logout: dependencies.getDep<LogoutUsecase>(),
            isSignedIn: dependencies.getDep<IsSignedInUsecase>()(
              const NoParams(),
            ),
          )..add(const AccountStarted()),
        ),
        // In-app notifications (rematches, friend requests, room
        // invitations) for the global overlay; above the router, so they
        // survive navigation.
        BlocProvider<NotificationBloc>(
          lazy: false,
          create: (_) => NotificationBloc(
            watchRematches: dependencies.getDep<WatchRematchesUsecase>(),
            getRematch: dependencies.getDep<GetRematchUsecase>(),
            getResult: dependencies.getDep<GetResultUsecase>(),
            requestRematch: dependencies.getDep<RequestRematchUsecase>(),
            cancelRematch: dependencies.getDep<CancelRematchUsecase>(),
            getActivity: dependencies.getDep<GetActivityUsecase>(),
            watchSignedIn: dependencies.getDep<WatchSignedInUsecase>(),
            watchConnection: dependencies.getDep<WatchConnectionUsecase>(),
            isSignedIn: dependencies.getDep<IsSignedInUsecase>()(
              const NoParams(),
            ),
            watchSignedInUser: dependencies.getDep<WatchSignedInUserUsecase>(),
            watchFriendshipChanges: dependencies
                .getDep<WatchFriendshipChangesUsecase>(),
            watchDuelInvitationChanges: dependencies
                .getDep<WatchDuelInvitationChangesUsecase>(),
            getFriendRequests: dependencies.getDep<GetFriendRequestsUsecase>(),
            getFriendRequest: dependencies.getDep<GetFriendRequestUsecase>(),
            acceptFriendRequest: dependencies
                .getDep<AcceptFriendRequestUsecase>(),
            declineFriendRequest: dependencies
                .getDep<DeclineFriendRequestUsecase>(),
            getIncomingDuelInvitations: dependencies
                .getDep<GetIncomingDuelInvitationsUsecase>(),
            getRoomInvitations: dependencies
                .getDep<GetRoomInvitationsUsecase>(),
            getDuelInvitation: dependencies.getDep<GetDuelInvitationUsecase>(),
            acceptDuelInvitation: dependencies
                .getDep<AcceptDuelInvitationUsecase>(),
            declineDuelInvitation: dependencies
                .getDep<DeclineDuelInvitationUsecase>(),
          )..add(const NotificationStarted()),
        ),
      ],
      child: MaterialApp.router(
        title: 'SkillBattles',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
        builder: (BuildContext context, Widget? child) =>
            StickerCompositionsScope(
              child: AppSkeletonTheme(child: child ?? const SizedBox.shrink()),
            ),
      ),
    );
  }
}
