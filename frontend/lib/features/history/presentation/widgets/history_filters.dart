import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/battle_mode.dart';
import 'package:skill_battles/core/presentation/extensions/battle_labels.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_segmented_control.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';

/// "All disciplines ⌄" and the All / Ranked / Private switch. `null`
/// values mean "all".
final class HistoryFilters extends StatelessWidget {
  const HistoryFilters({
    required this.disciplines,
    required this.disciplineCode,
    required this.mode,
    required this.onDisciplineSelected,
    required this.onModeSelected,
    super.key,
  });

  final List<DisciplineEntity> disciplines;
  final String? disciplineCode;
  final BattleMode? mode;
  final ValueChanged<String?> onDisciplineSelected;
  final ValueChanged<BattleMode?> onModeSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: <Widget>[
        if (disciplines.length > 1)
          _DisciplineMenu(
            disciplines: disciplines,
            selected: disciplineCode,
            onSelected: onDisciplineSelected,
          ),
        AppSegmentedControl<BattleMode?>(
          size: AppSegmentedControlSize.small,
          selected: mode,
          onSelected: onModeSelected,
          segments: <AppSegment<BattleMode?>>[
            const AppSegment<BattleMode?>(value: null, label: 'All'),
            for (final BattleMode value in BattleMode.values)
              AppSegment<BattleMode?>(value: value, label: value.label),
          ],
        ),
      ],
    );
  }
}

final class _DisciplineMenu extends StatelessWidget {
  const _DisciplineMenu({
    required this.disciplines,
    required this.selected,
    required this.onSelected,
  });

  /// Menu value of "All disciplines": a popup menu ignores `null` values.
  static const String _all = '';

  final List<DisciplineEntity> disciplines;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    String label = 'All disciplines';
    for (final DisciplineEntity d in disciplines) {
      if (d.code == selected) label = d.displayName;
    }
    final BorderRadius radius = BorderRadius.circular(10);
    return PopupMenuButton<String>(
      tooltip: 'Discipline',
      position: PopupMenuPosition.under,
      // The shell's nested navigator leaves the top bar uncovered: a tab tap
      // would switch pages under an open menu. On the root navigator the
      // barrier covers the tabs too, so the tap closes the menu first.
      useRootNavigator: true,
      initialValue: selected ?? _all,
      onSelected: (String code) => onSelected(code == _all ? null : code),
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: _all,
          child: Text('All disciplines'),
        ),
        for (final DisciplineEntity d in disciplines)
          PopupMenuItem<String>(value: d.code, child: Text(d.displayName)),
      ],
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: <Widget>[
            Text(
              label,
              style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w500),
            ),
            const AppSvgIcon(AppIcons.chevronDown, width: 12, height: 12),
          ],
        ),
      ),
    );
  }
}

/// The grey Free banner under the table: older matches are kept, Pro shows
/// them.
final class HistoryUpgradeBanner extends StatelessWidget {
  const HistoryUpgradeBanner({
    required this.limit,
    required this.onUpgrade,
    super.key,
  });

  final int limit;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        child: Row(
          spacing: 24,
          children: <Widget>[
            Expanded(
              child: Row(
                spacing: 14,
                children: <Widget>[
                  const AppSvgIcon(
                    AppIcons.lock,
                    width: 18,
                    height: 18,
                    color: AppColors.ink,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: <Widget>[
                        const Text(
                          'Your older matches are saved, not deleted',
                          style: AppTextStyles.buttonMd,
                        ),
                        Text(
                          'Free shows your latest $limit. Pro opens your full '
                          'history with answers and explanations. Your stats '
                          'already count every match.',
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.muted,
                            height: 18 / 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AppButton(
              label: 'Unlock history',
              variant: AppButtonVariant.dark,
              size: AppButtonSize.dense,
              onPressed: onUpgrade,
            ),
          ],
        ),
      ),
    );
  }
}
