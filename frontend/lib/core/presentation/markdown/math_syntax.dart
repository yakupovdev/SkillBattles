import 'package:markdown/markdown.dart' as md;

/// Element tags and attributes produced by [MathInlineSyntax] and
/// [MathBlockSyntax].
abstract final class MathTags {
  /// A formula inside a line of text.
  static const String inline = 'math';

  /// A display formula on its own lines (`$$ … $$`, `\[ … \]`).
  static const String block = 'math-block';

  /// The TeX source without delimiters.
  static const String tex = 'tex';

  /// The matched text with delimiters, shown when the TeX does not parse.
  static const String source = 'source';

  /// `'true'` for a display formula (`$$ … $$`, `\[ … \]`) inside a line.
  static const String display = 'display';
}

/// Parses `$$…$$`, `\[…\]` (display) and `\(…\)`, `$…$` (inline) into a
/// [MathTags.inline] element.
///
/// A single `$` follows the Pandoc rule so prices stay text: the opening `$`
/// is not followed by a space, the closing `$` is not preceded by a space
/// and not followed by a digit. `$5 and $10` and `$60.00` are not formulas,
/// and `\$` is a literal dollar.
///
/// Registered before the default syntaxes, so the TeX inside is never read as
/// Markdown (`_` in `$a_1$`, `\(` as an escape).
final class MathInlineSyntax extends md.InlineSyntax {
  MathInlineSyntax() : super(_pattern);

  static const String _pattern =
      r'\$\$([\s\S]+?)\$\$'
      r'|\\\[([\s\S]+?)\\\]'
      r'|\\\(([\s\S]+?)\\\)'
      r'|\$(?!\s)((?:\\.|[^\\$\n])+?)(?<!\s)\$(?!\d)';

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final String? display = match[1] ?? match[2];
    final String tex = (display ?? match[3] ?? match[4] ?? '').trim();
    if (tex.isEmpty) return false;
    parser.addNode(
      md.Element.empty(MathTags.inline)
        ..attributes[MathTags.tex] = tex
        ..attributes[MathTags.source] = match[0]!
        ..attributes[MathTags.display] = (display != null).toString(),
    );
    return true;
  }
}

/// Parses a display formula that starts a line with `$$` or `\[` and closes
/// with `$$` or `\]` at the end of the same or a later line into a
/// [MathTags.block] element.
///
/// Without this block syntax a formula line such as `+ b` or `- c` would be
/// read as a list item. A line where text follows the closing delimiter
/// (`$$x$$ is …`) is left to [MathInlineSyntax], and so is an opening
/// delimiter that never closes.
final class MathBlockSyntax extends md.BlockSyntax {
  const MathBlockSyntax();

  static final RegExp _opening = RegExp(r'^ {0,3}(\$\$|\\\[)');

  @override
  RegExp get pattern => _opening;

  @override
  bool canParse(md.BlockParser parser) => _closingLine(parser) != null;

  @override
  md.Node parse(md.BlockParser parser) {
    final int last = _closingLine(parser)!;
    final List<String> lines = <String>[];
    for (int i = 0; i <= last; i++) {
      lines.add(parser.current.content);
      parser.advance();
    }
    final String source = lines.join('\n').trim();
    final String close = _closeFor(source);
    final String tex = source.substring(2, source.length - close.length).trim();
    return md.Element.empty(MathTags.block)
      ..attributes[MathTags.tex] = tex
      ..attributes[MathTags.source] = source;
  }

  /// Lines ahead of the current one where the formula closes, or `null` when
  /// this is not a display block.
  static int? _closingLine(md.BlockParser parser) {
    final String first = parser.current.content;
    final Match? opening = _opening.firstMatch(first);
    if (opening == null) return null;
    final String close = _closeFor(opening[1]!);
    final String rest = first.substring(opening.end);
    final int sameLine = rest.indexOf(close);
    if (sameLine != -1) {
      final bool onlyFormula = rest
          .substring(sameLine + close.length)
          .trim()
          .isEmpty;
      return onlyFormula && rest.substring(0, sameLine).trim().isNotEmpty
          ? 0
          : null;
    }
    for (int ahead = 1; ; ahead++) {
      final md.Line? line = parser.peek(ahead);
      if (line == null || line.isBlankLine) return null;
      final String content = line.content.trimRight();
      if (content.contains(close)) {
        return content.endsWith(close) &&
                content.indexOf(close) == content.length - close.length
            ? ahead
            : null;
      }
    }
  }

  static String _closeFor(String opening) =>
      opening.startsWith(r'$$') ? r'$$' : r'\]';
}
