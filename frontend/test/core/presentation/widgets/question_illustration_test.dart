import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/app/theme/app_theme.dart';
import 'package:skill_battles/core/presentation/widgets/question_illustration.dart';

import '../../../helpers/fake_image_http_client.dart';

const String _path =
    '/media/questions/SAT_MATH/3f5a3602/'
    '224eefc655e44ddac7e07d499e9fad2ba90e28bd8db675e8cd15b31156b7a203.png';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

/// Lets the fake response and the PNG decode finish outside fake async.
Future<void> _settleImage(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump();
}

bool _hasDecodedImage(WidgetTester tester) => tester
    .widgetList<RawImage>(find.byType(RawImage))
    .any((RawImage image) => image.image != null);

void main() {
  group('QuestionIllustration', () {
    testWidgets('loads the origin-relative URL from the media origin with a '
        'plain GET and shows the image', (WidgetTester tester) async {
      final FakeImageHttpClient client = FakeImageHttpClient()..install();

      await tester.pumpWidget(
        _app(const QuestionIllustration(imageUrl: _path)),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await _settleImage(tester);

      expect(client.requests, <Uri>[Uri.parse('http://localhost:8080$_path')]);
      expect(_hasDecodedImage(tester), isTrue);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find.bySemanticsLabel(QuestionIllustration.semanticLabel),
        findsOneWidget,
      );
    });

    testWidgets('a failed load shows the error and Retry requests the same '
        'URL again', (WidgetTester tester) async {
      final FakeImageHttpClient client = FakeImageHttpClient(
        statuses: <int>[404, 200],
      )..install();

      await tester.pumpWidget(
        _app(const QuestionIllustration(imageUrl: _path)),
      );
      await _settleImage(tester);

      expect(find.text(QuestionIllustration.errorMessage), findsOneWidget);
      expect(_hasDecodedImage(tester), isFalse);

      await tester.tap(find.text(QuestionIllustration.retryLabel));
      await tester.pump();
      await _settleImage(tester);

      expect(client.requests, hasLength(2));
      expect(client.requests.last, client.requests.first);
      expect(client.requests.last.hasQuery, isFalse);
      expect(find.text(QuestionIllustration.errorMessage), findsNothing);
      expect(_hasDecodedImage(tester), isTrue);
    });

    testWidgets('rebuilding with the same URL does not request it again', (
      WidgetTester tester,
    ) async {
      final FakeImageHttpClient client = FakeImageHttpClient()..install();

      await tester.pumpWidget(
        _app(const QuestionIllustration(imageUrl: _path)),
      );
      await _settleImage(tester);
      await tester.pumpWidget(
        _app(const QuestionIllustration(imageUrl: _path, maxHeight: 300)),
      );
      await _settleImage(tester);

      expect(client.requests, hasLength(1));
    });

    testWidgets('a tap opens the image full size in a dialog', (
      WidgetTester tester,
    ) async {
      FakeImageHttpClient().install();

      await tester.pumpWidget(
        _app(const QuestionIllustration(imageUrl: _path)),
      );
      await _settleImage(tester);
      await tester.tap(find.byType(RawImage));
      await tester.pump();
      await _settleImage(tester);

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('the full-size dialog closes when the question changes', (
      WidgetTester tester,
    ) async {
      FakeImageHttpClient().install();

      await tester.pumpWidget(
        _app(
          const QuestionIllustration(key: ValueKey<int>(1), imageUrl: _path),
        ),
      );
      await _settleImage(tester);
      await tester.tap(find.byType(RawImage));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);

      // The next round has no illustration: the widget is removed.
      await tester.pumpWidget(_app(const SizedBox.shrink()));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('a tall chart on a narrow screen is scaled down whole, '
        'keeping its aspect ratio, without overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final List<int> png = (await tester.runAsync(
        () => encodeTestPng(600, 751),
      ))!;
      FakeImageHttpClient(body: png).install();

      await tester.pumpWidget(
        _app(const QuestionIllustration(imageUrl: _path)),
      );
      await _settleImage(tester);

      final Size size = tester.getSize(find.byType(RawImage));
      expect(size.width, lessThanOrEqualTo(360));
      expect(size.height, lessThanOrEqualTo(420));
      expect(size.width / size.height, closeTo(600 / 751, 0.01));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a small diagram is not stretched past its natural size', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final List<int> png = (await tester.runAsync(
        () => encodeTestPng(187, 107),
      ))!;
      FakeImageHttpClient(body: png).install();

      await tester.pumpWidget(
        _app(const QuestionIllustration(imageUrl: _path)),
      );
      await _settleImage(tester);

      expect(tester.getSize(find.byType(RawImage)), const Size(187, 107));
    });

    testWidgets('requests nothing while skeletonized', (
      WidgetTester tester,
    ) async {
      final FakeImageHttpClient client = FakeImageHttpClient()..install();

      await tester.pumpWidget(
        _app(
          const Skeletonizer(
            enabled: true,
            child: QuestionIllustration(imageUrl: _path),
          ),
        ),
      );
      await _settleImage(tester);

      expect(client.requests, isEmpty);
    });
  });
}
