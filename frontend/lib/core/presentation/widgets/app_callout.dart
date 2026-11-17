import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_link.dart';

/// Colors and icon of an [AppCallout].
enum AppCalloutTone {
  /// "Check your inbox".
  success(
    AppColors.successCallout,
    AppColors.successTitle,
    AppColors.successBody,
    AppIcons.statusSuccess,
  ),

  /// "This link has expired or was already used".
  danger(
    AppColors.dangerSurface,
    AppColors.dangerTitle,
    AppColors.dangerBody,
    AppIcons.statusError,
  );

  const AppCalloutTone(this.background, this.title, this.body, this.icon);

  final Color background;
  final Color title;
  final Color body;
  final String icon;
}

/// A tinted result box with a round status icon, a bold title, a body and
/// an optional inline link after the body.
final class AppCallout extends StatelessComponent {
  const AppCallout({
    required this.title,
    required this.message,
    required this.tone,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String message;
  final AppCalloutTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  static const Styles _body = Styles(lineHeight: Unit.pixels(19));

  @override
  Component build(BuildContext context) {
    final String? label = actionLabel;
    return div(
      classes: 'app-callout',
      styles: Styles(backgroundColor: tone.background),
      attributes: const <String, String>{'role': 'status', 'aria-live': 'polite'},
      <Component>[
        AppSvgIcon(tone.icon, width: 20, height: 20),
        div(classes: 'app-callout__text', <Component>[
          p(
            classes: 'app-callout__title',
            styles: Styles(color: tone.title),
            <Component>[Component.text(title)],
          ),
          p(
            classes: 'app-callout__body',
            styles: Styles(color: tone.body),
            <Component>[Component.text(message)],
          ),
          if (label != null)
            AppTextLink(
              label: label,
              style: AppTextStyles.bodySm
                  .combine(_body)
                  .combine(
                    const Styles(color: AppColors.primary, fontWeight: FontWeight.w500),
                  ),
              onPressed: onAction,
            ),
        ]),
      ],
    );
  }
}

@css
List<StyleRule> get appCalloutStyles => <StyleRule>[
  css('.app-callout').styles(
    display: Display.flex,
    padding: const Padding.all(Unit.pixels(16)),
    radius: const BorderRadius.circular(Unit.pixels(12)),
    alignItems: AlignItems.start,
    gap: const Gap.column(Unit.pixels(12)),
  ),
  css('.app-callout__text').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(4)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.app-callout__title').combine(AppTextStyles.buttonMd),
  css('.app-callout__body').combine(AppTextStyles.bodySm).combine(AppCallout._body),
];
