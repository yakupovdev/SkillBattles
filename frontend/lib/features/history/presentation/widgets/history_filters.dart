import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

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
final class HistoryFilters extends StatelessComponent {
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
  Component build(BuildContext context) {
    return div(classes: 'history-filters', <Component>[
      if (disciplines.length > 1)
        _DisciplineMenu(disciplines: disciplines, selected: disciplineCode, onSelected: onDisciplineSelected),
      AppSegmentedControl<BattleMode?>(
        size: AppSegmentedControlSize.small,
        selected: mode,
        onSelected: onModeSelected,
        segments: <AppSegment<BattleMode?>>[
          const AppSegment<BattleMode?>(value: null, label: 'All'),
          for (final BattleMode value in BattleMode.values) AppSegment<BattleMode?>(value: value, label: value.label),
        ],
      ),
    ]);
  }
}

/// A native `<select>` drawn as the outlined menu button of the design; the
/// option list is the browser's.
final class _DisciplineMenu extends StatelessComponent {
  const _DisciplineMenu({required this.disciplines, required this.selected, required this.onSelected});

  /// Option value of "All disciplines".
  static const String _all = '';

  final List<DisciplineEntity> disciplines;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Component build(BuildContext context) {
    final String value = selected ?? _all;
    return div(classes: 'history-filters__menu', <Component>[
      select(
        value: value,
        classes: 'history-filters__select',
        attributes: const <String, String>{'aria-label': 'Discipline', 'title': 'Discipline'},
        events: <String, void Function(web.Event)>{
          'change': (web.Event event) {
            final String code = (event.target! as web.HTMLSelectElement).value;
            onSelected(code == _all ? null : code);
          },
        },
        <Component>[
          option(value: _all, selected: value == _all, <Component>[const Component.text('All disciplines')]),
          for (final DisciplineEntity d in disciplines)
            option(value: d.code, selected: value == d.code, <Component>[Component.text(d.displayName)]),
        ],
      ),
      const span(classes: 'history-filters__chevron', <Component>[
        AppSvgIcon(AppIcons.chevronDown, width: 12, height: 12),
      ]),
    ]);
  }
}

/// The grey Free banner under the table: older matches are kept, Pro shows
/// them.
final class HistoryUpgradeBanner extends StatelessComponent {
  const HistoryUpgradeBanner({required this.limit, required this.onUpgrade, super.key});

  final int limit;
  final VoidCallback onUpgrade;

  @override
  Component build(BuildContext context) {
    return div(classes: 'history-upgrade', <Component>[
      div(classes: 'history-upgrade__info', <Component>[
        const AppSvgIcon(AppIcons.lock, width: 18, height: 18, color: AppColors.ink),
        div(classes: 'history-upgrade__texts', <Component>[
          const p(classes: 'history-upgrade__title', <Component>[
            Component.text('Your older matches are saved, not deleted'),
          ]),
          p(classes: 'history-upgrade__body', <Component>[
            Component.text(
              'Free shows your latest $limit. Pro opens your full '
              'history with answers and explanations. Your stats '
              'already count every match.',
            ),
          ]),
        ]),
      ]),
      AppButton(
        label: 'Unlock history',
        variant: AppButtonVariant.dark,
        size: AppButtonSize.dense,
        onPressed: onUpgrade,
      ),
    ]);
  }
}

@css
List<StyleRule> get historyFiltersStyles => <StyleRule>[
  css('.history-filters').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(12)),
    flex: const Flex(shrink: 0),
  ),
  css('.history-filters__menu').styles(position: const Position.relative()),
  css('.history-filters__select')
      .styles(
        height: const Unit.pixels(40),
        padding: const Padding.only(left: Unit.pixels(14), right: Unit.pixels(34)),
        border: Border.all(color: AppColors.border, width: const Unit.pixels(1)),
        radius: const BorderRadius.circular(Unit.pixels(10)),
        appearance: Appearance.none,
        cursor: Cursor.pointer,
        backgroundColor: AppColors.white,
      )
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(fontWeight: FontWeight.w500)),
  css('.history-filters__chevron').styles(
    display: Display.flex,
    position: const Position.absolute(top: Unit.zero, right: Unit.pixels(14), bottom: Unit.zero),
    pointerEvents: PointerEvents.none,
    alignItems: AlignItems.center,
  ),
  css('.history-upgrade').styles(
    display: Display.flex,
    padding: const Padding.symmetric(horizontal: Unit.pixels(22), vertical: Unit.pixels(18)),
    radius: const BorderRadius.circular(Unit.pixels(14)),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(24)),
    backgroundColor: AppColors.surface,
  ),
  css('.history-upgrade__info').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(14)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.history-upgrade__texts').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(2)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.history-upgrade__title').combine(AppTextStyles.buttonMd),
  css('.history-upgrade__body')
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.muted, lineHeight: Unit.pixels(18))),
];
