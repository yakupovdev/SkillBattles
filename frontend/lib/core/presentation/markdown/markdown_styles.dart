import 'package:jaspr/dom.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';

/// Styles of the rendered Markdown (`MarkdownSpans`, `AppMarkdownText`,
/// `AppMarkdownLine`).
///
/// They live apart from the components on purpose: the components import
/// the KaTeX binding (`dart:js_interop`), and the `@css` collector compiles
/// every library that declares styles on the Dart VM, where that library
/// does not exist.
abstract final class MarkdownStyles {
  /// Inline code inside text: mono at 90%, on the surface color.
  static const Styles code = Styles(
    fontFamily: AppFonts.mono,
    fontSize: Unit.em(0.9),
    letterSpacing: Unit.zero,
    backgroundColor: AppColors.surface,
  );

  @css
  static List<StyleRule> get styles => <StyleRule>[
    css('.md-code')
        .combine(code)
        .styles(
          padding: const Padding.symmetric(horizontal: Unit.em(0.2)),
          radius: const BorderRadius.circular(Unit.pixels(4)),
        ),
    css('.md-math').styles(whiteSpace: WhiteSpace.normal),
    css('.md-math .katex').styles(fontSize: const Unit.em(1), raw: const <String, String>{'text-rendering': 'auto'}),
    css('.md-math--bold .katex').styles(fontWeight: FontWeight.w700),
    css('.md-math-block .katex-display').styles(margin: Margin.zero, textAlign: TextAlign.left),
    css('.md-math-block .katex-display > .katex').styles(textAlign: TextAlign.left),
    css('.md-link').styles(
      color: AppColors.primary,
      textDecoration: const TextDecoration(line: TextDecorationLine.underline),
    ),
    css('.md-img').styles(height: Unit.auto, maxWidth: const Unit.percent(100)),
    css('.md-text, .md-line').styles(
      minWidth: Unit.zero,
      whiteSpace: WhiteSpace.preLine,
      raw: const <String, String>{'overflow-wrap': 'break-word'},
    ),
    css('.md-line--clamped').styles(
      overflow: Overflow.hidden,
      raw: const <String, String>{'display': '-webkit-box', '-webkit-box-orient': 'vertical'},
    ),
    css('.md-text', <StyleRule>[
      css('& .md-block + .md-block, & li + li').styles(margin: const Margin.only(top: Unit.variable('--md-gap'))),
      css('& .md-heading').styles(
        fontSize: Unit.inherit,
        fontWeight: FontWeight.w700,
        letterSpacing: Unit.inherit,
        lineHeight: Unit.inherit,
      ),
      css('& strong').styles(fontWeight: FontWeight.w700),
      css('& .md-quote').styles(
        padding: const Padding.only(left: Unit.pixels(12)),
        border: const Border.only(
          left: BorderSide(color: AppColors.border, width: Unit.pixels(3)),
        ),
        color: AppColors.inkSoft,
      ),
      css('& ul.md-list').styles(
        padding: const Padding.only(left: Unit.pixels(24)),
        listStyle: ListStyle.disc,
      ),
      css('& ol.md-list').styles(
        padding: const Padding.only(left: Unit.pixels(24)),
        listStyle: ListStyle.decimal,
      ),
      css('& .md-task').styles(listStyle: ListStyle.none),
      css('& .md-checkbox').styles(margin: const Margin.only(right: Unit.pixels(6))),
      css('& .md-pre').styles(
        padding: const Padding.all(Unit.pixels(12)),
        radius: const BorderRadius.circular(Unit.pixels(8)),
        overflow: Overflow.auto,
        fontFamily: AppFonts.mono,
        fontSize: const Unit.em(0.9),
        letterSpacing: Unit.zero,
        whiteSpace: WhiteSpace.pre,
        backgroundColor: AppColors.surface,
      ),
      css('& .md-hr').styles(
        height: Unit.zero,
        border: const Border.only(
          top: BorderSide(color: AppColors.border, width: Unit.pixels(1)),
        ),
      ),
      css('& .md-table-scroll').styles(maxWidth: const Unit.percent(100), overflow: Overflow.auto),
      css('& .md-table').styles(raw: const <String, String>{'border-collapse': 'collapse'}),
      css('& .md-table th, & .md-table td').styles(
        padding: const Padding.symmetric(horizontal: Unit.pixels(8), vertical: Unit.pixels(4)),
        border: Border.all(color: AppColors.border, width: const Unit.pixels(1)),
        textAlign: TextAlign.left,
      ),
      css('& .md-table th').styles(fontWeight: FontWeight.w700),
    ]),
  ];
}
