import 'package:bloc_signals_jaspr/bloc_signals_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

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
import 'package:skill_battles/core/utils/extensions/route_extension.dart';
import 'package:skill_battles/features/account/presentation/bloc/account_bloc/account_bloc.dart';
import 'package:skill_battles/features/subscription/domain/usecases/get_subscription_usecase.dart';
import 'package:skill_battles/features/subscription/presentation/bloc/billing_return_bloc/billing_return_bloc.dart';
import 'package:skill_battles/features/subscription/presentation/widgets/subscription_labels.dart';

/// Where Stripe returns (Paper: "25 Checkout return — verifying"). Shows the
/// server-verified status; the query string (`success=true`) is never taken
/// as proof of payment.
final class BillingReturnScreen extends StatelessComponent implements RouteWrapper {
  const BillingReturnScreen({required this.checkoutCancelled, super.key});

  final bool checkoutCancelled;

  @override
  Component wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocSignalProvider<BillingReturnBloc>(
      create: (_) => BillingReturnBloc(
        getSubscription: dependencies.getDep<GetSubscriptionUsecase>(),
      )..add(BillingReturnStarted(checkoutCancelled: checkoutCancelled)),
      child: this,
    );
  }

  @override
  Component build(BuildContext context) {
    return BlocSignalListener<BillingReturnBloc, BillingReturnState>(
      listenWhen: (BillingReturnState previous, BillingReturnState current) => previous.status != current.status,
      listener: (BuildContext context, BillingReturnState state) =>
          context.read<AccountBloc>().add(const AccountRefreshRequested()),
      child: AppDesktopViewport(
        child: div(classes: 'billing-return', <Component>[
          div(classes: 'billing-return__column', <Component>[
            BlocSignalBuilder<BillingReturnBloc, BillingReturnState>(
              builder: (BuildContext context, BillingReturnState state) {
                final _ReturnCallout? callout = _ReturnCallout.forState(state);
                return div(classes: 'billing-return__content', <Component>[
                  _Hero(state: state),
                  ?callout,
                ]);
              },
            ),
          ]),
        ]),
      ),
    );
  }
}

final class _Hero extends StatelessComponent {
  const _Hero({required this.state});

  final BillingReturnState state;

  @override
  Component build(BuildContext context) {
    final PlanCode? code = state.subscription?.planCode;
    // While Stripe has not confirmed, the account may still report Free.
    final String plan = code == null || code == PlanCode.free ? 'Pro' : code.label;
    final bool waiting = state.status == BillingReturnStatus.checking || state.status == BillingReturnStatus.pending;
    final bool isActive = state.status == BillingReturnStatus.active;
    final String title = switch (state.status) {
      BillingReturnStatus.checking || BillingReturnStatus.pending => 'Confirming your payment…',
      BillingReturnStatus.active => 'Payment confirmed',
      BillingReturnStatus.cancelled => 'Checkout was cancelled',
    };
    return div(classes: 'billing-hero', <Component>[
      switch (state.status) {
        BillingReturnStatus.checking || BillingReturnStatus.pending => const span(
          classes: 'billing-hero__spinner',
          attributes: <String, String>{'role': 'progressbar', 'aria-label': 'Confirming the payment'},
          <Component>[],
        ),
        BillingReturnStatus.active => const AppSvgIcon(AppIcons.statusSuccess, width: 64, height: 64),
        BillingReturnStatus.cancelled => const AppSvgIcon(AppIcons.statusError, width: 64, height: 64),
      },
      h1(classes: 'billing-hero__title', <Component>[Component.text(title)]),
      div(
        classes: 'billing-hero__body',
        attributes: const <String, String>{'aria-live': 'polite'},
        <Component>[
          switch (state.status) {
            BillingReturnStatus.checking || BillingReturnStatus.pending => _WaitingBody(plan: plan),
            BillingReturnStatus.active => p(<Component>[
              Component.text(
                '$plan is active. Your full history, correct answers and '
                'analytics are unlocked.',
              ),
            ]),
            BillingReturnStatus.cancelled => const p(<Component>[
              Component.text('Nothing was charged. You can choose a plan again anytime.'),
            ]),
          },
        ],
      ),
      div(classes: 'billing-hero__actions', <Component>[
        if (waiting)
          AppButton(
            label: 'Check again',
            variant: AppButtonVariant.outline,
            size: AppButtonSize.small,
            onPressed: () =>
                context.read<BillingReturnBloc>().add(const BillingReturnStarted(checkoutCancelled: false)),
          )
        else if (isActive)
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
        div(classes: 'billing-hero__link', <Component>[
          AppTextLink(
            label: isActive ? 'Subscription details' : 'Back to home',
            style: AppTextStyles.bodyMd.combine(const Styles(color: AppColors.muted, fontWeight: FontWeight.w500)),
            onPressed: isActive ? context.goPro : context.goHome,
          ),
        ]),
      ]),
      if (state.subscription?.isTestMode ?? true)
        const div(classes: 'billing-hero__test', <Component>[
          AppTestModeBadge(),
          span(classes: 'billing-hero__test-text', <Component>[Component.text('No real money was charged.')]),
        ]),
    ]);
  }
}

/// "We're waiting for Stripe to confirm Pro for `nickname`. …"
final class _WaitingBody extends StatelessComponent {
  const _WaitingBody({required this.plan});

  final String plan;

  @override
  Component build(BuildContext context) {
    return BlocSignalSelector<AccountBloc, AccountState, String?>(
      selector: (AccountState state) => state.account?.user.nickname,
      builder: (BuildContext context, String? nickname) => p(<Component>[
        Component.text("We're waiting for Stripe to confirm $plan"),
        if (nickname != null) ...<Component>[
          const Component.text(' for '),
          strong(classes: 'billing-hero__nickname', <Component>[Component.text(nickname)]),
        ],
        const Component.text(
          '. This usually takes a few seconds — you can keep this page '
          'open or go play.',
        ),
      ]),
    );
  }
}

/// Outcome box under the hero: Pro is on, the payment did not go through,
/// or Stripe is slow.
final class _ReturnCallout extends StatelessComponent {
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
        title: end == null ? "You're Pro" : "You're Pro until ${DisplayFormatters.date(end)}",
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
  Component build(BuildContext context) {
    final String? label = actionLabel;
    final void Function(BuildContext context)? action = onAction;
    final Styles bodyStyle = AppTextStyles.bodySm.combine(Styles(color: bodyColor, lineHeight: const Unit.pixels(19)));
    return div(
      classes: 'billing-callout',
      styles: Styles(backgroundColor: background),
      attributes: const <String, String>{'aria-live': 'polite'},
      <Component>[
        AppSvgIcon(icon, width: 22, height: 22),
        div(classes: 'billing-callout__text', <Component>[
          span(classes: 'billing-callout__title', styles: Styles(color: titleColor), <Component>[
            Component.text(title),
          ]),
          p(styles: bodyStyle, <Component>[Component.text(message)]),
          if (label != null)
            AppTextLink(
              label: label,
              style: bodyStyle.combine(const Styles(color: AppColors.primary, fontWeight: FontWeight.w500)),
              onPressed: action == null ? null : () => action(context),
            ),
        ]),
      ],
    );
  }
}

@css
List<StyleRule> get billingReturnScreenStyles => <StyleRule>[
  css.keyframes('billing-spin', <String, Styles>{'to': const Styles(transform: Transform.rotate(Angle.deg(360)))}),
  css('.billing-return').styles(
    display: Display.flex,
    padding: const Padding.symmetric(horizontal: Unit.pixels(64), vertical: Unit.pixels(40)),
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
  ),
  css('.billing-return__column').styles(width: const Unit.percent(100), maxWidth: const Unit.pixels(560)),
  css('.billing-return__content').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(56)),
  ),
  css('.billing-hero').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.center,
    gap: const Gap.row(Unit.pixels(20)),
  ),
  css('.billing-hero__spinner').styles(
    display: Display.block,
    width: const Unit.pixels(59),
    height: const Unit.pixels(59),
    margin: const Margin.all(Unit.pixels(2.5)),
    border: Border.all(color: AppColors.divider, width: const Unit.pixels(5)),
    radius: const BorderRadius.circular(Unit.percent(50)),
    raw: const <String, String>{
      'border-top-color': '#2B4BF2',
      'animation': 'billing-spin 1s linear infinite',
    },
  ),
  css('.billing-hero__title').combine(AppTextStyles.headlineLg).combine(const Styles(textAlign: TextAlign.center)),
  css('.billing-hero__body')
      .combine(AppTextStyles.bodyXl)
      .combine(
        const Styles(
          color: AppColors.muted,
          textAlign: TextAlign.center,
          fontSize: Unit.pixels(16),
          lineHeight: Unit.pixels(24),
        ),
      ),
  css('.billing-hero__nickname').styles(color: AppColors.ink, fontWeight: FontWeight.w600),
  css('.billing-hero__actions').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(12)),
  ),
  css('.billing-hero__link').styles(padding: const Padding.symmetric(horizontal: Unit.pixels(20))),
  css('.billing-hero__test').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(8)),
  ),
  css('.billing-hero__test-text').combine(AppTextStyles.bodyXs).combine(const Styles(color: AppColors.muted)),
  css('.billing-callout').styles(
    display: Display.flex,
    padding: const Padding.all(Unit.pixels(20)),
    radius: const BorderRadius.circular(Unit.pixels(14)),
    alignItems: AlignItems.start,
    gap: const Gap.column(Unit.pixels(14)),
  ),
  css('.billing-callout__text').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    alignItems: AlignItems.start,
    gap: const Gap.row(Unit.pixels(4)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.billing-callout__title').combine(AppTextStyles.buttonMd),
];
