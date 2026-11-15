import 'package:flutter_math_fork/ast.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/markdown/math_fit_width.dart';
import 'package:skill_battles/core/presentation/markdown/math_syntax.dart';

/// Inline Markdown with LaTeX as text spans, for one-paragraph text that
/// needs `maxLines` / ellipsis (answer options, tags, list rows).
///
/// Bold, italic, strikethrough, inline code and formulas keep their look;
/// any other element shows its text. Block structure (lists, headings) is
/// not parsed here — use `AppMarkdownText` for that.
abstract final class MarkdownSpans {
  /// The document every server text is parsed with: GitHub-flavored Markdown
  /// plus formulas.
  static md.Document document() => md.Document(
    extensionSet: md.ExtensionSet.gitHubFlavored,
    blockSyntaxes: const <md.BlockSyntax>[MathBlockSyntax()],
    inlineSyntaxes: <md.InlineSyntax>[MathInlineSyntax()],
    encodeHtml: false,
  );

  /// [source] as one span tree in [style].
  static InlineSpan build(String source, {required TextStyle style}) {
    final List<md.Node> nodes = document().parseInline(source);
    return TextSpan(style: style, children: _spans(nodes, style));
  }

  /// [source] without markup, for semantics and short previews. A formula
  /// becomes its TeX source.
  static String plainText(String source) {
    final StringBuffer buffer = StringBuffer();
    _writePlain(document().parseInline(source), buffer);
    return buffer.toString();
  }

  /// [text] with Markdown and formula characters escaped, to put plain text
  /// (a nickname) next to server Markdown in one source.
  static String escape(String text) =>
      text.replaceAllMapped(_special, (Match match) => '\\${match[0]}');

  static final RegExp _special = RegExp(r'[\\`*_{}\[\]()#+\-.!|~<>$]');

  /// A formula in [style]. TeX that does not parse or build is shown as the
  /// original [source] text.
  ///
  /// An inline formula wraps like words, but only after a relation (`=`,
  /// `<`, `\geq`): a part that ends with `+` or `-` would lose the spacing
  /// around it. The space a part loses after its closing relation is put back
  /// as padding. A part, or a display formula, wider than the line is scaled
  /// down to fit instead of overflowing.
  static InlineSpan math({
    required String tex,
    required String source,
    required bool isDisplay,
    required TextStyle style,
  }) {
    final Math formula = mathWidget(
      tex: tex,
      source: source,
      style: style,
      isDisplay: isDisplay,
    );
    if (formula.parseError != null) {
      return TextSpan(text: source, style: style);
    }
    final List<Math> parts = isDisplay
        ? <Math>[formula]
        : _splitAfterRelations(formula);
    final double gap =
        (style.fontSize ?? AppTextStyles.bodyMd.fontSize!) * _relationSpace;
    return TextSpan(
      children: <InlineSpan>[
        for (int i = 0; i < parts.length; i++)
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: MathFitWidth(
              child: i == parts.length - 1
                  ? parts[i]
                  : Padding(
                      padding: EdgeInsets.only(right: gap),
                      child: parts[i],
                    ),
            ),
          ),
      ],
    );
  }

  /// A `Math` widget for [tex] in [style] that shows [source] as text when
  /// it fails to build.
  static Math mathWidget({
    required String tex,
    required String source,
    required TextStyle style,
    required bool isDisplay,
  }) => Math.tex(
    tex,
    mathStyle: isDisplay ? MathStyle.display : MathStyle.text,
    textStyle: mathTextStyle(style),
    onErrorFallback: (FlutterMathException _) => Text(source, style: style),
  );

  /// [formula] cut after every relation that is not followed by another
  /// relation (`:=` stays whole) or a `\nobreak`.
  ///
  /// `Math.texBreak` cannot be used: it always cuts after binary operators
  /// too, and its penalties only describe the cuts.
  static List<Math> _splitAfterRelations(Math formula) {
    final GreenNode? root = formula.ast?.greenRoot;
    if (root is! EquationRowNode) return <Math>[formula];
    final List<GreenNode> children = root.flattenedChildList;
    final List<int> carets = root.caretPositions;
    final List<Math> parts = <Math>[];
    int start = carets.first;
    for (int i = 0; i < children.length - 1; i++) {
      final GreenNode next = children[i + 1];
      final bool keepsTogether =
          next.leftType == AtomType.rel ||
          (next is SpaceNode && (next.breakPenalty ?? 0) >= _noBreak);
      if (children[i].rightType != AtomType.rel || keepsTogether) continue;
      parts.add(_part(formula, root, start, carets[i + 1]));
      start = carets[i + 1];
    }
    if (parts.isEmpty) return <Math>[formula];
    parts.add(_part(formula, root, start, carets.last));
    return parts;
  }

  static Math _part(Math formula, EquationRowNode root, int from, int to) =>
      Math(
        ast: SyntaxTree(
          greenRoot: root.clipChildrenBetween(from, to).wrapWithEquationRow(),
        ),
        mathStyle: formula.mathStyle,
        textStyle: formula.textStyle,
        onErrorFallback: formula.onErrorFallback,
      );

  /// The TeX penalty that forbids a line break.
  static const int _noBreak = 10000;

  /// TeX `\thickmuskip` (5 mu, 1 mu = 1/18 em): the space after a relation.
  static const double _relationSpace = 5 / 18;

  /// The size and color of [style] for a formula. Math fonts have regular
  /// and bold only, so a formula is bold only inside bold text.
  static TextStyle mathTextStyle(TextStyle style) => TextStyle(
    fontSize: style.fontSize ?? AppTextStyles.bodyMd.fontSize,
    color: style.color ?? AppColors.ink,
    fontWeight:
        (style.fontWeight ?? FontWeight.w400).value >= FontWeight.w700.value
        ? FontWeight.w700
        : FontWeight.w400,
  );

  /// Inline code inside text of [style].
  static TextStyle codeStyle(TextStyle style) => style.copyWith(
    fontFamily: AppFonts.mono,
    fontSize: (style.fontSize ?? 14) * 0.9,
    letterSpacing: 0,
    backgroundColor: AppColors.surface,
  );

  static List<InlineSpan> _spans(
    List<md.Node>? nodes,
    TextStyle style,
  ) => <InlineSpan>[
    for (final md.Node node in nodes ?? const <md.Node>[]) _span(node, style),
  ];

  static InlineSpan _span(md.Node node, TextStyle style) {
    if (node is! md.Element) return TextSpan(text: node.textContent);
    final Map<String, String> attributes = node.attributes;
    switch (node.tag) {
      case MathTags.inline || MathTags.block:
        return math(
          tex: attributes[MathTags.tex] ?? '',
          source: attributes[MathTags.source] ?? '',
          isDisplay:
              node.tag == MathTags.block ||
              attributes[MathTags.display] == 'true',
          style: style,
        );
      case 'br':
        return const TextSpan(text: '\n');
      case 'code':
        return TextSpan(text: node.textContent, style: codeStyle(style));
      case 'img':
        return TextSpan(text: attributes['alt'] ?? '');
    }
    final TextStyle? delta = switch (node.tag) {
      'strong' => const TextStyle(fontWeight: FontWeight.w700),
      'em' => const TextStyle(fontStyle: FontStyle.italic),
      'del' => const TextStyle(decoration: TextDecoration.lineThrough),
      _ => null,
    };
    final TextStyle childStyle = delta == null ? style : style.merge(delta);
    return TextSpan(style: delta, children: _spans(node.children, childStyle));
  }

  static void _writePlain(List<md.Node>? nodes, StringBuffer buffer) {
    for (final md.Node node in nodes ?? const <md.Node>[]) {
      if (node is! md.Element) {
        buffer.write(node.textContent);
      } else if (node.tag == MathTags.inline || node.tag == MathTags.block) {
        buffer.write(node.attributes[MathTags.tex] ?? '');
      } else if (node.tag == 'br') {
        buffer.write('\n');
      } else if (node.tag == 'img') {
        buffer.write(node.attributes['alt'] ?? '');
      } else {
        _writePlain(node.children, buffer);
      }
    }
  }
}
