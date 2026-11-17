import 'package:bloc_signals_jaspr/bloc_signals_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_form.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_input.dart';
import 'package:skill_battles/core/utils/extensions/route_extension.dart';
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
final class FriendsScreen extends StatefulComponent implements RouteWrapper {
  const FriendsScreen({super.key});

  @override
  Component wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocSignalProvider<FriendsBloc>(
      create: (_) => FriendsBloc(
        getFriendCode: dependencies.getDep<GetFriendCodeUsecase>(),
        getFriends: dependencies.getDep<GetFriendsUsecase>(),
        getFriendRequests: dependencies.getDep<GetFriendRequestsUsecase>(),
        sendFriendRequest: dependencies.getDep<SendFriendRequestUsecase>(),
        acceptFriendRequest: dependencies.getDep<AcceptFriendRequestUsecase>(),
        declineFriendRequest: dependencies.getDep<DeclineFriendRequestUsecase>(),
        cancelFriendRequest: dependencies.getDep<CancelFriendRequestUsecase>(),
        removeFriend: dependencies.getDep<RemoveFriendUsecase>(),
        watchFriendshipChanges: dependencies.getDep<WatchFriendshipChangesUsecase>(),
        watchConnection: dependencies.getDep<WatchConnectionUsecase>(),
      )..add(const FriendsStarted()),
      child: this,
    );
  }

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

final class _FriendsScreenState extends State<FriendsScreen> {
  late final GlobalStateKey<AppFormState> _formKey;
  late final TextEditingController _codeController;
  late final FocusNode _codeFocusNode;
  late final GlobalNodeKey<web.HTMLElement> _requestsKey;
  late final ValueNotifier<FriendRequestDirection> _direction;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalStateKey<AppFormState>();
    _codeController = TextEditingController();
    _codeFocusNode = FocusNode();
    _requestsKey = GlobalNodeKey<web.HTMLElement>();
    _direction = ValueNotifier<FriendRequestDirection>(FriendRequestDirection.incoming);
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
    _requestsKey.currentNode?.scrollIntoView(web.ScrollIntoViewOptions(behavior: 'smooth', block: 'start'));
  }

  @override
  Component build(BuildContext context) {
    return AppDesktopViewport(
      child: div(classes: 'friends-screen', <Component>[
        div(classes: 'friends-screen__main', <Component>[
          const _PageTitle(),
          div(key: _requestsKey, classes: 'friends-screen__requests', <Component>[
            ValueListenableBuilder<FriendRequestDirection>(
              listenable: _direction,
              builder: (BuildContext context, FriendRequestDirection direction) => FriendsRequestsSection(
                direction: direction,
                onDirectionSelected: (FriendRequestDirection value) => _direction.value = value,
              ),
            ),
          ]),
          const FriendsListSection(),
        ]),
        div(classes: 'friends-screen__sidebar', <Component>[
          const FriendsCodeSection(),
          FriendsAddSection(
            formKey: _formKey,
            controller: _codeController,
            focusNode: _codeFocusNode,
            onShowIncoming: _showIncoming,
          ),
        ]),
      ]),
    );
  }
}

final class _PageTitle extends StatelessComponent {
  const _PageTitle();

  @override
  Component build(BuildContext context) {
    return div(classes: 'friends-screen__title-block', <Component>[
      const AppEyebrow('Social · Private matches'),
      h1(classes: 'friends-screen__title', <Component>[Component.text('Friends')]),
    ]);
  }
}

@css
List<StyleRule> get friendsScreenStyles => <StyleRule>[
  css('.friends-screen').styles(
    display: Display.flex,
    padding: const Padding.fromLTRB(Unit.pixels(64), Unit.pixels(48), Unit.pixels(64), Unit.pixels(64)),
    alignItems: AlignItems.start,
    gap: const Gap.column(Unit.pixels(64)),
  ),
  css('.friends-screen__main').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(40)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.friends-screen__sidebar').styles(
    display: Display.flex,
    width: const Unit.pixels(400),
    padding: const Padding.only(top: Unit.pixels(4)),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(24)),
    flex: const Flex(shrink: 0),
  ),
  css('.friends-screen__title-block').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(10)),
  ),
  css('.friends-screen__title').combine(AppTextStyles.displayMd),
];
