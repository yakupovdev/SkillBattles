import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/app/theme/app_theme.dart';
import 'package:skill_battles/core/presentation/markdown/math_fit_width.dart';
import 'package:skill_battles/core/presentation/widgets/app_markdown_text.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  group('AppMarkdownText', () {
    testWidgets('renders inline and display formulas as math', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const AppMarkdownText(
            'Solve \$x^2 + 4\$:\n\$\$\n\\frac{a}{b}\n\$\$',
            style: AppTextStyles.bodyLg,
          ),
        ),
      );

      expect(find.byType(Math), findsNWidgets(2));
      expect(find.textContaining(r'$'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows broken TeX as its source text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const AppMarkdownText(
            r'Broken $\frac{1$ here',
            style: AppTextStyles.bodyLg,
          ),
        ),
      );

      expect(find.byType(Math), findsNothing);
      expect(
        find.textContaining(r'$\frac{1$', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('reads as plain text to screen readers', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          const AppMarkdownText(r'**Find** $x$', style: AppTextStyles.bodyLg),
        ),
      );

      expect(find.bySemanticsLabel('Find x'), findsOneWidget);
      semantics.dispose();
    });
    testWidgets('wraps a long formula after relations without overflow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const SizedBox(
            width: 300,
            child: AppMarkdownText(
              r'Given $\sum_{k=1}^{n} k^2 = \frac{n(n+1)(2n+1)}{6} = '
              r'a + b + c + d + e + f + g + h + i + j + k + l + m + n$',
              style: AppTextStyles.headlineMd,
            ),
          ),
        ),
      );

      expect(find.byType(Math), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a wide display formula is scaled down to the width', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 200,
              child: AppMarkdownText(
                '\$\$a + b + c + d + e + f + g + h + i + j + k + l + m + n\$\$',
                style: AppTextStyles.bodyLg,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(MathFitWidth)).width, 200);
    });
  });

  group('AppMarkdownLine', () {
    testWidgets('renders a formula and cuts long text to maxLines', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 200,
            child: AppMarkdownLine(
              'A long answer with \$\\sqrt{2}\$ ${'word ' * 40}',
              style: AppTextStyles.bodyLg,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );

      expect(find.byType(Math), findsOneWidget);
      expect(
        tester.getSize(find.byType(AppMarkdownLine)).height,
        lessThan(AppTextStyles.bodyLg.fontSize! * 2),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
