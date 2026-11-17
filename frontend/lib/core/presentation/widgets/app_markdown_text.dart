import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/core/presentation/markdown/markdown_spans.dart';

/// Server text in Markdown with LaTeX (`$…$`, `\(…\)`, `$$…$$`, `\[…\]`)
/// rendered as formatted blocks: question, explanation.
///
/// Every style derives from [style]: headings and bold are bold [style],
/// code is mono, formulas take the size and color of the surrounding text.
/// A single newline is kept as a line break. For one paragraph with
/// `maxLines` use [AppMarkdownLine]. The text is never inserted as HTML (see
/// [MarkdownSpans]).
final class AppMarkdownText extends StatelessComponent {
  const AppMarkdownText(this.data, {required this.style, super.key});

  final String data;
  final Styles style;

  @override
  Component build(BuildContext context) {
    final double gap = MarkdownSpans.fontSizeOf(style) * 0.5;
    return div(
      classes: 'md-text',
      styles: style.combine(Styles(raw: <String, String>{'--md-gap': '${gap}px'})),
      <Component>[
        MarkdownNodes(nodes: MarkdownSpans.document().parse(data), isBold: MarkdownSpans.isBold(style)),
      ],
    );
  }
}

/// One paragraph of inline Markdown with LaTeX that can be cut to
/// [maxLines]: answer options, tags, review rows.
final class AppMarkdownLine extends StatelessComponent {
  const AppMarkdownLine(
    this.data, {
    required this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    super.key,
  });

  final String data;
  final Styles style;
  final int? maxLines;

  /// `TextOverflow.ellipsis` (the default with [maxLines]) or `clip`.
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Component build(BuildContext context) {
    final int? lines = maxLines;
    return div(
      classes: lines == null ? 'md-line' : 'md-line md-line--clamped',
      styles: style.combine(
        Styles(
          textAlign: textAlign,
          raw: <String, String>{
            if (lines != null) '-webkit-line-clamp': '$lines',
            if (lines != null) 'line-clamp': '$lines',
            if (overflow == TextOverflow.clip) 'text-overflow': 'clip',
          },
        ),
      ),
      <Component>[
        MarkdownNodes(
          nodes: MarkdownSpans.document().parseInline(data),
          isBold: MarkdownSpans.isBold(style),
          isInlineOnly: true,
        ),
      ],
    );
  }
}
