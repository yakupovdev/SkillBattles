import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/plan_code.dart';
import 'package:skill_battles/core/domain/entity/subscription_entity.dart';
import 'package:skill_battles/core/domain/usecases/generate_id_usecase.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/utils/open_external_url.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_status_view.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_test_mode_badge.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/core/utils/extensions/go_router_extension.dart';
import 'package:skill_battles/features/account/presentation/bloc/account_bloc/account_bloc.dart';
import 'package:skill_battles/features/subscription/domain/entity/plan_interval.dart';
import 'package:skill_battles/features/subscription/domain/entity/subscription_plan_entity.dart';
import 'package:skill_battles/features/subscription/domain/usecases/get_plans_usecase.dart';
import 'package:skill_battles/features/subscription/domain/usecases/get_subscription_usecase.dart';
import 'package:skill_battles/features/subscription/domain/usecases/open_portal_usecase.dart';
import 'package:skill_battles/features/subscription/domain/usecases/start_checkout_usecase.dart';
import 'package:skill_battles/features/subscription/presentation/bloc/subscription_bloc/subscription_bloc.dart';
import 'package:skill_battles/features/subscription/presentation/widgets/subscription_labels.dart';

/// Plans and the verified subscription (Paper: "24 Plans & Upgrade"). A
/// parent signs in to the student's account and pays in Stripe-hosted test
/// Checkout; there are no separate parent accounts. Buying never affects Elo
/// or matchmaking.
final class ProScreen extends StatelessWidget implements GoRouterWrapper {
  const ProScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<SubscriptionBloc>(
      create: (_) => SubscriptionBloc(
        getPlans: dependencies.getDep<GetPlansUsecase>(),
        getSubscription: dependencies.getDep<GetSubscriptionUsecase>(),
        startCheckout: dependencies.getDep<StartCheckoutUsecase>(),
        openPortal: dependencies.getDep<OpenPortalUsecase>(),
        generateId: dependencies.getDep<GenerateIdUsecase>(),
      )..add(const SubscriptionStarted()),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: <BlocListener<dynamic, dynamic>>[
        BlocListener<SubscriptionBloc, SubscriptionState>(
          listenWhen: (SubscriptionState previous, SubscriptionState current) =>
              previous.externalUrlSerial != current.externalUrlSerial &&
              current.externalUrl != null,
          listener: (BuildContext context, SubscriptionState state) async {
            final ScaffoldMessengerState messenger = ScaffoldMessenger.of(
              context,
            );
            final bool opened = await openExternalUrl(
              context,
              state.externalUrl!,
            );
            if (!opened) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text("Couldn't open the payment page."),
                ),
              );
            }
          },
        ),
        BlocListener<AccountBloc, AccountState>(
          listenWhen: (AccountState previous, AccountState current) =>
              previous.entitlementsVersion != current.entitlementsVersion,
          listener: (BuildContext context, AccountState state) => context
              .read<SubscriptionBloc>()
              .add(const SubscriptionRefreshRequested()),
        ),
      ],
      child: AppDesktopViewport(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 40),
          child: BlocBuilder<SubscriptionBloc, SubscriptionState>(
            builder: (BuildContext context, SubscriptionState state) {
              final SubscriptionEntity? subscription = state.subscription;
              if (subscription == null) {
                if (state.loadStatus.isFailure) {
                  return AppErrorView(
                    message: state.failure?.userMessage ?? '',
                    onRetry: () => context.read<SubscriptionBloc>().add(
                      const SubscriptionRefreshRequested(),
                    ),
                  );
                }
                return const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 36,
                children: <Widget>[
                  if (subscription.isTestMode) const _TestModeNotice(),
                  const _Header(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 16,
                    children: <Widget>[
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 20,
                          children: <Widget>[
                            for (final SubscriptionPlanEntity plan
                                in state.plans)
                              Expanded(
                                child: _PlanCard(
                                  key: ValueKey<PlanCode>(plan.code),
                                  plan: plan,
                                  subscription: subscription,
                                  state: state,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (state.checkoutFailure != null)
                        AppInlineError(state.checkoutFailure!.billingMessage),
                      if (state.portalFailure != null)
                        AppInlineError(state.portalFailure!.billingMessage),
                    ],
                  ),
                  const _ParentNote(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

final class _TestModeNotice extends StatelessWidget {
  const _TestModeNotice();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.accentTint,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: <Widget>[
              const AppTestModeBadge(),
              Flexible(
                child: Text(
                  'Payments use Stripe test cards — no real money is '
                  'charged.',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.accentCalloutText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: <Widget>[
        const Text('Learn from every round.', style: AppTextStyles.displayMd),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            'Pro unlocks answers, explanations and analytics. It never '
            'changes your Elo, matchmaking or the scoring — everyone plays by '
            'the same rules.',
            style: AppTextStyles.bodyXl.copyWith(
              fontSize: 16,
              height: 24 / 16,
              color: AppColors.muted,
            ),
          ),
        ),
      ],
    );
  }
}

/// Colors of a plan card: outlined Free, ink-outlined Monthly, ink Annual.
enum _PlanLook {
  plain(null, AppColors.border, 1, AppColors.ink, AppColors.ink),
  outlined(null, AppColors.ink, 1.5, AppColors.ink, AppColors.ink),
  dark(AppColors.ink, null, 0, AppColors.white, AppColors.accent);

  const _PlanLook(
    this.background,
    this.borderColor,
    this.borderWidth,
    this.text,
    this.price,
  );

  final Color? background;
  final Color? borderColor;
  final double borderWidth;
  final Color text;
  final Color price;

  bool get isDark => this == dark;
  Color get muted => isDark ? AppColors.onDarkMuted : AppColors.muted;
  Color get line => isDark ? AppColors.onDarkLine : AppColors.divider;
}

final class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.subscription,
    required this.state,
    super.key,
  });

  final SubscriptionPlanEntity plan;
  final SubscriptionEntity subscription;
  final SubscriptionState state;

  @override
  Widget build(BuildContext context) {
    final bool isPro = subscription.entitlements.isPro;
    final bool isCurrent =
        subscription.planCode == plan.code &&
        (plan.code == PlanCode.free || isPro);
    final _PlanLook look = switch (plan.code) {
      PlanCode.free => _PlanLook.plain,
      PlanCode.proMonthly => _PlanLook.outlined,
      PlanCode.proAnnual => _PlanLook.dark,
    };
    final bool isAnnual = plan.interval == PlanInterval.year;
    final int priceCents = isAnnual
        ? plan.monthlyEquivalentCents
        : plan.amountCents;
    // "$0" for Free, cents for the paid plans.
    final String price = priceCents == 0
        ? DisplayFormatters.money(0, plan.currency).replaceAll('.00', '')
        : DisplayFormatters.money(priceCents, plan.currency);
    final String caption = isCurrent
        ? 'Your current plan'
        : switch (plan.interval) {
            PlanInterval.none => 'Always free',
            PlanInterval.month => 'Cancel anytime',
            PlanInterval.year =>
              '${DisplayFormatters.money(plan.amountCents, plan.currency)} '
                  'billed once a year',
          };
    final BorderSide? side = look.borderColor == null
        ? null
        : BorderSide(color: look.borderColor!, width: look.borderWidth);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: look.background,
        borderRadius: BorderRadius.circular(16),
        border: side == null ? null : Border.fromBorderSide(side),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 22,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        plan.code.label,
                        style: AppTextStyles.buttonMd.copyWith(
                          color: look.text,
                        ),
                      ),
                    ),
                    if (plan.annualSavingsPercent > 0)
                      _SaveChip(percent: plan.annualSavingsPercent),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  spacing: 6,
                  children: <Widget>[
                    Text(
                      price,
                      style: AppTextStyles.monoXl.copyWith(
                        fontSize: 40,
                        height: 44 / 40,
                        letterSpacing: -0.02 * 40,
                        color: look.price,
                      ),
                    ),
                    if (plan.interval != PlanInterval.none)
                      Text(
                        '/ month',
                        style: AppTextStyles.bodyMd.copyWith(color: look.muted),
                      ),
                  ],
                ),
                Text(
                  caption,
                  style: AppTextStyles.bodySm.copyWith(color: look.muted),
                ),
              ],
            ),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: look.line)),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: <Widget>[
                      for (final String feature in plan.features)
                        Text(
                          feature,
                          style: AppTextStyles.bodyMd.copyWith(
                            height: 20 / 14,
                            color: look.text,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (plan.code != PlanCode.free)
              _PlanAction(
                plan: plan,
                subscription: subscription,
                state: state,
                look: look,
              ),
          ],
        ),
      ),
    );
  }
}

final class _SaveChip extends StatelessWidget {
  const _SaveChip({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          'SAVE $percent%',
          style: AppTextStyles.monoCaption.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.04 * 11,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}

/// Free buys the plan in test Checkout; Pro changes or cancels it in the
/// Stripe portal.
final class _PlanAction extends StatelessWidget {
  const _PlanAction({
    required this.plan,
    required this.subscription,
    required this.state,
    required this.look,
  });

  final SubscriptionPlanEntity plan;
  final SubscriptionEntity subscription;
  final SubscriptionState state;
  final _PlanLook look;

  @override
  Widget build(BuildContext context) {
    final AppButtonVariant variant = look.isDark
        ? AppButtonVariant.accent
        : AppButtonVariant.outline;
    if (subscription.entitlements.isPro) {
      final bool opening = state.portalStatus.isLoading;
      return AppButton(
        label: opening
            ? 'Opening…'
            : subscription.planCode == plan.code
            ? 'Manage in Stripe'
            : 'Switch in Stripe',
        variant: variant,
        size: AppButtonSize.medium,
        expand: true,
        onPressed: opening
            ? null
            : () => context.read<SubscriptionBloc>().add(
                const SubscriptionPortalRequested(),
              ),
      );
    }
    final bool busy =
        state.checkoutStatus.isLoading && state.checkoutPlan == plan.code;
    final String choose = switch (plan.interval) {
      PlanInterval.year => 'Choose annual',
      PlanInterval.month => 'Choose monthly',
      PlanInterval.none => 'Choose ${plan.name}',
    };
    return AppButton(
      label: busy
          ? 'Opening checkout…'
          : plan.checkoutAvailable
          ? choose
          : 'Not available',
      variant: variant,
      size: AppButtonSize.medium,
      expand: true,
      onPressed: plan.checkoutAvailable && !busy
          ? () => context.read<SubscriptionBloc>().add(
              SubscriptionCheckoutRequested(plan.code),
            )
          : null,
    );
  }
}

final class _ParentNote extends StatelessWidget {
  const _ParentNote();

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTextStyles.bodyMd.copyWith(
      height: 20 / 14,
      color: AppColors.muted,
    );
    return Row(
      spacing: 12,
      children: <Widget>[
        const AppSvgIcon(AppIcons.info, width: 18, height: 18),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                const TextSpan(text: 'Paying for a student? Sign in to '),
                TextSpan(
                  text: 'their',
                  style: style.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(
                  text:
                      ' account on this device and complete checkout here. '
                      'Pro activates once Stripe confirms the payment.',
                ),
              ],
            ),
            style: style,
          ),
        ),
      ],
    );
  }
}
