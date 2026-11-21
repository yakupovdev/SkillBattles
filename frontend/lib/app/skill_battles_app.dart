import 'package:bloc_signals_jaspr/bloc_signals_jaspr.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/router/app_router.dart';
import 'package:skill_battles/core/domain/usecases/usecase.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/utils/session/auth_session.dart';
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

/// Root component: the app-level account and notification blocs, the
/// sticker compositions and the router.
final class SkillBattlesApp extends StatefulComponent {
  const SkillBattlesApp({super.key});

  @override
  State<SkillBattlesApp> createState() => _SkillBattlesAppState();
}

final class _SkillBattlesAppState extends State<SkillBattlesApp> {
  late GlobalStateKey<RouterState> _routerKey;
  late AuthSession _session;
  late Router _router;

  @override
  void initState() {
    super.initState();
    _routerKey = GlobalStateKey<RouterState>();
    _session = AppDependenciesProvider.of(context).getDep<AuthSession>();
    _router = createAppRouter(session: _session, key: _routerKey);
    _session.addListener(_onSessionChanged);
  }

  /// Re-runs the redirect for the current address, like go_router's
  /// `refreshListenable`: sign-out leaves for the welcome page, sign-in
  /// leaves the auth and welcome pages.
  void _onSessionChanged() {
    final RouterState? router = _routerKey.currentState;
    if (router == null) return;
    router.replace(router.matchList.uri.toString());
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return MultiBlocSignalProvider(
      providers: <BlocSignalProviderSingleChildComponent>[
        BlocSignalProvider<AccountBloc>(
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
        BlocSignalProvider<NotificationBloc>(
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
      child: StickerCompositionsScope(child: _router),
    );
  }
}
