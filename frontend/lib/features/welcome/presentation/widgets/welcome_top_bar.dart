import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/js_interop.dart';
import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_logo.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_link.dart';
import 'package:skill_battles/features/welcome/presentation/widgets/welcome_navigation.dart';

/// The sticky 72 px top bar of the landing page: logo and section links on
/// the left, "Log in" and "Create account" on the right. It gets a soft
/// shadow once the page (the `.app-viewport` scroll container) is scrolled
/// by more than 8 px.
final class WelcomeTopBar extends StatefulComponent {
  const WelcomeTopBar({super.key});

  @override
  State<WelcomeTopBar> createState() => _WelcomeTopBarState();
}

final class _WelcomeTopBarState extends State<WelcomeTopBar> {
  late bool _isScrolled;
  late JSFunction _onScroll;
  web.Element? _scroller;

  @override
  void initState() {
    super.initState();
    _isScrolled = false;
    _onScroll = _handleScroll.toJS;
    if (kIsWeb) context.binding.addPostFrameCallback(_listen);
  }

  void _listen() {
    if (!mounted) return;
    final web.Element? scroller = web.document.querySelector('.app-viewport');
    if (scroller == null) return;
    _scroller = scroller;
    scroller.addEventListener('scroll', _onScroll);
    _handleScroll();
  }

  void _handleScroll() {
    final bool isScrolled = (_scroller?.scrollTop ?? 0) > 8;
    if (mounted && isScrolled != _isScrolled) setState(() => _isScrolled = isScrolled);
  }

  @override
  void dispose() {
    _scroller?.removeEventListener('scroll', _onScroll);
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return header(classes: _isScrolled ? 'welcome-top-bar welcome-top-bar--scrolled' : 'welcome-top-bar', <Component>[
      div(classes: 'welcome-container welcome-top-bar__inner', <Component>[
        div(classes: 'welcome-top-bar__start', <Component>[
          AppTappable(
            onTap: () => scrollToWelcomeSection(WelcomeAnchors.top),
            radius: 8,
            semanticLabel: 'SkillBattles, back to top',
            // 48 px hit height around the 28 px mark.
            styles: const Styles(padding: Padding.symmetric(vertical: Unit.pixels(10))),
            child: const AppLogo(),
          ),
          nav(
            classes: 'welcome-top-bar__nav',
            attributes: const <String, String>{'aria-label': 'Sections'},
            const <Component>[
              _NavLink(label: 'How it works', target: WelcomeAnchors.howItWorks),
              _NavLink(label: 'Features', target: WelcomeAnchors.features),
              _NavLink(label: 'Leagues', target: WelcomeAnchors.leagues),
            ],
          ),
        ]),
        div(classes: 'welcome-top-bar__actions', <Component>[
          AppButton(
            label: 'Log in',
            variant: AppButtonVariant.outline,
            size: AppButtonSize.small,
            onPressed: context.goToLogIn,
          ),
          AppButton(
            label: 'Create account',
            variant: AppButtonVariant.dark,
            size: AppButtonSize.small,
            onPressed: context.goToSignUp,
          ),
        ]),
      ]),
    ]);
  }
}

final class _NavLink extends StatelessComponent {
  const _NavLink({required this.label, required this.target});

  final String label;
  final String target;

  static const Styles _style = Styles(
    // 48 px hit height around the 18 px line.
    padding: Padding.symmetric(vertical: Unit.pixels(15)),
    fontFamily: AppFonts.body,
    fontSize: Unit.pixels(14),
    fontWeight: FontWeight.w500,
    lineHeight: Unit.pixels(18),
  );

  @override
  Component build(BuildContext context) {
    return div(classes: 'welcome-nav-link', <Component>[
      AppTextLink(label: label, style: _style, onPressed: () => scrollToWelcomeSection(target)),
    ]);
  }
}

@css
List<StyleRule> get welcomeTopBarStyles => <StyleRule>[
  css('.welcome-top-bar').styles(
    position: const Position.sticky(top: Unit.zero),
    zIndex: const ZIndex(10),
    border: const Border.only(
      bottom: BorderSide(color: AppColors.border, width: Unit.pixels(1)),
    ),
    backgroundColor: AppColors.white,
    raw: const <String, String>{'transition': 'box-shadow 200ms ease', 'flex-shrink': '0'},
  ),
  css('.welcome-top-bar--scrolled').styles(
    raw: <String, String>{'box-shadow': '0 1px 2px ${AppColors.shadow.value}'},
  ),
  css('.welcome-top-bar__inner').styles(
    display: Display.flex,
    height: const Unit.pixels(72),
    justifyContent: JustifyContent.spaceBetween,
    alignItems: AlignItems.center,
  ),
  css('.welcome-top-bar__start').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(48)),
  ),
  css('.welcome-top-bar__nav').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(32)),
  ),
  css('.welcome-nav-link').styles(color: AppColors.muted),
  css('.welcome-nav-link:hover, .welcome-nav-link:focus-within').styles(color: AppColors.ink),
  css('.welcome-top-bar__actions').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(12)),
  ),
];
