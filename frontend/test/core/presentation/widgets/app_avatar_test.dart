import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_theme.dart';
import 'package:skill_battles/core/presentation/widgets/app_avatar.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('AppAvatar', () {
    testWidgets('shows the upper-case first letter of the nickname', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_app(const AppAvatar(nickname: 'aliya_k')));

      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('shows a question mark for an empty nickname', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_app(const AppAvatar(nickname: '')));

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('is drawn at the diameter of its size', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(const AppAvatar(nickname: 'timur.b', size: AppAvatarSize.xl)),
      );

      expect(tester.getSize(find.byType(AppAvatar)), const Size.square(72));
    });
  });
}
