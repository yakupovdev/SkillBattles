import 'package:material_ui/material_ui.dart';

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
final class AppSegmentedControl<T> extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: size.expand ? MainAxisSize.max : MainAxisSize.min,
          children: <Widget>[
            for (final AppSegment<T> segment in segments)
              if (size.expand)
                Expanded(
                  child: _SegmentButton<T>(
                    segment: segment,
                    isSelected: segment.value == selected,
                    size: size,
                    onSelected: onSelected,
                  ),
                )
              else
                _SegmentButton<T>(
                  segment: segment,
                  isSelected: segment.value == selected,
                  size: size,
                  onSelected: onSelected,
                ),
          ],
        ),
      ),
    );
  }
}

final class _SegmentButton<T> extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(size.segmentRadius);
    return AppTappable(
      onTap: () => onSelected(segment.value),
      isSelected: isSelected,
      borderRadius: radius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: size.segmentHeight,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: size.horizontalPadding),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : Colors.transparent,
          borderRadius: radius,
          boxShadow: isSelected
              ? const <BoxShadow>[
                  BoxShadow(
                    color: AppColors.shadow,
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Text(
          segment.label,
          style: AppTextStyles.bodyMd.copyWith(
            fontSize: size.fontSize,
            height: size.lineHeight / size.fontSize,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.ink : AppColors.muted,
          ),
        ),
      ),
    );
  }
}
