import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/markdown/markdown_spans.dart';

void main() {
  group('MarkdownSpans.plainText', () {
    test('drops markup and keeps the TeX of formulas', () {
      expect(
        MarkdownSpans.plainText(r'**Solve** $x^2 = 4$ for `x`'),
        'Solve x^2 = 4 for x',
      );
    });

    test('keeps prices as they are', () {
      expect(MarkdownSpans.plainText(r'B · $60.00'), r'B · $60.00');
    });
  });

  group('MarkdownSpans.escape', () {
    test('a nickname with markup characters reads back unchanged', () {
      const String nickname = r'*timur_b* $1';

      expect(MarkdownSpans.plainText(MarkdownSpans.escape(nickname)), nickname);
    });
  });

  group('MarkdownSpans.build', () {
    List<InlineSpan> formulaParts(String source) {
      final TextSpan root =
          MarkdownSpans.build(source, style: AppTextStyles.bodyLg) as TextSpan;
      return (root.children!.single as TextSpan).children!;
    }

    test('cuts an inline formula only after relations', () {
      // `a + b =`, `c - d \leq`, `e`.
      expect(formulaParts(r'$a + b = c - d \leq e$'), hasLength(3));
      expect(formulaParts(r'$a + b - c$'), hasLength(1));
    });

    test('keeps two relations in a row together', () {
      // `x :=`, `y`.
      expect(formulaParts(r'$x := y$'), hasLength(2));
    });

    test('bold text gets a bold span, a formula a widget span', () {
      final InlineSpan span = MarkdownSpans.build(
        r'**Bold** and $x^2$',
        style: AppTextStyles.bodyLg,
      );
      final List<InlineSpan> spans = (span as TextSpan).children!;

      final TextSpan bold = spans.whereType<TextSpan>().firstWhere(
        (TextSpan s) => s.style?.fontWeight == FontWeight.w700,
      );
      expect(bold.toPlainText(), 'Bold');
      final InlineSpan formula = spans.last;
      expect(formula, isA<TextSpan>());
      expect((formula as TextSpan).children!.single, isA<WidgetSpan>());
    });

    test('broken TeX stays text with its delimiters', () {
      final InlineSpan span = MarkdownSpans.build(
        r'Broken $\frac{1$ here',
        style: AppTextStyles.bodyLg,
      );

      expect(span.toPlainText(), r'Broken $\frac{1$ here');
    });
  });
}
