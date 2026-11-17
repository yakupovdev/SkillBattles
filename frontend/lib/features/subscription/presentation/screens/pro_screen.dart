import 'package:bloc_signals_jaspr/bloc_signals_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/domain/entity/plan_code.dart';
import 'package:skill_battles/core/domain/entity/subscription_entity.dart';
import 'package:skill_battles/core/domain/usecases/generate_id_usecase.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/overlay/app_overlay.dart';
import 'package:skill_battles/core/presentation/utils/open_external_url.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_status_view.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_test_mode_badge.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/core/utils/extensions/route_extension.dart';
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
final class ProScreen extends StatelessComponent implements RouteWrapper {
  const ProScreen({super.key});

  @override
  Component wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocSignalProvider<SubscriptionBloc>(
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

  static Future<void> _openExternal(BuildContext context, String url) async {
    // Same tab: Stripe returns to the billing return page.
    final bool opened = await openExternalUrl(context, url);
    if (!opened) showAppSnackBar(context, "Couldn't open the payment page.");
  }

  @override
  Component build(BuildContext context) {
    return MultiBlocSignalListener(
      listeners: <BlocSignalListenerSingleChildComponent>[
        BlocSignalListener<SubscriptionBloc, SubscriptionState>(
          listenWhen: (SubscriptionState previous, SubscriptionState current) =>
              previous.externalUrlSerial != current.externalUrlSerial && current.externalUrl != null,
          listener: (BuildContext context, SubscriptionState state) => _openExternal(context, state.externalUrl!),
        ),
        BlocSignalListener<AccountBloc, AccountState>(
          listenWhen: (AccountState previous, AccountState current) =>
              previous.entitlementsVersion != current.entitlementsVersion,
          listener: (BuildContext context, AccountState state) =>
              context.read<SubscriptionBloc>().add(const SubscriptionRefreshRequested()),
        ),
      ],
      child: AppDesktopViewport(
        child: div(classes: 'pro-page', <Component>[
          BlocSignalBuilder<SubscriptionBloc, SubscriptionState>(
            builder: (BuildContext context, SubscriptionState state) {
              final SubscriptionEntity? subscription = state.subscription;
              if (subscription == null) {
                if (state.loadStatus.isFailure) {
                  return AppErrorView(
                    message: state.failure?.userMessage ?? '',
                    onRetry: () => context.read<SubscriptionBloc>().add(const SubscriptionRefreshRequested()),
                  );
                }
                return const _Loading();
              }
              return div(classes: 'pro-page__content', <Component>[
                if (subscription.isTestMode) const _TestModeNotice(),
                const _Header(),
                div(classes: 'pro-page__plans-block', <Component>[
                  div(classes: 'pro-page__plans', <Component>[
                    for (final SubscriptionPlanEntity plan in state.plans)
                      _PlanCard(
                        key: ValueKey<PlanCode>(plan.code),
                        plan: plan,
                        subscription: subscription,
                        state: state,
                      ),
                  ]),
                  if (state.checkoutFailure != null) AppInlineError(state.checkoutFailure!.billingMessage),
                  if (state.portalFailure != null) AppInlineError(state.portalFailure!.billingMessage),
                ]),
                const _ParentNote(),
              ]);
            },
          ),
        ]),
      ),
    );
  }
}

/// The page-level progress indicator while plans load.
final class _Loading extends StatelessComponent {
  const _Loading();

  @override
  Component build(BuildContext context) {
    return const div(classes: 'pro-page__loading', <Component>[
      span(
        classes: 'pro-page__spinner',
        attributes: <String, String>{'role': 'progressbar', 'aria-label': 'Loading plans'},
        <Component>[],
      ),
    ]);
  }
}

final class _TestModeNotice extends StatelessComponent {
  const _TestModeNotice();

  @override
  Component build(BuildContext context) {
    return const div(classes: 'pro-test-notice', <Component>[
      AppTestModeBadge(),
      span(classes: 'pro-test-notice__text', <Component>[
        Component.text('Payments use Stripe test cards — no real money is charged.'),
      ]),
    ]);
  }
}

final class _Header extends StatelessComponent {
  const _Header();

  @override
  Component build(BuildContext context) {
    return const div(classes: 'pro-header', <Component>[
      h1(classes: 'pro-header__title', <Component>[Component.text('Learn from every round.')]),
      p(classes: 'pro-header__body', <Component>[
        Component.text(
          'Pro unlocks answers, explanations and analytics. It never '
          'changes your Elo, matchmaking or the scoring — everyone plays by '
          'the same rules.',
        ),
      ]),
    ]);
  }
}

/// Colors of a plan card: outlined Free, ink-outlined Monthly, ink Annual.
enum _PlanLook {
  plain(null, AppColors.border, 1, AppColors.ink, AppColors.ink),
  outlined(null, AppColors.ink, 1.5, AppColors.ink, AppColors.ink),
  dark(AppColors.ink, null, 0, AppColors.white, AppColors.accent);

  const _PlanLook(this.background, this.borderColor, this.borderWidth, this.text, this.price);

  final Color? background;
  final Color? borderColor;
  final double borderWidth;
  final Color text;
  final Color price;

  bool get isDark => this == dark;
  Color get muted => isDark ? AppColors.onDarkMuted : AppColors.muted;
  Color get line => isDark ? AppColors.onDarkLine : AppColors.divider;
}

final class _PlanCard extends StatelessComponent {
  const _PlanCard({required this.plan, required this.subscription, required this.state, super.key});

  final SubscriptionPlanEntity plan;
  final SubscriptionEntity subscription;
  final SubscriptionState state;

  @override
  Component build(BuildContext context) {
    final bool isPro = subscription.entitlements.isPro;
    final bool isCurrent = subscription.planCode == plan.code && (plan.code == PlanCode.free || isPro);
    final _PlanLook look = switch (plan.code) {
      PlanCode.free => _PlanLook.plain,
      PlanCode.proMonthly => _PlanLook.outlined,
      PlanCode.proAnnual => _PlanLook.dark,
    };
    final bool isAnnual = plan.interval == PlanInterval.year;
    final int priceCents = isAnnual ? plan.monthlyEquivalentCents : plan.amountCents;
    // "$0" for Free, cents for the paid plans.
    final String price = priceCents == 0
        ? DisplayFormatters.money(0, plan.currency).replaceAll('.00', '')
        : DisplayFormatters.money(priceCents, plan.currency);
    final String caption = isCurrent
        ? 'Your current plan'
        : switch (plan.interval) {
            PlanInterval.none => 'Always free',
            PlanInterval.month => 'Cancel anytime',
            PlanInterval.year => '${DisplayFormatters.money(plan.amountCents, plan.currency)} billed once a year',
          };
    final Color? borderColor = look.borderColor;
    return div(
      classes: 'pro-plan',
      styles: Styles(
        border: borderColor == null ? null : Border.all(color: borderColor, width: Unit.pixels(look.borderWidth)),
        backgroundColor: look.background,
      ),
      <Component>[
        div(classes: 'pro-plan__head', <Component>[
          div(classes: 'pro-plan__name-row', <Component>[
            span(classes: 'pro-plan__name', styles: Styles(color: look.text), <Component>[
              Component.text(plan.code.label),
            ]),
            if (plan.annualSavingsPercent > 0) _SaveChip(percent: plan.annualSavingsPercent),
          ]),
          div(classes: 'pro-plan__price-row', <Component>[
            span(classes: 'pro-plan__price', styles: Styles(color: look.price), <Component>[Component.text(price)]),
            if (plan.interval != PlanInterval.none)
              span(classes: 'pro-plan__per', styles: Styles(color: look.muted), <Component>[
                const Component.text('/ month'),
              ]),
          ]),
          span(classes: 'pro-plan__caption', styles: Styles(color: look.muted), <Component>[Component.text(caption)]),
        ]),
        ul(
          classes: 'pro-plan__features',
          styles: Styles(
            border: Border.only(
              top: BorderSide(color: look.line, width: const Unit.pixels(1)),
            ),
          ),
          <Component>[
            for (final String feature in plan.features)
              li(classes: 'pro-plan__feature', styles: Styles(color: look.text), <Component>[Component.text(feature)]),
          ],
        ),
        if (plan.code != PlanCode.free) _PlanAction(plan: plan, subscription: subscription, state: state, look: look),
      ],
    );
  }
}

final class _SaveChip extends StatelessComponent {
  const _SaveChip({required this.percent});

  final int percent;

  @override
  Component build(BuildContext context) {
    return span(classes: 'pro-plan__save', <Component>[Component.text('SAVE $percent%')]);
  }
}

/// Free buys the plan in test Checkout; Pro changes or cancels it in the
/// Stripe portal.
final class _PlanAction extends StatelessComponent {
  const _PlanAction({required this.plan, required this.subscription, required this.state, required this.look});

  final SubscriptionPlanEntity plan;
  final SubscriptionEntity subscription;
  final SubscriptionState state;
  final _PlanLook look;

  @override
  Component build(BuildContext context) {
    final AppButtonVariant variant = look.isDark ? AppButtonVariant.accent : AppButtonVariant.outline;
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
        onPressed: opening ? null : () => context.read<SubscriptionBloc>().add(const SubscriptionPortalRequested()),
      );
    }
    final bool busy = state.checkoutStatus.isLoading && state.checkoutPlan == plan.code;
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
          ? () => context.read<SubscriptionBloc>().add(SubscriptionCheckoutRequested(plan.code))
          : null,
    );
  }
}

final class _ParentNote extends StatelessComponent {
  const _ParentNote();

  @override
  Component build(BuildContext context) {
    return const div(classes: 'pro-parent-note', <Component>[
      AppSvgIcon(AppIcons.info, width: 18, height: 18),
      p(classes: 'pro-parent-note__text', <Component>[
        Component.text('Paying for a student? Sign in to '),
        strong(classes: 'pro-parent-note__strong', <Component>[Component.text('their')]),
        Component.text(
          ' account on this device and complete checkout here. '
          'Pro activates once Stripe confirms the payment.',
        ),
      ]),
    ]);
  }
}

@css
List<StyleRule> get proScreenStyles => <StyleRule>[
  css.keyframes('pro-spin', <String, Styles>{'to': const Styles(transform: Transform.rotate(Angle.deg(360)))}),
  css('.pro-page').styles(
    display: Display.flex,
    padding: const Padding.symmetric(horizontal: Unit.pixels(64), vertical: Unit.pixels(40)),
    flexDirection: FlexDirection.column,
  ),
  css('.pro-page__loading').styles(
    display: Display.flex,
    padding: const Padding.only(top: Unit.pixels(120)),
    justifyContent: JustifyContent.center,
  ),
  css('.pro-page__spinner').styles(
    display: Display.block,
    width: const Unit.pixels(36),
    height: const Unit.pixels(36),
    border: Border.all(color: AppColors.primary, width: const Unit.pixels(4)),
    radius: const BorderRadius.circular(Unit.percent(50)),
    raw: const <String, String>{'border-right-color': 'transparent', 'animation': 'pro-spin 0.9s linear infinite'},
  ),
  css('.pro-page__content').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(36)),
  ),
  css('.pro-test-notice').styles(
    display: Display.flex,
    padding: const Padding.symmetric(horizontal: Unit.pixels(14), vertical: Unit.pixels(10)),
    radius: const BorderRadius.circular(Unit.pixels(10)),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(10)),
    alignSelf: AlignSelf.start,
    backgroundColor: AppColors.accentTint,
  ),
  css('.pro-test-notice__text').combine(AppTextStyles.bodySm).combine(const Styles(color: AppColors.accentCalloutText)),
  css('.pro-header').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(12)),
  ),
  css('.pro-header__title').combine(AppTextStyles.displayMd),
  css('.pro-header__body')
      .styles(maxWidth: const Unit.pixels(620))
      .combine(AppTextStyles.bodyXl)
      .combine(const Styles(color: AppColors.muted, fontSize: Unit.pixels(16), lineHeight: Unit.pixels(24))),
  css('.pro-page__plans-block').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(16)),
  ),
  css('.pro-page__plans').styles(
    display: Display.flex,
    alignItems: AlignItems.stretch,
    gap: const Gap.column(Unit.pixels(20)),
  ),
  css('.pro-plan').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    padding: const Padding.all(Unit.pixels(28)),
    radius: const BorderRadius.circular(Unit.pixels(16)),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(22)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.pro-plan__head').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(6)),
  ),
  css('.pro-plan__name-row').styles(
    display: Display.flex,
    width: const Unit.percent(100),
    alignItems: AlignItems.center,
  ),
  css('.pro-plan__name')
      .styles(
        minWidth: Unit.zero,
        flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
      )
      .combine(AppTextStyles.buttonMd),
  css('.pro-plan__save')
      .styles(
        padding: const Padding.symmetric(horizontal: Unit.pixels(8), vertical: Unit.pixels(3)),
        radius: const BorderRadius.circular(Unit.pixels(6)),
      )
      .combine(AppTextStyles.monoCaption)
      .combine(
        const Styles(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          letterSpacing: Unit.em(0.04),
          backgroundColor: AppColors.accent,
        ),
      ),
  css('.pro-plan__price-row').styles(
    display: Display.flex,
    alignItems: AlignItems.baseline,
    gap: const Gap.column(Unit.pixels(6)),
  ),
  css('.pro-plan__price')
      .combine(AppTextStyles.monoXl)
      .combine(const Styles(fontSize: Unit.pixels(40), letterSpacing: Unit.em(-0.02), lineHeight: Unit.pixels(44))),
  css('.pro-plan__per').combine(AppTextStyles.bodyMd),
  css('.pro-plan__caption').combine(AppTextStyles.bodySm),
  css('.pro-plan__features').styles(
    display: Display.flex,
    padding: const Padding.only(top: Unit.pixels(18)),
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(10)),
    flex: const Flex(grow: 1, shrink: 0, basis: Unit.auto),
    listStyle: ListStyle.none,
  ),
  css('.pro-plan__feature').combine(AppTextStyles.bodyMd).combine(const Styles(lineHeight: Unit.pixels(20))),
  css('.pro-parent-note').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(12)),
  ),
  css('.pro-parent-note__text')
      .styles(
        minWidth: Unit.zero,
        flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
      )
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(color: AppColors.muted, lineHeight: Unit.pixels(20))),
  css('.pro-parent-note__strong').styles(color: AppColors.ink, fontWeight: FontWeight.w600),
];
