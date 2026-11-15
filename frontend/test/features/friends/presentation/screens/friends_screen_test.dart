import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/app/router/app_routes.dart';
import 'package:skill_battles/core/domain/entity/public_player_entity.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/core/utils/functional/either.dart';
import 'package:skill_battles/features/friends/domain/entity/friends_page_entity.dart';
import 'package:skill_battles/features/friends/presentation/screens/friends_screen.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friend_row.dart';
import 'package:skill_battles/features/friends/presentation/widgets/friends_list_section.dart';

import '../../../../helpers/friends_fakes.dart';
import '../../../../helpers/router_harness.dart';

void main() {
  testWidgets(
    'Friends route skeleton uses real rows then renders empty state',
    (WidgetTester tester) async {
      final ScriptedFriendsRepository repository = ScriptedFriendsRepository();
      final Completer<Either<Failure, FriendsPageEntity>> answer =
          Completer<Either<Failure, FriendsPageEntity>>();
      repository.onGetFriends = (_) => answer.future;
      final RouterHarness harness = await RouterHarness.create(
        signedIn: true,
        location: AppRoutes.friends.path,
        friendsRepository: repository,
      );
      addTearDown(() => harness.dispose(tester));
      await harness.pump(tester);

      expect(find.byType(FriendsScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(FriendsListSection),
          matching: find.byType(FriendRow),
        ),
        findsWidgets,
      );
      expect(
        tester
            .widgetList<Skeletonizer>(
              find.byWidgetPredicate((widget) => widget is Skeletonizer),
            )
            .any((widget) => widget.enabled),
        isTrue,
      );

      answer.complete(ok(friendsPage([], totalPages: 0)));
      await pumpFrames(tester);

      expect(find.text('No friends yet'), findsOneWidget);
      expect(find.byType(FriendRow), findsNothing);
      expect(
        tester
            .widgetList<Skeletonizer>(
              find.byWidgetPredicate((widget) => widget is Skeletonizer),
            )
            .any((widget) => widget.enabled),
        isFalse,
      );
    },
  );

  testWidgets('Friends page shows page error, keeps rows and retries Next', (
    WidgetTester tester,
  ) async {
    final ScriptedFriendsRepository repository = ScriptedFriendsRepository();
    bool failPage = true;
    repository.onGetFriends = (params) async {
      if (params.page == 1 && failPage) return failed(const TimeoutFailure());
      return ok(
        friendsPage(
          [
            if (params.page == 0)
              for (int i = 0; i < 20; i++)
                friendItem(
                  'rel-$i',
                  PublicPlayerEntity(
                    id: 'u-$i',
                    nickname: 'Player $i',
                    isPro: false,
                  ),
                )
            else
              friendItem('last-rel', friendBoris),
          ],
          page: params.page,
          totalPages: 2,
          totalElements: 21,
        ),
      );
    };
    final RouterHarness harness = await RouterHarness.create(
      signedIn: true,
      location: AppRoutes.friends.path,
      friendsRepository: repository,
    );
    addTearDown(() => harness.dispose(tester));
    await harness.pump(tester);

    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await pumpFrames(tester);

    expect(find.text(const TimeoutFailure().userMessage), findsOneWidget);
    expect(find.byType(FriendRow), findsNWidgets(20));
    expect(repository.friendsCalls.last.page, 1);

    failPage = false;
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await pumpFrames(tester);

    expect(find.text(const TimeoutFailure().userMessage), findsNothing);
    expect(find.byType(FriendRow), findsOneWidget);
    expect(find.text(friendBoris.nickname), findsOneWidget);
    expect(find.text('Showing 21–21 of 21'), findsOneWidget);
  });

  testWidgets('Friends list failure leaves other blocks usable and retries', (
    WidgetTester tester,
  ) async {
    final ScriptedFriendsRepository repository = ScriptedFriendsRepository();
    repository.onGetFriends = (_) async => failed(const TimeoutFailure());
    final RouterHarness harness = await RouterHarness.create(
      signedIn: true,
      location: AppRoutes.friends.path,
      friendsRepository: repository,
    );
    addTearDown(() => harness.dispose(tester));
    await harness.pump(tester);

    expect(find.text("Couldn't load your friends"), findsOneWidget);
    expect(find.text('YOUR FRIEND CODE'), findsOneWidget);
    repository.onGetFriends = (_) async =>
        ok(friendsPage([friendItem('rel-1', friendAnna)]));
    await tester.ensureVisible(find.text('Try again'));
    await tester.tap(find.text('Try again'));
    await pumpFrames(tester);

    expect(find.text("Couldn't load your friends"), findsNothing);
    expect(find.text(friendAnna.nickname), findsOneWidget);
  });
}
