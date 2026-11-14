import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/pro_badge.dart';
import 'package:skill_battles/core/utils/extensions/go_router_extension.dart';
import 'package:skill_battles/features/account/presentation/bloc/account_bloc/account_bloc.dart';
import 'package:skill_battles/features/subscription/domain/usecases/get_subscription_usecase.dart';
import 'package:skill_battles/features/subscription/presentation/bloc/billing_return_bloc/billing_return_bloc.dart';

/// Where Stripe returns. Shows the server-verified status; the query string
/// (`success=true`) is never taken as proof of payment.
final class BillingReturnScreen extends StatelessWidget
    implements GoRouterWrapper {
  const BillingReturnScreen({required this.checkoutCancelled, super.key});

  final bool checkoutCancelled;

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<BillingReturnBloc>(
      create: (_) => BillingReturnBloc(
        getSubscription: dependencies.getDep<GetSubscriptionUsecase>(),
      )..add(BillingReturnStarted(checkoutCancelled: checkoutCancelled)),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BillingReturnBloc, BillingReturnState>(
      listenWhen: (BillingReturnState previous, BillingReturnState current) =>
          previous.status != current.status,
      listener: (BuildContext context, BillingReturnState state) =>
          context.read<AccountBloc>().add(const AccountRefreshRequested()),
      child: AppDesktopViewport(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: BlocBuilder<BillingReturnBloc, BillingReturnState>(
                builder: (BuildContext context, BillingReturnState state) {
                  final (String title, String body) = switch (state.status) {
                    BillingReturnStatus.checking => (
                      'Checking your payment…',
                      'We are waiting for Stripe to confirm the test payment. '
                          'This usually takes a few seconds.',
                    ),
                    BillingReturnStatus.active => (
                      'Pro is active',
                      'Thanks! Your full history, correct answers and '
                          'analytics are unlocked.',
                    ),
                    BillingReturnStatus.pending => (
                      'Payment is still being verified',
                      "We haven't received a confirmed payment yet. If you "
                          'completed checkout, Pro turns on automatically as '
                          'soon as it is confirmed — no need to pay again.',
                    ),
                    BillingReturnStatus.cancelled => (
                      'Checkout was cancelled',
                      'Nothing was charged. You can try again anytime.',
                    ),
                  };
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 16,
                    children: <Widget>[
                      if (state.status == BillingReturnStatus.active)
                        const ProBadge(),
                      if (state.status == BillingReturnStatus.checking)
                        const CircularProgressIndicator(),
                      Text(
                        title,
                        style: AppTextStyles.displaySm,
                        textAlign: TextAlign.center,
                      ),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          body,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyLg.copyWith(
                            color: AppColors.muted,
                            height: 22 / 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: <Widget>[
                          AppButton(
                            label: 'Back to home',
                            size: AppButtonSize.medium,
                            onPressed: context.goHome,
                          ),
                          AppButton(
                            label: 'Subscription details',
                            variant: AppButtonVariant.outline,
                            size: AppButtonSize.medium,
                            onPressed: context.goPro,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
