import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_theme.dart';
import 'package:skill_battles/core/domain/usecases/watch_connection_usecase.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_duel_invitation_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_friends_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/get_room_invitations_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/send_duel_invitation_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/watch_duel_invitation_changes_usecase.dart';
import 'package:skill_battles/features/friends/domain/usecases/withdraw_duel_invitation_usecase.dart';
import 'package:skill_battles/features/friends/presentation/bloc/room_invitation_bloc/room_invitation_bloc.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friend_picker_dialog.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friend_picker_row.dart';
import 'package:skill_battles/features/friends/presentation/widgets/room_invitation_section.dart';

import '../../../../helpers/friends_fakes.dart';
import '../../../../helpers/notification_fakes.dart';
import '../../../../helpers/router_harness.dart' show pumpFrames;

void main() {
  late ScriptedFriendsRepository repository;
  late FakeConnectionRepository connection;
  late RoomInvitationBloc bloc;

  setUp(() {
    repository = ScriptedFriendsRepository();
    connection = FakeConnectionRepository();
  });

  Future<void> pump(WidgetTester tester) async {
    bloc = RoomInvitationBloc(
      getRoomInvitations: GetRoomInvitationsUsecase(repository),
      getDuelInvitation: GetDuelInvitationUsecase(repository),
      sendDuelInvitation: SendDuelInvitationUsecase(repository),
      withdrawDuelInvitation: WithdrawDuelInvitationUsecase(repository),
      getFriends: GetFriendsUsecase(repository),
      watchDuelInvitationChanges: WatchDuelInvitationChangesUsecase(repository),
      watchConnection: WatchConnectionUsecase(connection),
      generateId: sequentialIds(),
      pageSize: 2,
    )..add(const RoomInvitationStarted('duel-1'));
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      final Future<void> closing = bloc.close();
      await pumpFrames(tester);
      await tester.runAsync(() async {
        await closing;
        await repository.dispose();
        await connection.changes.close();
      });
    });
    await tester.pumpWidget(
      BlocProvider<RoomInvitationBloc>.value(
        value: bloc,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: Center(
              child: RoomInvitationActions(disciplineCode: 'SAT_MATH'),
            ),
          ),
        ),
      ),
    );
    await pumpFrames(tester);
    await tester.tap(find.text('Invite friend'));
    await pumpFrames(tester);
    expect(find.byType(FriendPickerDialog), findsOneWidget);
  }

  testWidgets('failed invitation to A does not disable sending to selected B', (
    WidgetTester tester,
  ) async {
    repository.onGetFriends = (_) async => ok(
      friendsPage([
        friendItem('rel-anna', friendAnna),
        friendItem('rel-boris', friendBoris),
      ]),
    );
    repository.onSendDuelInvitation = (params) async =>
        params.friendId == friendAnna.id
        ? failed(apiFailure(ApiErrorCodes.friendNotFound, status: 404))
        : ok(invitation('invite-b', incoming: false, other: friendBoris));
    await pump(tester);

    await tester.tap(find.byKey(ValueKey<String>(friendAnna.id)));
    await pumpFrames(tester);
    await tester.tap(find.text('Send invitation'));
    await pumpFrames(tester);

    expect(
      find.text('You are no longer friends with this player.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AppButton>(find.widgetWithText(AppButton, 'Send invitation'))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(ValueKey<String>(friendBoris.id)));
    await pumpFrames(tester);
    expect(
      find.text('You are no longer friends with this player.'),
      findsNothing,
    );
    expect(
      tester
          .widget<AppButton>(find.widgetWithText(AppButton, 'Send invitation'))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.text('Send invitation'));
    await pumpFrames(tester);

    expect(repository.sendInvitationCalls.map((p) => p.friendId), [
      friendAnna.id,
      friendBoris.id,
    ]);
    expect(repository.sendInvitationCalls.map((p) => p.requestId), [
      'id-1',
      'id-2',
    ]);
    expect(find.byType(FriendPickerDialog), findsNothing);
  });

  testWidgets('picker keeps current rows after page failure and Next retries', (
    WidgetTester tester,
  ) async {
    bool failPage = true;
    repository.onGetFriends = (params) async {
      if (params.page == 1 && failPage) return failed(const TimeoutFailure());
      return ok(
        friendsPage(
          [
            friendItem(
              'rel-${params.page}',
              params.page == 0 ? friendAnna : friendBoris,
            ),
          ],
          page: params.page,
          totalPages: 2,
          totalElements: 3,
        ),
      );
    };
    await pump(tester);

    await tester.tap(find.text('Next'));
    await pumpFrames(tester);
    expect(find.text(const TimeoutFailure().userMessage), findsOneWidget);
    expect(find.text(friendAnna.nickname), findsOneWidget);
    expect(find.byType(FriendPickerRow), findsOneWidget);

    failPage = false;
    await tester.tap(find.text('Next'));
    await pumpFrames(tester);

    expect(find.text(const TimeoutFailure().userMessage), findsNothing);
    expect(find.text(friendBoris.nickname), findsOneWidget);
    expect(find.byType(FriendPickerRow), findsOneWidget);
    expect(repository.friendsCalls.last.page, 1);
  });
}
