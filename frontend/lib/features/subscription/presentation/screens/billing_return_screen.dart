import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/plan_code.dart';
import 'package:skill_battles/core/domain/entity/subscription_entity.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_test_mode_badge.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_link.dart';
import 'package:skill_battles/core/utils/extensions/go_router_extension.dart';
import 'package:skill_battles/features/account/presentation/bloc/account_bloc/account_bloc.dart';
import 'package:skill_battles/features/subscription/domain/usecases/get_subscription_usecase.dart';
import 'package:skill_battles/features/subscription/presentation/bloc/billing_return_bloc/billing_return_bloc.dart';
import 'package:skill_battles/features/subscription/presentation/widgets/subscription_labels.dart';

/// Where Stripe returns (Paper: "25 Checkout return — verifying"). Shows the
/// server-verified status; the query string (`success=true`) is never taken
/// as proof of payment.
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: BlocBuilder<BillingReturnBloc, BillingReturnState>(
                builder: (BuildContext context, BillingReturnState state) {
                  final _ReturnCallout? callout = _ReturnCallout.forState(
                    state,
                  );
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 56,
                    children: <Widget>[
                      _Hero(state: state),
                      ?callout,
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

final class _Hero extends StatelessWidget {
  const _Hero({required this.state});

  final BillingReturnState state;

  @override
  Widget build(BuildContext context) {
    final PlanCode? code = state.subscription?.planCode;
    // While Stripe has not confirmed, the account may still report Free.
    final String plan = code == null || code == PlanCode.free
        ? 'Pro'
        : code.label;
    final String? nickname = context.select(
      (AccountBloc bloc) => bloc.state.account?.user.nickname,
    );
    final TextStyle bodyStyle = AppTextStyles.bodyXl.copyWith(
      fontSize: 16,
      height: 24 / 16,
      color: AppColors.muted,
    );
    final bool waiting =
        state.status == BillingReturnStatus.checking ||
        state.status == BillingReturnStatus.pending;
    final String title = switch (state.status) {
      BillingReturnStatus.checking ||
      BillingReturnStatus.pending => 'Confirming your payment…',
      BillingReturnStatus.active => 'Payment confirmed',
      BillingReturnStatus.cancelled => 'Checkout was cancelled',
    };
    final InlineSpan body = switch (state.status) {
      BillingReturnStatus.checking || BillingReturnStatus.pending => TextSpan(
        children: <InlineSpan>[
          TextSpan(text: "We're waiting for Stripe to confirm $plan"),
          if (nickname != null) ...<InlineSpan>[
            const TextSpan(text: ' for '),
            TextSpan(
              text: nickname,
              style: bodyStyle.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const TextSpan(
            text:
                '. This usually takes a few seconds — you can keep this page '
                'open or go play.',
          ),
        ],
      ),
      BillingReturnStatus.active => TextSpan(
        text:
            '$plan is active. Your full history, correct answers and '
            'analytics are unlocked.',
      ),
      BillingReturnStatus.cancelled => const TextSpan(
        text: 'Nothing was charged. You can choose a plan again anytime.',
      ),
    };
    return Column(
      spacing: 20,
      children: <Widget>[
        switch (state.status) {
          BillingReturnStatus.checking ||
          BillingReturnStatus.pending => const SizedBox.square(
            dimension: 64,
            child: Padding(
              padding: EdgeInsets.all(2.5),
              child: CircularProgressIndicator(
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
                color: AppColors.primary,
                backgroundColor: AppColors.divider,
              ),
            ),
          ),
          BillingReturnStatus.active => const AppSvgIcon(
            AppIcons.statusSuccess,
            width: 64,
            height: 64,
          ),
          BillingReturnStatus.cancelled => const AppSvgIcon(
            AppIcons.statusError,
            width: 64,
            height: 64,
          ),
        },
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineLg,
        ),
        Semantics(
          liveRegion: true,
          child: Text.rich(body, textAlign: TextAlign.center, style: bodyStyle),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: <Widget>[
            if (waiting)
              AppButton(
                label: 'Check again',
                variant: AppButtonVariant.outline,
                size: AppButtonSize.small,
                onPressed: () => context.read<BillingReturnBloc>().add(
                  const BillingReturnStarted(checkoutCancelled: false),
                ),
              )
            else if (state.status == BillingReturnStatus.active)
              AppButton(
                label: 'Go play',
                variant: AppButtonVariant.dark,
                size: AppButtonSize.small,
                onPressed: context.goHome,
              )
            else
              AppButton(
                label: 'See plans',
                variant: AppButtonVariant.outline,
                size: AppButtonSize.small,
                onPressed: context.goPro,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AppTextLink(
                label: state.status == BillingReturnStatus.active
                    ? 'Subscription details'
                    : 'Back to home',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w500,
                ),
                onPressed: state.status == BillingReturnStatus.active
                    ? context.goPro
                    : context.goHome,
              ),
            ),
          ],
        ),
        if (state.subscription?.isTestMode ?? true)
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: <Widget>[
              const AppTestModeBadge(),
              Text(
                'No real money was charged.',
                style: AppTextStyles.bodyXs.copyWith(color: AppColors.muted),
              ),
            ],
          ),
      ],
    );
  }
}

/// Outcome box under the hero: Pro is on, the payment did not go through,
/// or Stripe is slow.
final class _ReturnCallout extends StatelessWidget {
  const _ReturnCallout({
    required this.icon,
    required this.background,
    required this.titleColor,
    required this.bodyColor,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  static _ReturnCallout? forState(BillingReturnState state) {
    final SubscriptionEntity? subscription = state.subscription;
    final DateTime? end = subscription?.currentPeriodEnd;
    return switch (state.status) {
      BillingReturnStatus.checking => null,
      BillingReturnStatus.active => _ReturnCallout(
        icon: AppIcons.statusSuccess,
        background: AppColors.successCallout,
        titleColor: AppColors.successTitle,
        bodyColor: AppColors.successBody,
        title: end == null
            ? "You're Pro"
            : "You're Pro until ${DisplayFormatters.date(end)}",
        message:
            'Old reviews, answers and analytics are unlocked now. Ratings '
            'stay exactly the same.',
      ),
      BillingReturnStatus.cancelled => const _ReturnCallout(
        icon: AppIcons.statusError,
        background: AppColors.dangerSurface,
        titleColor: AppColors.dangerTitle,
        bodyColor: AppColors.dangerBody,
        title: "Payment wasn't completed",
        message:
            "You're still on Free. If the payment failed, you can try again "
            'or update the card.',
        actionLabel: 'Try again',
        onAction: _tryAgain,
      ),
      BillingReturnStatus.pending => const _ReturnCallout(
        icon: AppIcons.clock,
        background: AppColors.surface,
        titleColor: AppColors.ink,
        bodyColor: AppColors.muted,
        title: 'Taking longer than usual',
        message:
            "We'll update your account automatically when Stripe confirms. "
            'No need to pay again.',
      ),
    };
  }

  static void _tryAgain(BuildContext context) => context.goPro();

  final String icon;
  final Color background;
  final Color titleColor;
  final Color bodyColor;
  final String title;
  final String message;
  final String? actionLabel;
  final void Function(BuildContext context)? onAction;

  @override
  Widget build(BuildContext context) {
    final TextStyle bodyStyle = AppTextStyles.bodySm.copyWith(
      height: 19 / 13,
      color: bodyColor,
    );
    final String? label = actionLabel;
    final void Function(BuildContext context)? action = onAction;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14,
            children: <Widget>[
              AppSvgIcon(icon, width: 22, height: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: <Widget>[
                    Text(
                      title,
                      style: AppTextStyles.buttonMd.copyWith(color: titleColor),
                    ),
                    Text(message, style: bodyStyle),
                    if (label != null)
                      AppTextLink(
                        label: label,
                        style: bodyStyle.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        onPressed: action == null
                            ? null
                            : () => action(context),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
