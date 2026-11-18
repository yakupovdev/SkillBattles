import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/js_interop.dart';
import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_notice.dart';
import 'package:skill_battles/features/battle/presentation/widgets/battle_round_view.dart';

/// Hides the round (question and options) while the battle tab or window is
/// not in front, and warns the player after they come back that leaving
/// during a round is not allowed.
///
/// The round is away when the tab is hidden (`visibilitychange`) or the
/// browser window loses focus (`blur` of the window; `focus` brings it
/// back), so both blur the round: it is harder to copy the question into
/// another tab or to capture it with a screenshot tool that takes focus.
/// While enabled it also refuses `copy`, `cut` and `dragstart` inside the
/// round (the text is not selectable either; the right-click menu is off on
/// the whole battle screen). Nothing is reported to the server; the warning
/// and the count of leaves stay on this screen.
final class BattleFocusGuard extends StatefulComponent {
  const BattleFocusGuard({required this.enabled, required this.roundId, required this.child, super.key});

  /// Off: [child] is shown as is and leaves are not counted.
  final bool enabled;

  /// A new round clears the warning of the previous one (the count stays).
  final String roundId;

  final Component child;

  @override
  State<BattleFocusGuard> createState() => _BattleFocusGuardState();
}

final class _BattleFocusGuardState extends State<BattleFocusGuard> {
  late bool _isAway;
  late bool _leftWhileGuarded;
  late int _leaveCount;
  late bool _showWarning;
  late bool _hasWindowFocus;
  web.EventListener? _visibilityListener;
  web.EventListener? _blurListener;
  web.EventListener? _focusListener;

  @override
  void initState() {
    super.initState();
    // Like Flutter's "no lifecycle state yet", only a hidden tab counts as
    // away at the start; a window without focus is noticed by its events.
    _hasWindowFocus = true;
    _isAway = kIsWeb && web.document.hidden;
    _leftWhileGuarded = false;
    _leaveCount = 0;
    _showWarning = false;
    if (kIsWeb) {
      final web.EventListener visibility = _onVisibilityChanged.toJS;
      final web.EventListener blur = _onWindowBlur.toJS;
      final web.EventListener focus = _onWindowFocus.toJS;
      _visibilityListener = visibility;
      _blurListener = blur;
      _focusListener = focus;
      web.document.addEventListener('visibilitychange', visibility);
      web.window.addEventListener('blur', blur);
      web.window.addEventListener('focus', focus);
    }
  }

  @override
  void didUpdateComponent(BattleFocusGuard oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.roundId != component.roundId) _showWarning = false;
  }

  @override
  void dispose() {
    final web.EventListener? visibility = _visibilityListener;
    final web.EventListener? blur = _blurListener;
    final web.EventListener? focus = _focusListener;
    if (visibility != null) web.document.removeEventListener('visibilitychange', visibility);
    if (blur != null) web.window.removeEventListener('blur', blur);
    if (focus != null) web.window.removeEventListener('focus', focus);
    super.dispose();
  }

  void _onVisibilityChanged(web.Event _) => _update();

  void _onWindowBlur(web.Event event) {
    // Focus moving between elements of the page also fires `blur` on them,
    // but only the window's own event means the window lost focus.
    if (event.target != web.window) return;
    _hasWindowFocus = false;
    _update();
  }

  void _onWindowFocus(web.Event event) {
    if (event.target != web.window) return;
    _hasWindowFocus = true;
    _update();
  }

  void _update() {
    final bool away = web.document.hidden || !_hasWindowFocus;
    if (away == _isAway || !mounted) return;
    setState(() {
      _isAway = away;
      if (away) {
        if (component.enabled) _leftWhileGuarded = true;
      } else if (_leftWhileGuarded) {
        _leftWhileGuarded = false;
        _leaveCount++;
        _showWarning = true;
      }
    });
  }

  void _dismissWarning() => setState(() => _showWarning = false);

  String get _warning {
    const String message =
        'You left the battle tab. Switching tabs or windows during a round '
        'is not allowed.';
    return _leaveCount > 1 ? '$message ($_leaveCount times this match)' : message;
  }

  static void _refuse(web.Event event) => event.preventDefault();

  @override
  Component build(BuildContext context) {
    final bool obscured = component.enabled && _isAway;
    return div(classes: 'battle-focus-guard', <Component>[
      if (component.enabled && _showWarning)
        div(classes: 'battle-focus-guard__warning', <Component>[
          BattleColumn(
            child: AppNotice(
              message: _warning,
              tone: AppNoticeTone.danger,
              actionLabel: 'Got it',
              onAction: _dismissWarning,
            ),
          ),
        ]),
      div(classes: 'battle-focus-guard__stack', <Component>[
        div(
          classes: obscured
              ? 'battle-focus-guard__round battle-focus-guard__round--obscured'
              : 'battle-focus-guard__round',
          attributes: obscured ? const <String, String>{'aria-hidden': 'true', 'inert': ''} : null,
          events: component.enabled
              ? const <String, void Function(web.Event)>{'copy': _refuse, 'cut': _refuse, 'dragstart': _refuse}
              : null,
          <Component>[component.child],
        ),
        if (obscured) const _AwayCover(),
      ]),
    ]);
  }
}

/// Shown over the blurred round while the battle is in the background.
final class _AwayCover extends StatelessComponent {
  const _AwayCover();

  @override
  Component build(BuildContext context) {
    return const div(classes: 'battle-focus-guard__cover', <Component>[
      div(classes: 'battle-focus-guard__cover-content', <Component>[
        p(classes: 'battle-focus-guard__cover-title', <Component>[Component.text('Battle hidden')]),
        p(classes: 'battle-focus-guard__cover-text', <Component>[
          Component.text('Come back to this tab — the round clock keeps running.'),
        ]),
      ]),
    ]);
  }
}

@css
List<StyleRule> get battleFocusGuardStyles => <StyleRule>[
  css('.battle-focus-guard').styles(display: Display.flex, flexDirection: FlexDirection.column),
  css('.battle-focus-guard__warning').styles(
    display: Display.flex,
    padding: const Padding.only(top: Unit.pixels(16)),
    justifyContent: JustifyContent.center,
  ),
  css('.battle-focus-guard__stack').styles(position: const Position.relative()),
  css('.battle-focus-guard__round').styles(display: Display.flex, justifyContent: JustifyContent.center),
  css('.battle-focus-guard__round--obscured').styles(
    filter: const Filter.blur(Unit.pixels(16)),
    pointerEvents: PointerEvents.none,
  ),
  css('.battle-focus-guard__cover').styles(
    display: Display.flex,
    position: const Position.absolute(top: Unit.zero, left: Unit.zero, right: Unit.zero, bottom: Unit.zero),
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
    raw: const <String, String>{'background-color': 'rgba(255, 255, 255, 0.7)'},
  ),
  css('.battle-focus-guard__cover-content').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.center,
    gap: const Gap.row(Unit.pixels(8)),
  ),
  css('.battle-focus-guard__cover-title').combine(AppTextStyles.titleMd),
  css('.battle-focus-guard__cover-text')
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(color: AppColors.muted, textAlign: TextAlign.center)),
];
