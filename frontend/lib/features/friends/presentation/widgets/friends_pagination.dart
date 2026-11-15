import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/page_info_entity.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';

/// "Showing 1–20 of 45" with Previous / Next (Paper: sheet 36, "39 Friends —
/// loaded"). Used by the requests, the friends list and, with a [unit], the
/// friend picker.
///
/// [itemCount] is the number of items on the shown page. A `null`
/// [onPageSelected] disables both buttons (a page is changing).
final class FriendsPagination extends StatelessWidget {
  const FriendsPagination({
    required this.page,
    required this.itemCount,
    required this.onPageSelected,
    this.unit,
    super.key,
  });

  final PageInfoEntity page;
  final int itemCount;
  final ValueChanged<int>? onPageSelected;

  /// When set the label reads `1–5 of 12 {unit}` instead of
  /// `Showing 1–5 of 12`.
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final int total = page.totalElements;
    final int from = page.page * page.size + 1;
    final int to = from - 1 + itemCount;
    final ValueChanged<int>? select = onPageSelected;
    final String range = total == 0 || itemCount == 0
        ? '0 of 0'
        : '$from–$to of $total';
    final String label = unit == null ? 'Showing $range' : '$range $unit';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
          ),
        ),
        Row(
          spacing: 8,
          children: <Widget>[
            AppButton(
              label: 'Previous',
              variant: AppButtonVariant.outline,
              size: AppButtonSize.compact,
              onPressed: select != null && page.hasPrevious
                  ? () => select(page.page - 1)
                  : null,
            ),
            AppButton(
              label: 'Next',
              variant: AppButtonVariant.outline,
              size: AppButtonSize.compact,
              onPressed: select != null && page.hasNext
                  ? () => select(page.page + 1)
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}
