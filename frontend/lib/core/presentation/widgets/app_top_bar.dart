import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_shadows.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_avatar.dart';
import 'package:skill_battles/core/presentation/widgets/app_logo.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';

/// A section of the main navigation.
enum AppNavTab {
  play('Play'),
  leaderboard('Leaderboard'),
  stats('Stats'),
  history('History'),
  friends('Friends');

  const AppNavTab(this.label);

  final String label;
}

/// Entries of the account menu.
enum AppAccountAction { editProfile, subscription, logOut }

/// The 72 px top bar: logo and navigation on the left, the plan and the
/// player on the right, a 1 px line below.
final class AppTopBar extends StatelessComponent {
  const AppTopBar({
    required this.activeTab,
    required this.nickname,
    required this.isPro,
    required this.onTabSelected,
    required this.onLogoPressed,
    required this.onProPressed,
    required this.onAccountAction,
    this.environmentLabel,
    super.key,
  });

  /// Highlighted tab, `null` when the current page belongs to none.
  final AppNavTab? activeTab;

  /// `null` while the profile loads.
  final String? nickname;
  final bool isPro;
  final ValueChanged<AppNavTab> onTabSelected;
  final VoidCallback onLogoPressed;
  final VoidCallback onProPressed;
  final ValueChanged<AppAccountAction> onAccountAction;

  /// A visible marker for non-production data sources ("DEV MOCKS").
  final String? environmentLabel;

  static const double height = 72;

  @override
  Component build(BuildContext context) {
    final String? label = environmentLabel;
    final String? name = nickname;
    return header(classes: 'app-top-bar', <Component>[
      div(classes: 'app-top-bar__inner', <Component>[
        AppTappable(
          onTap: onLogoPressed,
          radius: 8,
          semanticLabel: 'SkillBattles, home',
          classes: 'app-top-bar__logo',
          child: const AppLogo(),
        ),
        nav(
          classes: 'app-top-bar__nav',
          attributes: const <String, String>{'aria-label': 'Main'},
          <Component>[
            for (final AppNavTab tab in AppNavTab.values)
              _NavItem(tab: tab, isActive: tab == activeTab, onSelected: onTabSelected),
            if (label != null) _EnvironmentChip(label: label),
          ],
        ),
        div(classes: 'app-top-bar__end', <Component>[
          _ProPill(isPro: isPro, onPressed: onProPressed),
          if (name != null) _AccountMenu(nickname: name, onSelected: onAccountAction),
        ]),
      ]),
    ]);
  }
}

final class _NavItem extends StatelessComponent {
  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.onSelected,
  });

  final AppNavTab tab;
  final bool isActive;
  final ValueChanged<AppNavTab> onSelected;

  @override
  Component build(BuildContext context) {
    return AppTappable(
      onTap: () => onSelected(tab),
      isSelected: isActive,
      radius: 4,
      classes: isActive ? 'app-top-bar__tab app-top-bar__tab--active' : 'app-top-bar__tab',
      child: span(<Component>[Component.text(tab.label)]),
    );
  }
}

/// The amber pill: outlined "Go Pro" for Free, filled "Pro" for Pro.
final class _ProPill extends StatelessComponent {
  const _ProPill({required this.isPro, required this.onPressed});

  final bool isPro;
  final VoidCallback onPressed;

  @override
  Component build(BuildContext context) {
    return AppTappable(
      onTap: onPressed,
      radius: 999,
      semanticLabel: isPro ? 'Your Pro subscription' : 'Go Pro',
      classes: isPro ? 'app-top-bar__pro app-top-bar__pro--active' : 'app-top-bar__pro',
      child: span(classes: 'app-top-bar__pro-content', <Component>[
        AppSvgIcon(AppIcons.star, width: 12, height: 12, color: isPro ? AppColors.ink : null),
        span(<Component>[Component.text(isPro ? 'Pro' : 'Go Pro')]),
      ]),
    );
  }
}

final class _EnvironmentChip extends StatelessComponent {
  const _EnvironmentChip({required this.label});

  final String label;

  @override
  Component build(BuildContext context) {
    return span(classes: 'app-top-bar__env', <Component>[Component.text(label)]);
  }
}

/// The nickname and avatar; a click opens the account menu under it.
/// The menu closes on a pick, Esc (the focus returns to the trigger), Tab
/// or a click outside (a transparent backdrop under the menu takes it).
/// Arrow keys move between the entries.
final class _AccountMenu extends StatefulComponent {
  const _AccountMenu({required this.nickname, required this.onSelected});

  final String nickname;
  final ValueChanged<AppAccountAction> onSelected;

  @override
  State<_AccountMenu> createState() => _AccountMenuState();
}

final class _AccountMenuState extends State<_AccountMenu> {
  late bool _isOpen;
  late GlobalNodeKey<web.HTMLElement> _popupKey;
  late GlobalNodeKey<web.HTMLElement> _triggerKey;

  @override
  void initState() {
    super.initState();
    _isOpen = false;
    _popupKey = GlobalNodeKey<web.HTMLElement>();
    _triggerKey = GlobalNodeKey<web.HTMLElement>();
  }

  void _open() {
    if (_isOpen) return;
    setState(() => _isOpen = true);
    // The menu takes the focus, so its keydown handler sees Esc and arrows.
    context.binding.addPostFrameCallback(() {
      final List<web.HTMLElement> items = _items();
      if (items.isNotEmpty) items.first.focus();
    });
  }

  void _close({bool restoreFocus = false}) {
    if (!_isOpen) return;
    if (mounted) setState(() => _isOpen = false);
    if (restoreFocus) _triggerKey.currentNode?.focus();
  }

  void _onMenuKeyDown(web.Event event) {
    final String key = (event as web.KeyboardEvent).key;
    if (key == 'Escape') {
      event.preventDefault();
      _close(restoreFocus: true);
      return;
    }
    if (key == 'Tab') {
      _close();
      return;
    }
    if (key != 'ArrowDown' && key != 'ArrowUp') return;
    event.preventDefault();
    final List<web.HTMLElement> items = _items();
    if (items.isEmpty) return;
    final web.Element? active = web.document.activeElement;
    final int current = items.indexWhere((web.HTMLElement item) => item == active);
    final int step = key == 'ArrowDown' ? 1 : -1;
    items[(current + step) % items.length].focus();
  }

  List<web.HTMLElement> _items() {
    final web.NodeList? nodes = _popupKey.currentNode?.querySelectorAll('[role="menuitem"]');
    if (nodes == null) return const <web.HTMLElement>[];
    return <web.HTMLElement>[
      for (int i = 0; i < nodes.length; i++) nodes.item(i)! as web.HTMLElement,
    ];
  }

  void _pick(AppAccountAction action) {
    _close();
    component.onSelected(action);
  }

  @override
  Component build(BuildContext context) {
    return div(classes: 'app-account-menu', <Component>[
      button(
        key: _triggerKey,
        type: ButtonType.button,
        classes: 'app-account-menu__trigger',
        attributes: <String, String>{
          'title': 'Account',
          'aria-haspopup': 'menu',
          'aria-expanded': '$_isOpen',
        },
        onClick: () => _isOpen ? _close() : _open(),
        <Component>[
          span(classes: 'app-account-menu__name', <Component>[Component.text(component.nickname)]),
          AppAvatar(nickname: component.nickname),
        ],
      ),
      if (_isOpen)
        div(
          classes: 'app-account-menu__backdrop',
          attributes: const <String, String>{'aria-hidden': 'true'},
          events: <String, void Function(web.Event)>{'mousedown': (web.Event _) => _close()},
          const <Component>[],
        ),
      if (_isOpen)
        div(
          key: _popupKey,
          classes: 'app-account-menu__popup',
          attributes: const <String, String>{'role': 'menu', 'aria-label': 'Account'},
          events: <String, void Function(web.Event)>{'keydown': _onMenuKeyDown},
          <Component>[
            _MenuItem(label: 'Account settings', onPressed: () => _pick(AppAccountAction.editProfile)),
            _MenuItem(label: 'Subscription', onPressed: () => _pick(AppAccountAction.subscription)),
            const div(
              classes: 'app-account-menu__divider',
              attributes: <String, String>{'role': 'separator'},
              <Component>[],
            ),
            _MenuItem(label: 'Log out', isDanger: true, onPressed: () => _pick(AppAccountAction.logOut)),
          ],
        ),
    ]);
  }
}

final class _MenuItem extends StatelessComponent {
  const _MenuItem({required this.label, required this.onPressed, this.isDanger = false});

  final String label;
  final VoidCallback onPressed;
  final bool isDanger;

  @override
  Component build(BuildContext context) {
    return button(
      type: ButtonType.button,
      classes: isDanger ? 'app-account-menu__item app-account-menu__item--danger' : 'app-account-menu__item',
      attributes: const <String, String>{'role': 'menuitem', 'tabindex': '-1'},
      onClick: onPressed,
      <Component>[
        if (isDanger) const AppSvgIcon(AppIcons.logOut, width: 16, height: 16, color: AppColors.danger),
        span(<Component>[Component.text(label)]),
      ],
    );
  }
}

@css
List<StyleRule> get appTopBarStyles => <StyleRule>[
  css('.app-top-bar').styles(
    display: Display.flex,
    height: const Unit.pixels(AppTopBar.height),
    border: const Border.only(
      bottom: BorderSide(color: AppColors.border, width: Unit.pixels(1)),
    ),
    justifyContent: JustifyContent.center,
    flex: const Flex(shrink: 0),
    backgroundColor: AppColors.white,
  ),
  css('.app-top-bar__inner').styles(
    display: Display.flex,
    width: const Unit.percent(100),
    maxWidth: const Unit.pixels(1440),
    padding: const Padding.symmetric(horizontal: Unit.pixels(64)),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(48)),
  ),
  css('.app-top-bar__logo').styles(flex: const Flex(shrink: 0)),
  css('.app-top-bar__nav').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(32)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.app-top-bar__tab')
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(color: AppColors.muted, fontWeight: FontWeight.w500, whiteSpace: WhiteSpace.noWrap)),
  css('.app-top-bar__tab:hover').styles(color: AppColors.ink),
  css('.app-top-bar__tab--active').styles(color: AppColors.ink, fontWeight: FontWeight.w600),
  css('.app-top-bar__env')
      .styles(
        padding: const Padding.symmetric(horizontal: Unit.pixels(8), vertical: Unit.pixels(3)),
        radius: const BorderRadius.circular(Unit.pixels(6)),
        backgroundColor: AppColors.dangerSurface,
      )
      .combine(AppTextStyles.outcome)
      .combine(const Styles(color: AppColors.danger, whiteSpace: WhiteSpace.noWrap)),
  css('.app-top-bar__end').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(20)),
    flex: const Flex(shrink: 0),
  ),
  css('.app-top-bar__pro').styles(
    display: Display.flex,
    height: const Unit.pixels(34),
    padding: const Padding.symmetric(horizontal: Unit.pixels(14)),
    border: Border.all(color: AppColors.accent, width: const Unit.pixels(1.5)),
    alignItems: AlignItems.center,
  ),
  css('.app-top-bar__pro--active').styles(backgroundColor: AppColors.accent),
  css('.app-top-bar__pro-content')
      .styles(display: Display.flex, alignItems: AlignItems.center, gap: const Gap.column(Unit.pixels(6)))
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.accentDeep, fontWeight: FontWeight.w600, whiteSpace: WhiteSpace.noWrap)),
  css('.app-top-bar__pro--active .app-top-bar__pro-content').styles(color: AppColors.ink),
  css('.app-account-menu').styles(position: const Position.relative()),
  css('.app-account-menu__trigger').styles(
    display: Display.flex,
    radius: const BorderRadius.circular(Unit.pixels(8)),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(12)),
  ),
  css('.app-account-menu__name')
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(fontWeight: FontWeight.w500, whiteSpace: WhiteSpace.noWrap)),
  css('.app-account-menu__backdrop').styles(
    position: const Position.fixed(top: Unit.zero, left: Unit.zero, right: Unit.zero, bottom: Unit.zero),
    zIndex: const ZIndex(899),
  ),
  css('.app-account-menu__popup').styles(
    display: Display.flex,
    position: const Position.absolute(top: Unit.expression('calc(100% + 8px)'), right: Unit.zero),
    zIndex: const ZIndex(900),
    minWidth: const Unit.pixels(200),
    padding: const Padding.symmetric(vertical: Unit.pixels(6)),
    border: Border.all(color: AppColors.border, width: const Unit.pixels(1)),
    radius: const BorderRadius.circular(Unit.pixels(12)),
    shadow: AppShadows.overlay,
    flexDirection: FlexDirection.column,
    backgroundColor: AppColors.white,
  ),
  css('.app-account-menu__item')
      .styles(
        display: Display.flex,
        height: const Unit.pixels(44),
        padding: const Padding.symmetric(horizontal: Unit.pixels(16)),
        alignItems: AlignItems.center,
        gap: const Gap.column(Unit.pixels(10)),
        whiteSpace: WhiteSpace.noWrap,
      )
      .combine(AppTextStyles.bodyMd),
  css('.app-account-menu__item:hover, .app-account-menu__item:focus-visible').styles(
    backgroundColor: AppColors.surface,
    raw: const <String, String>{'outline': 'none'},
  ),
  css('.app-account-menu__item--danger').styles(color: AppColors.danger),
  css('.app-account-menu__divider').styles(
    height: const Unit.pixels(1),
    margin: const Margin.symmetric(vertical: Unit.pixels(6)),
    backgroundColor: AppColors.divider,
  ),
];
