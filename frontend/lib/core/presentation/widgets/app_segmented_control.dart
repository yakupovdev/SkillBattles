import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';

/// One choice of an [AppSegmentedControl].
final class AppSegment<T> {
  const AppSegment({required this.value, required this.label});

  final T value;
  final String label;
}

/// Size of an [AppSegmentedControl]. Every size has a 4 px grey track with
/// radius 10 and a white, raised selected segment.
enum AppSegmentedControlSize {
  /// Full-width tabs, 40 high segments (auth: "Create account" / "Log in").
  large(40, 0, 8, 14, 18, expand: true),

  /// Hugging tabs, 36 high, 14 px labels (stats: "SAT Math" / "SAT R&W").
  medium(36, 16, 8, 14, 18),

  /// Compact filter, 32 high, 13 px labels (history: "All" / "Ranked").
  small(32, 14, 7, 13, 16);

  const AppSegmentedControlSize(
    this.segmentHeight,
    this.horizontalPadding,
    this.segmentRadius,
    this.fontSize,
    this.lineHeight, {
    this.expand = false,
  });

  final double segmentHeight;
  final double horizontalPadding;
  final double segmentRadius;
  final double fontSize;
  final double lineHeight;

  /// Whether the segments share the full available width.
  final bool expand;
}

/// A grey track with a white, raised selected segment.
final class AppSegmentedControl<T> extends StatelessComponent {
  const AppSegmentedControl({
    required this.segments,
    required this.selected,
    required this.onSelected,
    this.size = AppSegmentedControlSize.large,
    super.key,
  });

  final List<AppSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onSelected;
  final AppSegmentedControlSize size;

  @override
  Component build(BuildContext context) {
    return div(
      classes: size.expand ? 'app-segmented' : 'app-segmented app-segmented--hug',
      attributes: const <String, String>{'role': 'group'},
      <Component>[
        for (final AppSegment<T> segment in segments)
          _SegmentButton<T>(
            segment: segment,
            isSelected: segment.value == selected,
            size: size,
            onSelected: onSelected,
          ),
      ],
    );
  }
}

final class _SegmentButton<T> extends StatelessComponent {
  const _SegmentButton({
    required this.segment,
    required this.isSelected,
    required this.size,
    required this.onSelected,
  });

  final AppSegment<T> segment;
  final bool isSelected;
  final AppSegmentedControlSize size;
  final ValueChanged<T> onSelected;

  @override
  Component build(BuildContext context) {
    return AppTappable(
      onTap: () => onSelected(segment.value),
      isSelected: isSelected,
      radius: size.segmentRadius,
      classes: <String>[
        'app-segmented__segment',
        if (size.expand) 'app-segmented__segment--expand',
        if (isSelected) 'app-segmented__segment--selected',
      ].join(' '),
      styles: Styles(
        height: Unit.pixels(size.segmentHeight),
        padding: Padding.symmetric(horizontal: Unit.pixels(size.horizontalPadding)),
        fontSize: Unit.pixels(size.fontSize),
        lineHeight: Unit.pixels(size.lineHeight),
      ),
      child: span(<Component>[Component.text(segment.label)]),
    );
  }
}

@css
List<StyleRule> get appSegmentedControlStyles => <StyleRule>[
  css('.app-segmented').styles(
    display: Display.flex,
    padding: const Padding.all(Unit.pixels(4)),
    radius: const BorderRadius.circular(Unit.pixels(10)),
    backgroundColor: AppColors.surface,
  ),
  css('.app-segmented--hug').styles(width: Unit.fitContent, maxWidth: const Unit.percent(100)),
  css('.app-segmented__segment')
      .styles(
        display: Display.flex,
        transition: const Transition.combine(<Transition>[
          Transition('background-color', duration: Duration(milliseconds: 150)),
          Transition('box-shadow', duration: Duration(milliseconds: 150)),
        ]),
        justifyContent: JustifyContent.center,
        alignItems: AlignItems.center,
        whiteSpace: WhiteSpace.noWrap,
        backgroundColor: Colors.transparent,
      )
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(color: AppColors.muted, fontWeight: FontWeight.w500)),
  css('.app-segmented__segment--expand').styles(
    minWidth: Unit.zero,
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.app-segmented__segment--selected').styles(
    shadow: const BoxShadow(
      offsetX: Unit.zero,
      offsetY: Unit.pixels(1),
      blur: Unit.pixels(2),
      color: AppColors.shadow,
    ),
    color: AppColors.ink,
    fontWeight: FontWeight.w600,
    backgroundColor: AppColors.white,
  ),
];
