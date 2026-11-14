import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/dev/dev_scenario.dart';
import 'package:skill_battles/dev/mock_backend.dart';

/// DEVELOPMENT ONLY. A floating "DEV" panel over the app in mock mode to
/// switch Free/Pro, the daily limit, the opponent's behaviour (correct,
/// wrong, time-outs, overtime, draw, forfeit), payment outcome and
/// subscription expiry. Dev tooling reads the mock backend directly; it is
/// never built without `DEV_MOCKS=true`.
final class DevPanelOverlay extends StatefulWidget {
  const DevPanelOverlay({required this.child, super.key});

  final Widget child;

  @override
  State<DevPanelOverlay> createState() => _DevPanelOverlayState();
}

final class _DevPanelOverlayState extends State<DevPanelOverlay> {
  late bool _open;

  @override
  void initState() {
    super.initState();
    _open = false;
  }

  @override
  Widget build(BuildContext context) {
    final MockBackend backend = AppDependenciesProvider.of(context)
        .getDep<MockBackend>();
    final GoRouter router = AppDependenciesProvider.of(context)
        .getDep<GoRouter>();
    return Stack(
      children: <Widget>[
        widget.child,
        Positioned(
          right: 16,
          bottom: 16,
          child: Material(
            color: Colors.transparent,
            child: _open
                ? _Panel(
                    backend: backend,
                    router: router,
                    onClose: () => setState(() => _open = false),
                  )
                : FloatingActionButton.small(
                    heroTag: 'dev-panel',
                    backgroundColor: AppColors.danger,
                    onPressed: () => setState(() => _open = true),
                    child: const Text(
                      'DEV',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

final class _Panel extends StatelessWidget {
  const _Panel({
    required this.backend,
    required this.router,
    required this.onClose,
  });

  final MockBackend backend;

  /// The panel sits above the router's context, so it gets the router.
  final GoRouter router;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final DevScenario scenario = backend.scenario;
    return ListenableBuilder(
      listenable: scenario,
      builder: (BuildContext context, Widget? _) => Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.danger, width: 1.5),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Development mocks',
                    style: AppTextStyles.buttonMd.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
            Text(
              'Fake data — not a substitute for testing with the backend.',
              style: AppTextStyles.bodyXs.copyWith(color: AppColors.muted),
            ),
            _Toggle(
              label: 'Pro (simulated webhook)',
              value: backend.isPro,
              onChanged: (bool value) {
                backend.setPro(value);
                scenario.touch();
              },
            ),
            _Toggle(
              label: 'Free daily limit used up',
              value: backend.dailyLimitReached,
              onChanged: (bool value) {
                backend.setDailyLimitReached(value);
                scenario.touch();
              },
            ),
            _Toggle(
              label: 'Cancel next ranked (QUOTA_EXHAUSTED)',
              value: scenario.cancelNextRankedForQuota,
              onChanged: (bool value) =>
                  scenario.cancelNextRankedForQuota = value,
            ),
            Text('Opponent', style: AppTextStyles.bodyXs),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final DevOpponent o in DevOpponent.values)
                  ChoiceChip(
                    label: Text(o.label, style: AppTextStyles.bodyXs),
                    selected: scenario.opponent == o,
                    onSelected: (_) => scenario.opponent = o,
                  ),
              ],
            ),
            Text('Test checkout', style: AppTextStyles.bodyXs),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final DevPayment p in DevPayment.values)
                  ChoiceChip(
                    label: Text(p.label, style: AppTextStyles.bodyXs),
                    selected: scenario.payment == p,
                    onSelected: (_) => scenario.payment = p,
                  ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton(
                  onPressed: backend.expireSubscription,
                  child: const Text('Expire subscription'),
                ),
                OutlinedButton(
                  onPressed: backend.lastResetLink == null
                      ? null
                      : () => router.go(backend.lastResetLink!),
                  child: const Text('Open reset link'),
                ),
              ],
            ),
            Text(
              'Log in with any email; password "wrongpass" fails. Nickname '
              '"taken" is taken. Join codes EXPIRE / NOROOM fail.',
              style: AppTextStyles.bodyXs.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

final class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: AppTextStyles.bodySm)),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
