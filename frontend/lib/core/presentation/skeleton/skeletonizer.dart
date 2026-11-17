import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The real UI rendered with mock data and painted as bones — the web
/// counterpart of `package:skeletonizer` (see `.claude/rules`
/// `skeleton_loading.md`).
///
/// While [enabled], every leaf element of [child] (text, icons, images,
/// empty boxes) is painted as a shimmering bone, and pointer events are
/// ignored so taps never act on mock data. No extra DOM node is added: the
/// class goes on the child's root element.
final class Skeletonizer extends StatelessComponent {
  const Skeletonizer({required this.enabled, required this.child, super.key});

  final bool enabled;
  final Component child;

  /// The nearest [Skeletonizer] above [context], if any.
  static Skeletonizer? maybeOf(BuildContext context) =>
      (context.dependOnInheritedComponentOfExactType<_SkeletonScope>())
          ?.skeletonizer;

  /// Whether [context] is inside an enabled [Skeletonizer]. Components that
  /// load from the network check it and skip the load.
  static bool isEnabled(BuildContext context) =>
      maybeOf(context)?.enabled ?? false;

  @override
  Component build(BuildContext context) => _SkeletonScope(
    skeletonizer: this,
    child: Component.wrapElement(
      classes: enabled ? 'sk-on' : null,
      attributes: enabled
          ? const <String, String>{'aria-busy': 'true', 'inert': ''}
          : null,
      child: child,
    ),
  );
}

final class _SkeletonScope extends InheritedComponent {
  const _SkeletonScope({required this.skeletonizer, required super.child});

  final Skeletonizer skeletonizer;

  @override
  bool updateShouldNotify(_SkeletonScope oldComponent) =>
      skeletonizer.enabled != oldComponent.skeletonizer.enabled;
}

/// Annotations for the real components under a [Skeletonizer]; no-ops when
/// it is disabled. Each puts a class on the child's root element.
abstract final class Skeleton {
  /// Stays visible while loading (a static label, a section icon).
  static Component keep({required Component child}) =>
      Component.wrapElement(classes: 'sk-keep', child: child);

  /// Hidden while loading (badges, counters, actions without data).
  static Component ignore({required Component child}) =>
      Component.wrapElement(classes: 'sk-ignore', child: child);

  /// The whole subtree is one bone (a card, a chip, a stat tile).
  static Component leaf({required Component child}) =>
      Component.wrapElement(classes: 'sk-leaf', child: child);

  /// Several small bones (a row of icons) become one.
  static Component unite({required Component child}) => leaf(child: child);
}

/// Mock strings of a realistic length for skeleton data.
abstract final class BoneMock {
  static const String name = 'Jordan Blake';
  static const String title = 'Lorem ipsum dolor sit';
  static const String date = 'Jan 12, 2026';

  /// [count] words of five letters.
  static String words(int count) =>
      List<String>.filled(count, 'lorem').join(' ');

  /// [count] characters.
  static String chars(int count) => 'x' * count;
}

/// `AppColors.skeletonLight` → `AppColors.skeletonHighlight` shimmer.
const String _bone =
    'linear-gradient(90deg, #EDEEF1 25%, #F7F8FA 50%, #EDEEF1 75%)';

/// Bones of an enabled [Skeletonizer] (the still look under reduced
/// motion is in `web/styles/base.css`). `:not(:has(*))` picks the leaf
/// elements, the ones that hold text or draw something by themselves.
@css
List<StyleRule> get skeletonStyles => <StyleRule>[
  css.keyframes('sk-shimmer', <String, Styles>{
    '0%': const Styles(raw: <String, String>{'background-position': '100% 0'}),
    '100%': const Styles(raw: <String, String>{'background-position': '0 0'}),
  }),
  css('.sk-on').styles(
    userSelect: UserSelect.none,
    pointerEvents: PointerEvents.none,
  ),
  css(
    '.sk-on :not(:has(*)):not(.sk-keep, .sk-keep *, .sk-ignore, .sk-ignore *), '
    '.sk-on.sk-leaf, .sk-on .sk-leaf:not(.sk-keep *)',
  ).styles(
    raw: const <String, String>{
      'border-color': 'transparent !important',
      'border-radius': '4px',
      'box-shadow': 'none !important',
      'background': '$_bone !important',
      'background-size': '400% 100% !important',
      'animation': 'sk-shimmer 1.4s ease-in-out infinite',
      'color': 'transparent !important',
      'caret-color': 'transparent',
      '-webkit-text-fill-color': 'transparent',
    },
  ),
  css('.sk-on .sk-leaf *, .sk-on.sk-leaf *').styles(
    visibility: Visibility.hidden,
  ),
  css('.sk-on img, .sk-on video').styles(
    raw: const <String, String>{'object-position': '-99999px 0'},
  ),
  css('.sk-on .sk-ignore').styles(visibility: Visibility.hidden),
];
