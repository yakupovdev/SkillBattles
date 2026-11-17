import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/app/theme/app_colors.dart';

/// Makes any piece of the design clickable the way a desktop user expects:
/// mouse click with a hand cursor, keyboard focus with Tab, activation with
/// Enter or Space, a visible focus ring drawn just outside the element, and
/// button semantics.
///
/// Use it for every custom tappable (cards, rows, links, tabs) instead of a
/// bare `div` with a click handler, which is unreachable from the keyboard.
/// A `null` [onTap] disables it.
///
/// The tappable IS the box: style it through [classes] / [styles] (a card
/// gives its padding, border and background here) instead of wrapping one
/// more element. [radius] shapes the focus ring.
final class AppTappable extends StatelessComponent {
  const AppTappable({
    required this.onTap,
    required this.child,
    this.classes,
    this.styles,
    this.radius = 0,
    this.focusColor = AppColors.primary,
    this.isSelected,
    this.semanticLabel,
    this.semanticValue,
    super.key,
  });

  final VoidCallback? onTap;
  final Component child;
  final String? classes;
  final Styles? styles;

  /// Corner radius of the box and of its focus ring, px.
  final double radius;

  /// Color of the focus ring; use a contrasting one on filled surfaces.
  final Color focusColor;

  /// Selection state for assistive technology (tabs, choices).
  final bool? isSelected;

  /// Replaces the child's own text for assistive technology when set.
  final String? semanticLabel;

  /// Extra state read after the label ("Correct", "Your answer").
  final String? semanticValue;

  @override
  Component build(BuildContext context) {
    final VoidCallback? tap = onTap;
    final bool enabled = tap != null;
    final String? label = semanticLabel;
    final String? value = semanticValue;
    return div(
      classes: <String>[
        'app-tappable',
        if (!enabled) 'app-tappable--disabled',
        ?classes,
      ].join(' '),
      styles: Styles.combine(<Styles>[
        Styles(
          radius: radius == 0
              ? null
              : BorderRadius.circular(Unit.pixels(radius)),
          raw: <String, String>{'--focus-ring': focusColor.value},
        ),
        ?styles,
      ]),
      attributes: <String, String>{
        'role': 'button',
        'tabindex': enabled ? '0' : '-1',
        if (!enabled) 'aria-disabled': 'true',
        if (isSelected != null) 'aria-pressed': '$isSelected',
        if (label != null)
          'aria-label': value == null ? label : '$label, $value',
      },
      events: enabled
          ? <String, void Function(web.Event)>{
              'click': (web.Event _) => tap(),
              'keydown': (web.Event event) {
                final String key = (event as web.KeyboardEvent).key;
                if (key == 'Enter' || key == ' ') {
                  event.preventDefault();
                  tap();
                }
              },
            }
          : null,
      <Component>[child],
    );
  }
}

@css
List<StyleRule> get appTappableStyles => <StyleRule>[
  css('.app-tappable').styles(
    cursor: Cursor.pointer,
    userSelect: UserSelect.none,
    raw: const <String, String>{'-webkit-tap-highlight-color': 'transparent'},
  ),
  css('.app-tappable:focus-visible').styles(
    raw: const <String, String>{
      'outline': '2px solid var(--focus-ring)',
      'outline-offset': '3px',
    },
  ),
  css('.app-tappable--disabled').styles(cursor: Cursor.defaultCursor),
];
