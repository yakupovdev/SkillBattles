import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';

/// A form-level error under the fields, announced to screen readers.
final class AppInlineError extends StatelessComponent {
  const AppInlineError(this.message, {super.key});

  final String message;

  @override
  Component build(BuildContext context) {
    return p(
      classes: 'app-inline-error',
      attributes: const <String, String>{'role': 'alert', 'aria-live': 'polite'},
      <Component>[Component.text(message)],
    );
  }
}

@css
List<StyleRule> get appInlineErrorStyles => <StyleRule>[
  css('.app-inline-error')
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.danger, lineHeight: Unit.pixels(18))),
];
