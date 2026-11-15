import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/core/presentation/markdown/markdown_spans.dart';
import 'package:skill_battles/core/presentation/markdown/math_fit_width.dart';
import 'package:skill_battles/core/presentation/markdown/math_syntax.dart';

/// Server text in Markdown with LaTeX (`$…$`, `\(…\)`, `$$…$$`, `\[…\]`)
/// rendered as formatted blocks: question, explanation.
///
/// Every style derives from [style]: headings and bold are bold [style],
/// code is mono, formulas take the size and color of the surrounding text.
/// A single newline is kept as a line break. For one paragraph with
/// `maxLines` use [AppMarkdownLine].
final class AppMarkdownText extends StatelessWidget {
  const AppMarkdownText(this.data, {required this.style, super.key});

  final String data;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: MarkdownSpans.plainText(data),
      excludeSemantics: true,
      child: MarkdownBody(
        data: data,
        styleSheet: _styleSheet(style),
        extensionSet: md.ExtensionSet.gitHubFlavored,
        blockSyntaxes: const <md.BlockSyntax>[MathBlockSyntax()],
        inlineSyntaxes: <md.InlineSyntax>[MathInlineSyntax()],
        builders: <String, MarkdownElementBuilder>{
          MathTags.inline: _InlineMathBuilder(style),
          MathTags.block: _BlockMathBuilder(style),
        },
        softLineBreak: true,
      ),
    );
  }

  static MarkdownStyleSheet _styleSheet(TextStyle style) {
    final double size = style.fontSize ?? 14;
    final TextStyle bold = style.copyWith(fontWeight: FontWeight.w700);
    return MarkdownStyleSheet(
      p: style,
      a: style.copyWith(color: AppColors.primary),
      strong: const TextStyle(fontWeight: FontWeight.w700),
      em: const TextStyle(fontStyle: FontStyle.italic),
      del: const TextStyle(decoration: TextDecoration.lineThrough),
      code: MarkdownSpans.codeStyle(style),
      h1: bold,
      h2: bold,
      h3: bold,
      h4: bold,
      h5: bold,
      h6: bold,
      blockquote: style.copyWith(color: AppColors.inkSoft),
      listBullet: style,
      tableHead: bold,
      tableBody: style,
      tableBorder: TableBorder.all(color: AppColors.border),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      blockSpacing: size * 0.5,
      blockquotePadding: const EdgeInsets.only(left: 12),
      blockquoteDecoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.border, width: 3)),
      ),
      codeblockPadding: const EdgeInsets.all(12),
      codeblockDecoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      horizontalRuleDecoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
    );
  }
}

/// One paragraph of inline Markdown with LaTeX that can be cut to
/// [maxLines]: answer options, tags, review rows.
final class AppMarkdownLine extends StatelessWidget {
  const AppMarkdownLine(
    this.data, {
    required this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    super.key,
  });

  final String data;
  final TextStyle style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      MarkdownSpans.build(data, style: style),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      semanticsLabel: MarkdownSpans.plainText(data),
    );
  }
}

/// A formula inside a paragraph. The returned `Text.rich` is merged into the
/// paragraph's text, so the formula wraps with the words around it.
final class _InlineMathBuilder extends MarkdownElementBuilder {
  _InlineMathBuilder(this._style);

  final TextStyle _style;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final Map<String, String> attributes = element.attributes;
    return Text.rich(
      MarkdownSpans.math(
        tex: attributes[MathTags.tex] ?? '',
        source: attributes[MathTags.source] ?? '',
        isDisplay: attributes[MathTags.display] == 'true',
        style: _style.merge(parentStyle),
      ),
    );
  }
}

/// A display formula on its own lines.
final class _BlockMathBuilder extends MarkdownElementBuilder {
  _BlockMathBuilder(this._style);

  final TextStyle _style;

  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return _DisplayMath(
      tex: element.attributes[MathTags.tex] ?? '',
      source: element.attributes[MathTags.source] ?? '',
      style: _style,
    );
  }
}

/// A display formula on its own line, scaled down when it is wider than the
/// text.
final class _DisplayMath extends StatelessWidget {
  const _DisplayMath({
    required this.tex,
    required this.source,
    required this.style,
  });

  final String tex;
  final String source;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final Math formula = MarkdownSpans.mathWidget(
      tex: tex,
      source: source,
      style: style,
      isDisplay: true,
    );
    if (formula.parseError != null) return Text(source, style: style);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: MathFitWidth(child: formula),
    );
  }
}
