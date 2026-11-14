import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_avatar.dart';
import 'package:skill_battles/core/presentation/widgets/app_logo.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';

/// A section of the main navigation.
enum AppNavTab {
  play('Play'),
  leaderboard('Leaderboard'),
  profile('Profile');

  const AppNavTab(this.label);

  final String label;
}

/// Entries of the account menu.
enum AppAccountAction { editProfile, subscription, logOut }

/// The 72 px top bar: logo and navigation on the left, the plan and the
/// player on the right, a 1 px line below.
final class AppTopBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final String? label = environmentLabel;
    final String? name = nickname;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        height: height - 1,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 64),
              child: Row(
                spacing: 48,
                children: <Widget>[
                  AppTappable(
                    onTap: onLogoPressed,
                    borderRadius: BorderRadius.circular(8),
                    semanticLabel: 'SkillBattles, home',
                    child: const AppLogo(),
                  ),
                  Expanded(
                    child: Row(
                      spacing: 32,
                      children: <Widget>[
                        for (final AppNavTab tab in AppNavTab.values)
                          _NavItem(
                            tab: tab,
                            isActive: tab == activeTab,
                            onSelected: onTabSelected,
                          ),
                        if (label != null) _EnvironmentChip(label: label),
                      ],
                    ),
                  ),
                  Row(
                    spacing: 20,
                    children: <Widget>[
                      _ProPill(isPro: isPro, onPressed: onProPressed),
                      if (name != null)
                        _AccountMenu(
                          nickname: name,
                          onSelected: onAccountAction,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.onSelected,
  });

  final AppNavTab tab;
  final bool isActive;
  final ValueChanged<AppNavTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return AppTappable(
      onTap: () => onSelected(tab),
      isSelected: isActive,
      borderRadius: BorderRadius.circular(4),
      child: Text(
        tab.label,
        style: AppTextStyles.bodyMd.copyWith(
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          color: isActive ? AppColors.ink : AppColors.muted,
        ),
      ),
    );
  }
}

/// The amber pill: outlined "Go Pro" for Free, filled "Pro" for Pro.
final class _ProPill extends StatelessWidget {
  const _ProPill({required this.isPro, required this.onPressed});

  final bool isPro;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(999);
    return AppTappable(
      onTap: onPressed,
      borderRadius: radius,
      semanticLabel: isPro ? 'Your Pro subscription' : 'Go Pro',
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isPro ? AppColors.accent : null,
          borderRadius: radius,
          border: Border.all(color: AppColors.accent, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: <Widget>[
            AppSvgIcon(
              AppIcons.star,
              width: 12,
              height: 12,
              color: isPro ? AppColors.ink : null,
            ),
            Text(
              isPro ? 'Pro' : 'Go Pro',
              style: AppTextStyles.bodySm.copyWith(
                fontWeight: FontWeight.w600,
                color: isPro ? AppColors.ink : AppColors.accentDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _EnvironmentChip extends StatelessWidget {
  const _EnvironmentChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.dangerSurface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: AppTextStyles.outcome.copyWith(color: AppColors.danger),
        ),
      ),
    );
  }
}

final class _AccountMenu extends StatelessWidget {
  const _AccountMenu({required this.nickname, required this.onSelected});

  final String nickname;
  final ValueChanged<AppAccountAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AppAccountAction>(
      tooltip: 'Account',
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      itemBuilder: (BuildContext context) =>
          const <PopupMenuEntry<AppAccountAction>>[
            PopupMenuItem<AppAccountAction>(
              value: AppAccountAction.editProfile,
              child: Text('Account settings'),
            ),
            PopupMenuItem<AppAccountAction>(
              value: AppAccountAction.subscription,
              child: Text('Subscription'),
            ),
            PopupMenuDivider(),
            PopupMenuItem<AppAccountAction>(
              value: AppAccountAction.logOut,
              child: Text('Log out'),
            ),
          ],
      child: Row(
        spacing: 12,
        children: <Widget>[
          Text(
            nickname,
            style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w500),
          ),
          AppAvatar(nickname: nickname),
        ],
      ),
    );
  }
}
