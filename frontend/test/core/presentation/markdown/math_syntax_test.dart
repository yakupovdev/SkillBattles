import 'package:flutter_test/flutter_test.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:skill_battles/core/presentation/markdown/markdown_spans.dart';
import 'package:skill_battles/core/presentation/markdown/math_syntax.dart';

List<md.Node> _parse(String source) =>
    MarkdownSpans.document().parseLines(source.split('\n'));

/// Every math element in [nodes], depth first.
List<md.Element> _math(List<md.Node>? nodes) => <md.Element>[
  for (final md.Node node in nodes ?? const <md.Node>[])
    if (node is md.Element) ...<md.Element>[
      if (node.tag == MathTags.inline || node.tag == MathTags.block) node,
      ..._math(node.children),
    ],
];

void main() {
  group('MathInlineSyntax', () {
    test('parses \$…\$ as an inline formula without Markdown inside', () {
      final List<md.Element> math = _math(_parse(r'Solve $a_1 * b_1 = 0$.'));

      expect(math, hasLength(1));
      expect(math.single.tag, MathTags.inline);
      expect(math.single.attributes[MathTags.tex], r'a_1 * b_1 = 0');
      expect(math.single.attributes[MathTags.display], 'false');
    });

    test('parses \\(…\\) as inline and \$\$…\$\$, \\[…\\] in a line as '
        'display', () {
      final List<md.Element> math = _math(
        _parse(r'A \(x\) and $$\frac{a}{b}$$ and \[y^2\] here'),
      );

      expect(math.map((md.Element e) => e.attributes[MathTags.tex]), <String>[
        'x',
        r'\frac{a}{b}',
        'y^2',
      ]);
      expect(
        math.map((md.Element e) => e.attributes[MathTags.display]),
        <String>['false', 'true', 'true'],
      );
    });

    test('leaves prices and an escaped dollar as text', () {
      expect(_math(_parse(r'Costs $5 and $10, total $60.00')), isEmpty);
      expect(_math(_parse(r'Pay \$5 now')), isEmpty);
    });

    test('keeps the original source for a fallback', () {
      final md.Element math = _math(_parse(r'Is \(\frac{1\) ok')).single;

      expect(math.attributes[MathTags.source], r'\(\frac{1\)');
    });
  });

  group('MathBlockSyntax', () {
    test('parses a multi-line \$\$ block, so its lines are not a list', () {
      final List<md.Node> nodes = _parse('Compute:\n\$\$\nx\n+ 1\n\$\$\nDone');
      final List<md.Element> math = _math(nodes);

      expect(math.single.tag, MathTags.block);
      expect(math.single.attributes[MathTags.tex], 'x\n+ 1');
      expect(
        nodes.whereType<md.Element>().map((md.Element e) => e.tag),
        <String>['p', MathTags.block, 'p'],
      );
    });

    test('parses a one-line \\[…\\] block', () {
      final md.Element math = _math(_parse(r'\[ \sqrt{2} \]')).single;

      expect(math.tag, MathTags.block);
      expect(math.attributes[MathTags.tex], r'\sqrt{2}');
    });

    test('leaves an unclosed \$\$ as text', () {
      expect(_math(_parse('\$\$\nx + 1')), isEmpty);
    });
  });
}
