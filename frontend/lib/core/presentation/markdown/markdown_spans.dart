import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:markdown/markdown.dart' as md;

import 'package:skill_battles/core/presentation/js/katex.dart';
import 'package:skill_battles/core/presentation/markdown/markdown_styles.dart';
import 'package:skill_battles/core/presentation/markdown/math_fit_width.dart';
import 'package:skill_battles/core/presentation/markdown/math_syntax.dart';

/// Server Markdown with LaTeX, rendered as components built from the
/// `package:markdown` AST.
///
/// The source is untrusted (question text comes from the server), so no
/// Markdown or HTML is ever inserted as markup: every text node becomes an
/// escaped text component, raw HTML in the source is shown as text, link and
/// image URLs are limited to http(s), mailto and relative ones. The only
/// markup inserted as HTML is KaTeX's own output for a formula (KaTeX runs
/// with `trust: false`, so `\href`, `\url` and `\includegraphics` are not
/// rendered).
abstract final class MarkdownSpans {
  /// The document every server text is parsed with: GitHub-flavored Markdown
  /// plus formulas.
  static md.Document document() => md.Document(
    extensionSet: md.ExtensionSet.gitHubFlavored,
    blockSyntaxes: const <md.BlockSyntax>[MathBlockSyntax()],
    inlineSyntaxes: <md.InlineSyntax>[MathInlineSyntax()],
    encodeHtml: false,
  );

  /// [source] without markup, for labels and short previews. A formula
  /// becomes its TeX source.
  static String plainText(String source) {
    final StringBuffer buffer = StringBuffer();
    _writePlain(document().parseInline(source), buffer);
    return buffer.toString();
  }

  /// [text] with Markdown and formula characters escaped, to put plain text
  /// (a nickname) next to server Markdown in one source.
  static String escape(String text) => text.replaceAllMapped(_special, (Match match) => '\\${match[0]}');

  static final RegExp _special = RegExp(r'[\\`*_{}\[\]()#+\-.!|~<>$]');

  /// Inline code inside text: mono at 90%, on the surface color.
  static const Styles codeStyle = MarkdownStyles.code;

  /// Whether [style] is bold (formulas are bold only inside bold text: math
  /// fonts have regular and bold only).
  static bool isBold(Styles? style) {
    final String? weight = style?.properties['font-weight'];
    if (weight == null) return false;
    if (weight == 'bold' || weight == 'bolder') return true;
    return (int.tryParse(weight) ?? 400) >= 700;
  }

  /// The font size of [style] in px, or [fallback].
  static double fontSizeOf(Styles? style, {double fallback = 14}) {
    final String? size = style?.properties['font-size'];
    if (size == null || !size.endsWith('px')) return fallback;
    return double.tryParse(size.substring(0, size.length - 2)) ?? fallback;
  }

  /// [url] when it may be put into an `href` / `src`, otherwise `null`.
  static String? safeUrl(String? url) {
    final String value = url?.trim() ?? '';
    if (value.isEmpty) return null;
    final Uri? uri = Uri.tryParse(value);
    if (uri == null) return null;
    if (!uri.hasScheme) return value.startsWith('//') ? null : value;
    return switch (uri.scheme.toLowerCase()) {
      'http' || 'https' || 'mailto' => value,
      _ => null,
    };
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

/// Inline Markdown with LaTeX as an inline `span` in [style], to put inside
/// a line of text (the counterpart of Flutter's `MarkdownSpans.build`).
///
/// Bold, italic, strikethrough, inline code and formulas keep their look;
/// any other element shows its text. Block structure (lists, headings) is
/// not parsed here — use `AppMarkdownText` for that.
final class MarkdownSpan extends StatelessComponent {
  const MarkdownSpan(this.source, {this.style, super.key});

  final String source;
  final Styles? style;

  @override
  Component build(BuildContext context) {
    return span(classes: 'md-span', styles: style, <Component>[
      MarkdownNodes(nodes: MarkdownSpans.document().parseInline(source), isBold: MarkdownSpans.isBold(style)),
    ]);
  }
}

/// Components for parsed Markdown [nodes] (blocks or inline content).
/// [isBold] tells formulas whether the surrounding text is bold.
final class MarkdownNodes extends StatelessComponent {
  const MarkdownNodes({required this.nodes, required this.isBold, this.isInlineOnly = false, super.key});

  final List<md.Node> nodes;
  final bool isBold;

  /// Draws block elements (a display formula) inline, inside one line.
  final bool isInlineOnly;

  @override
  Component build(BuildContext context) {
    return Component.fragment(<Component>[
      for (final md.Node node in nodes) _MarkdownNode(node: node, isBold: isBold, isInlineOnly: isInlineOnly),
    ]);
  }
}

final class _MarkdownNode extends StatelessComponent {
  const _MarkdownNode({required this.node, required this.isBold, required this.isInlineOnly});

  final md.Node node;
  final bool isBold;
  final bool isInlineOnly;

  static const Set<String> _boldTags = <String>{'strong', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'th'};

  @override
  Component build(BuildContext context) {
    final md.Node node = this.node;
    if (node is! md.Element) return Component.text(node.textContent);
    final Map<String, String> attributes = node.attributes;
    final bool bold = isBold || _boldTags.contains(node.tag);
    final List<md.Node> children = node.children ?? const <md.Node>[];
    final Component content = MarkdownNodes(nodes: children, isBold: bold, isInlineOnly: isInlineOnly);
    final List<Component> inner = <Component>[content];

    switch (node.tag) {
      case MathTags.inline:
      case MathTags.block:
        final bool isDisplay = node.tag == MathTags.block || attributes[MathTags.display] == 'true';
        final Component formula = MarkdownMath(
          tex: attributes[MathTags.tex] ?? '',
          source: attributes[MathTags.source] ?? '',
          isDisplay: isDisplay,
          isBold: bold,
          isBlock: node.tag == MathTags.block && !isInlineOnly,
        );
        return formula;
      case 'br':
        return const br();
      case 'code':
        return code(classes: 'md-code', <Component>[Component.text(node.textContent)]);
      case 'img':
        final String alt = attributes['alt'] ?? '';
        final String? src = MarkdownSpans.safeUrl(attributes['src']);
        if (src == null || isInlineOnly) return Component.text(alt);
        return img(
          src: src,
          alt: alt,
          classes: 'md-img',
          attributes: const <String, String>{'loading': 'lazy', 'referrerpolicy': 'no-referrer'},
        );
      case 'strong':
        return strong(inner);
      case 'em':
        return em(inner);
      case 'del':
        return s(inner);
      case 'a':
        final String? href = MarkdownSpans.safeUrl(attributes['href']);
        if (href == null || isInlineOnly) return span(inner);
        return a(
          href: href,
          target: Target.blank,
          classes: 'md-link',
          attributes: const <String, String>{'rel': 'noopener noreferrer nofollow'},
          inner,
        );
    }
    if (isInlineOnly) return span(inner);
    return switch (node.tag) {
      'p' => p(classes: 'md-block', inner),
      'h1' => h1(classes: 'md-block md-heading', inner),
      'h2' => h2(classes: 'md-block md-heading', inner),
      'h3' => h3(classes: 'md-block md-heading', inner),
      'h4' => h4(classes: 'md-block md-heading', inner),
      'h5' => h5(classes: 'md-block md-heading', inner),
      'h6' => h6(classes: 'md-block md-heading', inner),
      'blockquote' => blockquote(classes: 'md-block md-quote', inner),
      'ul' => ul(classes: 'md-block md-list', inner),
      'ol' => ol(
        classes: 'md-block md-list',
        attributes: <String, String>{'start': ?attributes['start']},
        inner,
      ),
      'li' => li(classes: attributes['class'] == 'task-list-item' ? 'md-task' : null, inner),
      'input' => input(
        type: InputType.checkbox,
        checked: attributes['checked'] != null,
        disabled: true,
        classes: 'md-checkbox',
      ),
      'pre' => pre(classes: 'md-block md-pre', <Component>[
        code(<Component>[Component.text(node.textContent)]),
      ]),
      'hr' => const hr(classes: 'md-block md-hr'),
      'table' => div(classes: 'md-block md-table-scroll', <Component>[table(classes: 'md-table', inner)]),
      'thead' => thead(inner),
      'tbody' => tbody(inner),
      'tr' => tr(inner),
      'th' || 'td' => _TableCell(
        isHeader: node.tag == 'th',
        align: attributes['align'],
        child: content,
      ),
      _ => span(inner),
    };
  }
}

final class _TableCell extends StatelessComponent {
  const _TableCell({required this.isHeader, required this.align, required this.child});

  final bool isHeader;
  final String? align;
  final Component child;

  @override
  Component build(BuildContext context) {
    final Styles? styles = switch (align) {
      'center' => const Styles(textAlign: TextAlign.center),
      'right' => const Styles(textAlign: TextAlign.right),
      'left' => const Styles(textAlign: TextAlign.left),
      _ => null,
    };
    return isHeader ? th(styles: styles, <Component>[child]) : td(styles: styles, <Component>[child]);
  }
}

/// A formula rendered by KaTeX in the size and color of the surrounding
/// text. TeX that does not parse is shown as its original [source] text.
///
/// A display formula on its own lines ([isBlock]) is left aligned and scaled
/// down when it is wider than the text ([MathFitWidth]); inside a line it is
/// drawn in display style and wraps with the words like an inline formula
/// (KaTeX breaks lines after relations and operators).
final class MarkdownMath extends StatelessComponent {
  const MarkdownMath({
    required this.tex,
    required this.source,
    required this.isDisplay,
    required this.isBold,
    this.isBlock = false,
    super.key,
  });

  final String tex;
  final String source;
  final bool isDisplay;
  final bool isBold;
  final bool isBlock;

  @override
  Component build(BuildContext context) {
    final String? html = renderTex(isDisplay && !isBlock ? '\\displaystyle{$tex}' : tex, displayMode: isBlock);
    final String classes = isBold ? 'md-math md-math--bold' : 'md-math';
    if (html == null) {
      return isBlock ? p(classes: 'md-block', <Component>[Component.text(source)]) : Component.text(source);
    }
    final Component formula = span(classes: classes, <Component>[RawText(html)]);
    if (!isBlock) return formula;
    return div(classes: 'md-block md-math-block', <Component>[MathFitWidth(child: formula)]);
  }
}
