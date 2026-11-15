import 'dart:io';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:skill_battles/core/presentation/league/league_rank.dart';
import 'package:skill_battles/core/presentation/widgets/division_pips.dart';
import 'package:skill_battles/core/presentation/widgets/league_emblem.dart';

const LeagueRank _gold2 = LeagueRank(League.gold, 2);

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('LeagueEmblem', () {
    testWidgets('renders the asset of the rank at the given size', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_app(const LeagueEmblem(rank: _gold2, size: 48)));

      final SvgPicture picture = tester.widget(find.byType(SvgPicture));
      expect(
        (picture.bytesLoader as SvgAssetLoader).assetName,
        'assets/leagues/gold_2.svg',
      );
      expect(tester.getSize(find.byType(SvgPicture)), const Size(48, 48));
      expect(find.byType(ColorFiltered), findsNothing);
      expect(find.byType(Opacity), findsNothing);
    });

    testWidgets('locked is grayscale at 35% opacity', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(const LeagueEmblem(rank: _gold2, size: 48, locked: true)),
      );

      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.35);
      expect(find.byType(ColorFiltered), findsOneWidget);
    });

    testWidgets('dimmed is grayscale at 70% opacity', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(const LeagueEmblem(rank: _gold2, size: 48, dimmed: true)),
      );

      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.7);
      expect(find.byType(ColorFiltered), findsOneWidget);
    });

    testWidgets('inside an enabled Skeletonizer renders a bone, no SVG', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const Skeletonizer(
            enabled: true,
            child: LeagueEmblem(rank: _gold2, size: 48),
          ),
        ),
      );

      expect(find.byType(SvgPicture), findsNothing);
      expect(find.byType(LeagueEmblem), findsOneWidget);
    });

    testWidgets('inside a disabled Skeletonizer renders the SVG', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const Skeletonizer(
            enabled: false,
            child: LeagueEmblem(rank: _gold2, size: 48),
          ),
        ),
      );

      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('is hidden from semantics without a label', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(const LeagueEmblem(rank: _gold2, size: 48)));

      expect(find.bySemanticsLabel('Gold II'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(LeagueEmblem),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
      handle.dispose();
    });

    testWidgets('exposes the semantic label when given', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          const LeagueEmblem(rank: _gold2, size: 48, semanticLabel: 'Gold II'),
        ),
      );

      expect(find.bySemanticsLabel('Gold II'), findsOneWidget);
      handle.dispose();
    });
  });

  group('league SVG files', () {
    final List<File> files =
        Directory('assets/leagues').listSync().whereType<File>().toList()
          ..sort((File a, File b) => a.path.compareTo(b.path));

    test('there are 27 emblems', () => expect(files, hasLength(27)));

    for (final File file in files) {
      test('${file.path} loads through flutter_svg', () async {
        final PictureInfo info = await vg.loadPicture(
          SvgStringLoader(file.readAsStringSync()),
          null,
        );

        expect(info.size.isEmpty, isFalse);
        info.picture.dispose();
      });
    }
  });

  group('DivisionPips', () {
    const Color filled = Color(0xFF112233);
    const Color empty = Color(0xFFEEEEEE);

    List<Color?> colors(WidgetTester tester) => tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(DivisionPips),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((DecoratedBox b) => (b.decoration as BoxDecoration).color)
        .toList();

    testWidgets('is hidden when the division is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const DivisionPips(division: null, color: filled, emptyColor: empty),
        ),
      );

      expect(find.byType(DecoratedBox), findsNothing);
    });

    for (final int division in <int>[1, 2, 3]) {
      testWidgets('fills $division of 3 pips for division $division', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _app(
            DivisionPips(division: division, color: filled, emptyColor: empty),
          ),
        );

        expect(colors(tester), <Color>[
          for (int i = 1; i <= 3; i++) i <= division ? filled : empty,
        ]);
      });
    }
  });
}
