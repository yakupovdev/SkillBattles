import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_notice.dart';
import 'package:skill_battles/features/battle/presentation/widgets/battle_round_view.dart';

/// Hides the round (question and options) while the battle tab or window is
/// not in front, and warns the player after they come back that leaving
/// during a round is not allowed.
///
/// On the web the app is `inactive` when the browser window loses focus and
/// `hidden` when the tab is switched away, so both blur the round: it is
/// harder to copy the question into another tab or to capture it with a
/// screenshot tool that takes focus. Nothing is reported to the server; the
/// warning and the count of leaves stay on this screen.
final class BattleFocusGuard extends StatefulWidget {
  const BattleFocusGuard({
    required this.enabled,
    required this.roundId,
    required this.child,
    super.key,
  });

  /// Off: [child] is shown as is and leaves are not counted.
  final bool enabled;

  /// A new round clears the warning of the previous one (the count stays).
  final String roundId;

  final Widget child;

  @override
  State<BattleFocusGuard> createState() => _BattleFocusGuardState();
}

final class _BattleFocusGuardState extends State<BattleFocusGuard> {
  late AppLifecycleListener _lifecycle;
  late bool _isAway;
  late bool _leftWhileGuarded;
  late int _leaveCount;
  late bool _showWarning;

  @override
  void initState() {
    super.initState();
    _isAway = !_isInFront(WidgetsBinding.instance.lifecycleState);
    _leftWhileGuarded = false;
    _leaveCount = 0;
    _showWarning = false;
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycleChanged);
  }

  @override
  void didUpdateWidget(BattleFocusGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roundId != widget.roundId) _showWarning = false;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// No state yet means nothing has reported the app as hidden.
  static bool _isInFront(AppLifecycleState? state) =>
      state == null || state == AppLifecycleState.resumed;

  void _onLifecycleChanged(AppLifecycleState state) {
    final bool away = !_isInFront(state);
    if (away == _isAway) return;
    setState(() {
      _isAway = away;
      if (away) {
        if (widget.enabled) _leftWhileGuarded = true;
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
    return _leaveCount > 1
        ? '$message ($_leaveCount times this match)'
        : message;
  }

  @override
  Widget build(BuildContext context) {
    final bool obscured = widget.enabled && _isAway;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.enabled && _showWarning)
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
            child: Center(
              child: BattleColumn(
                child: AppNotice(
                  message: _warning,
                  tone: AppNoticeTone.danger,
                  actionLabel: 'Got it',
                  onAction: _dismissWarning,
                ),
              ),
            ),
          ),
        Stack(
          children: <Widget>[
            ExcludeSemantics(
              excluding: obscured,
              child: ImageFiltered(
                enabled: obscured,
                imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: widget.child,
              ),
            ),
            if (obscured) const Positioned.fill(child: _AwayCover()),
          ],
        ),
      ],
    );
  }
}

/// Shown over the blurred round while the battle is in the background.
final class _AwayCover extends StatelessWidget {
  const _AwayCover();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.white.withValues(alpha: 0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: <Widget>[
            const Text('Battle hidden', style: AppTextStyles.titleMd),
            Text(
              'Come back to this tab — the round clock keeps running.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
