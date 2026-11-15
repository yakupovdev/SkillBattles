import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/utils/extensions/go_router_extension.dart';
import 'package:skill_battles/features/friends/domain/entity/friend_request_direction.dart';
import 'package:skill_battles/features/friends/domain/usecases/accept_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/cancel_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/decline_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friend_code_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friend_requests_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friends_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/remove_friend_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/send_friend_request_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/watch_friendship_changes_usecase.dart';
import 'package:skill_battles/features/friends/presentation/bloc/friends_bloc/friends_bloc.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friends_list_section.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friends_requests_section.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friends_sidebar.dart';

/// The Friends page (Paper: "39 Friends — loaded"): requests above the
/// friends list, the own code and the add form on the right.
final class FriendsScreen extends StatefulWidget implements GoRouterWrapper {
  const FriendsScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<FriendsBloc>(
      create: (_) => FriendsBloc(
        getFriendCode: dependencies.getDep<GetFriendCodeUsecase>(),
        getFriends: dependencies.getDep<GetFriendsUsecase>(),
        getFriendRequests: dependencies.getDep<GetFriendRequestsUsecase>(),
        sendFriendRequest: dependencies.getDep<SendFriendRequestUsecase>(),
        acceptFriendRequest: dependencies.getDep<AcceptFriendRequestUsecase>(),
        declineFriendRequest: dependencies
            .getDep<DeclineFriendRequestUsecase>(),
        cancelFriendRequest: dependencies.getDep<CancelFriendRequestUsecase>(),
        removeFriend: dependencies.getDep<RemoveFriendUsecase>(),
        watchFriendshipChanges: dependencies
            .getDep<WatchFriendshipChangesUsecase>(),
        watchConnection: dependencies.getDep<WatchConnectionUsecase>(),
      )..add(const FriendsStarted()),
      child: this,
    );
  }

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

final class _FriendsScreenState extends State<FriendsScreen> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _codeController;
  late final FocusNode _codeFocusNode;
  late final GlobalKey _requestsKey;
  late final ValueNotifier<FriendRequestDirection> _direction;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _codeController = TextEditingController();
    _codeFocusNode = FocusNode();
    _requestsKey = GlobalKey();
    _direction = ValueNotifier<FriendRequestDirection>(
      FriendRequestDirection.incoming,
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    _direction.dispose();
    super.dispose();
  }

  void _showIncoming() {
    _direction.value = FriendRequestDirection.incoming;
    final BuildContext? target = _requestsKey.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 250),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDesktopViewport(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(64, 48, 64, 64),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 64,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 40,
                children: <Widget>[
                  const _PageTitle(),
                  KeyedSubtree(
                    key: _requestsKey,
                    child: ValueListenableBuilder<FriendRequestDirection>(
                      valueListenable: _direction,
                      builder:
                          (
                            BuildContext context,
                            FriendRequestDirection direction,
                            _,
                          ) => FriendsRequestsSection(
                            direction: direction,
                            onDirectionSelected: (
                              FriendRequestDirection value,
                            ) => _direction.value = value,
                          ),
                    ),
                  ),
                  const FriendsListSection(),
                ],
              ),
            ),
            SizedBox(
              width: 400,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 24,
                  children: <Widget>[
                    const FriendsCodeSection(),
                    FriendsAddSection(
                      formKey: _formKey,
                      controller: _codeController,
                      focusNode: _codeFocusNode,
                      onShowIncoming: _showIncoming,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _PageTitle extends StatelessWidget {
  const _PageTitle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: <Widget>[
        AppEyebrow('Social · Private matches'),
        Text('Friends', style: AppTextStyles.displayMd),
      ],
    );
  }
}
