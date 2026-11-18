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
import 'package:skill_battles/core/domain/entity/subscription_status.dart';
import 'package:skill_battles/core/domain/entity/user_entity.dart';
import 'package:skill_battles/core/domain/usecases/generate_id_usecase.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/overlay/app_overlay.dart';
import 'package:skill_battles/core/presentation/utils/open_external_url.dart';
import 'package:skill_battles/core/presentation/widgets/app_avatar.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_form.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_field.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_input.dart';
import 'package:skill_battles/core/presentation/widgets/pro_badge.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/core/utils/extensions/route_extension.dart';
import 'package:skill_battles/core/utils/feature_flags.dart';
import 'package:skill_battles/core/utils/form_validators.dart';
import 'package:skill_battles/features/account/domain/entity/update_profile_params_entity.dart';
import 'package:skill_battles/features/account/domain/usecases/update_profile_usecase.dart';
import 'package:skill_battles/features/account/presentation/bloc/account_bloc/account_bloc.dart';
import 'package:skill_battles/features/profile/presentation/bloc/edit_profile_bloc/edit_profile_bloc.dart';
import 'package:skill_battles/features/subscription/domain/entity/plan_interval.dart';
import 'package:skill_battles/features/subscription/domain/entity/subscription_plan_entity.dart';
import 'package:skill_battles/features/subscription/domain/usecases/get_plans_usecase.dart';
import 'package:skill_battles/features/subscription/domain/usecases/get_subscription_usecase.dart';
import 'package:skill_battles/features/subscription/domain/usecases/open_portal_usecase.dart';
import 'package:skill_battles/features/subscription/domain/usecases/start_checkout_usecase.dart';
import 'package:skill_battles/features/subscription/presentation/bloc/subscription_bloc/subscription_bloc.dart';
import 'package:skill_battles/features/subscription/presentation/widgets/subscription_labels.dart';

/// Account settings (Paper: "26 Account settings (Pro)"): nickname,
/// password and the subscription. The email never changes; a password
/// change signs every device out, so the user logs in again.
final class EditProfileScreen extends StatefulComponent implements RouteWrapper {
  const EditProfileScreen({super.key});

  @override
  Component wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return MultiBlocSignalProvider(
      providers: <BlocSignalProviderSingleChildComponent>[
        BlocSignalProvider<EditProfileBloc>(
          create: (_) => EditProfileBloc(updateProfile: dependencies.getDep<UpdateProfileUsecase>()),
        ),
        BlocSignalProvider<SubscriptionBloc>(
          create: (_) {
            final SubscriptionBloc bloc = SubscriptionBloc(
              getPlans: dependencies.getDep<GetPlansUsecase>(),
              getSubscription: dependencies.getDep<GetSubscriptionUsecase>(),
              startCheckout: dependencies.getDep<StartCheckoutUsecase>(),
              openPortal: dependencies.getDep<OpenPortalUsecase>(),
              generateId: dependencies.getDep<GenerateIdUsecase>(),
            );
            // Payments are off: there is no subscription section to load.
            if (FeatureFlags.billing) bloc.add(const SubscriptionStarted());
            return bloc;
          },
        ),
      ],
      child: this,
    );
  }

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

final class _EditProfileScreenState extends State<EditProfileScreen> {
  late final GlobalStateKey<AppFormState> _nicknameForm;
  late final GlobalStateKey<AppFormState> _passwordForm;
  late final TextEditingController _nickname;
  late final TextEditingController _email;
  late final TextEditingController _current;
  late final TextEditingController _next;
  late final FocusNode _currentFocus;
  late final FocusNode _nextFocus;

  @override
  void initState() {
    super.initState();
    _nicknameForm = GlobalStateKey<AppFormState>();
    _passwordForm = GlobalStateKey<AppFormState>();
    final UserEntity? user = context.read<AccountBloc>().stateValue.account?.user;
    _nickname = TextEditingController(text: user?.nickname ?? '');
    _email = TextEditingController(text: user?.email ?? '');
    _current = TextEditingController();
    _next = TextEditingController();
    _currentFocus = FocusNode();
    _nextFocus = FocusNode();
  }

  @override
  void dispose() {
    _nickname.dispose();
    _email.dispose();
    _current.dispose();
    _next.dispose();
    _currentFocus.dispose();
    _nextFocus.dispose();
    super.dispose();
  }

  void _saveNickname() {
    if (!(_nicknameForm.currentState?.validate() ?? false)) return;
    context.read<EditProfileBloc>().add(
      EditProfileNicknameSubmitted(UpdateProfileParamsEntity(nickname: _nickname.text)),
    );
  }

  void _savePassword() {
    if (!(_passwordForm.currentState?.validate() ?? false)) return;
    context.read<EditProfileBloc>().add(
      EditProfilePasswordSubmitted(
        UpdateProfileParamsEntity(currentPassword: _current.text, newPassword: _next.text),
      ),
    );
  }

  /// The account arrives after the screen opened (a reload): fill the
  /// fields once, without touching what the user already typed.
  void _onUserLoaded(UserEntity user) {
    if (_nickname.text.isEmpty) _nickname.text = user.nickname;
    _email.text = user.email;
  }

  Future<void> _openExternal(String url) async {
    final bool opened = await openExternalUrl(context, url);
    if (!opened && mounted) showAppSnackBar(context, "Couldn't open Stripe.");
  }

  @override
  Component build(BuildContext context) {
    return MultiBlocSignalListener(
      listeners: <BlocSignalListenerSingleChildComponent>[
        BlocSignalListener<AccountBloc, AccountState>(
          listenWhen: (AccountState previous, AccountState current) =>
              previous.account?.user != current.account?.user && current.account != null,
          listener: (BuildContext context, AccountState state) => _onUserLoaded(state.account!.user),
        ),
        BlocSignalListener<EditProfileBloc, EditProfileState>(
          listenWhen: (EditProfileState previous, EditProfileState current) =>
              previous.nicknameStatus != current.nicknameStatus && current.nicknameStatus.isSuccess,
          listener: (BuildContext context, EditProfileState state) {
            context.read<AccountBloc>().add(const AccountRefreshRequested());
            showAppSnackBar(context, 'Nickname saved');
          },
        ),
        BlocSignalListener<EditProfileBloc, EditProfileState>(
          listenWhen: (EditProfileState previous, EditProfileState current) =>
              previous.passwordStatus != current.passwordStatus && current.passwordStatus.isSuccess,
          // The session is already cleared; the router opens log-in.
          listener: (BuildContext context, EditProfileState state) =>
              showAppSnackBar(context, 'Password changed. Log in with the new one.'),
        ),
        BlocSignalListener<SubscriptionBloc, SubscriptionState>(
          listenWhen: (SubscriptionState previous, SubscriptionState current) =>
              previous.externalUrlSerial != current.externalUrlSerial && current.externalUrl != null,
          listener: (BuildContext context, SubscriptionState state) => _openExternal(state.externalUrl!),
        ),
      ],
      child: AppDesktopViewport(
        child: div(classes: 'edit-profile', <Component>[
          const _SideColumn(),
          div(classes: 'edit-profile__main', <Component>[
            _SectionBlock(
              child: _ProfileSection(formKey: _nicknameForm, nickname: _nickname, email: _email, onSave: _saveNickname),
            ),
            _SectionBlock(
              child: _PasswordSection(
                formKey: _passwordForm,
                email: _email,
                current: _current,
                next: _next,
                currentFocus: _currentFocus,
                nextFocus: _nextFocus,
                onSave: _savePassword,
              ),
            ),
            if (FeatureFlags.billing) const _SubscriptionSection(),
          ]),
        ]),
      ),
    );
  }
}

String _profileMessage(Failure failure) {
  if (failure.hasCode(ApiErrorCodes.nicknameAlreadyExists)) {
    return 'This nickname is taken.';
  }
  if (failure.hasCode(ApiErrorCodes.invalidCurrentPassword)) {
    return 'The current password is incorrect.';
  }
  if (failure.hasCode(ApiErrorCodes.emptyUpdate)) return 'Nothing changed.';
  return failure.userMessage;
}

/// `onPressed` of a submit button: the click submits the enclosing
/// [AppForm], whose `onSubmit` does the work (also for Enter in a field).
void _submitsEnclosingForm() {}

/// Title and identity; log-out lives in the top bar's account menu.
final class _SideColumn extends StatelessComponent {
  const _SideColumn();

  @override
  Component build(BuildContext context) {
    return const div(classes: 'edit-profile__side', <Component>[
      h1(classes: 'edit-profile__title', <Component>[Component.text('Account')]),
      _Identity(),
    ]);
  }
}

final class _Identity extends StatelessComponent {
  const _Identity();

  @override
  Component build(BuildContext context) {
    return BlocSignalBuilder<AccountBloc, AccountState>(
      buildWhen: (AccountState previous, AccountState current) =>
          previous.account?.user != current.account?.user || previous.isPro != current.isPro,
      builder: (BuildContext context, AccountState state) {
        final UserEntity? user = state.account?.user;
        if (user == null) return const div(classes: 'edit-profile__identity-empty', <Component>[]);
        return div(classes: 'edit-profile__identity', <Component>[
          AppAvatar(nickname: user.nickname, size: AppAvatarSize.settings),
          div(classes: 'edit-profile__identity-text', <Component>[
            div(classes: 'edit-profile__identity-name-row', <Component>[
              span(classes: 'edit-profile__identity-name', <Component>[Component.text(user.nickname)]),
              if (state.isPro) const ProBadge(tone: ProBadgeTone.amber),
            ]),
            span(classes: 'edit-profile__identity-meta', <Component>[
              Component.text('${user.email} · since ${DisplayFormatters.monthYear(user.createdAt)}'),
            ]),
          ]),
        ]);
      },
    );
  }
}

/// A server error under a block, or nothing.
final class _FailureLine extends StatelessComponent {
  const _FailureLine({required this.message});

  final String? message;

  @override
  Component build(BuildContext context) {
    final String? message = this.message;
    if (message == null) return const Component.empty();
    return div(classes: 'edit-profile__failure', <Component>[AppInlineError(message)]);
  }
}

/// A settings block with a line and 32 px below it.
final class _SectionBlock extends StatelessComponent {
  const _SectionBlock({required this.child});

  final Component child;

  @override
  Component build(BuildContext context) {
    return div(classes: 'edit-profile__block', <Component>[child]);
  }
}

final class _ProfileSection extends StatelessComponent {
  const _ProfileSection({required this.formKey, required this.nickname, required this.email, required this.onSave});

  final GlobalStateKey<AppFormState> formKey;
  final TextEditingController nickname;
  final TextEditingController email;
  final VoidCallback onSave;

  @override
  Component build(BuildContext context) {
    return AppForm(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      onSubmit: onSave,
      child: div(classes: 'edit-profile__section', <Component>[
        const h2(classes: 'edit-profile__section-title', <Component>[Component.text('Profile')]),
        div(classes: 'edit-profile__row', <Component>[
          div(classes: 'edit-profile__field', <Component>[
            // No onFieldSubmitted: Enter submits the form.
            AppTextField(
              label: 'Nickname',
              controller: nickname,
              validator: FormValidators.nickname,
              textInputAction: TextInputAction.done,
              autofillHints: const <String>[AutofillHints.nickname],
            ),
          ]),
          div(classes: 'edit-profile__field', <Component>[
            AppTextField(label: 'Email', controller: email, enabled: false),
          ]),
          div(classes: 'edit-profile__row-action', <Component>[
            BlocSignalSelector<EditProfileBloc, EditProfileState, bool>(
              selector: (EditProfileState state) => state.nicknameStatus.isLoading,
              builder: (BuildContext context, bool isSaving) => AppButton(
                label: isSaving ? 'Saving…' : 'Save',
                variant: AppButtonVariant.dark,
                size: AppButtonSize.field,
                type: ButtonType.submit,
                onPressed: isSaving ? null : _submitsEnclosingForm,
              ),
            ),
          ]),
        ]),
        const p(classes: 'edit-profile__hint', <Component>[
          Component.text("3–24 letters, numbers, _ or -. Email can't be changed."),
        ]),
        BlocSignalSelector<EditProfileBloc, EditProfileState, Failure?>(
          selector: (EditProfileState state) => state.nicknameFailure,
          builder: (BuildContext context, Failure? failure) =>
              failure == null ? const Component.empty() : AppInlineError(_profileMessage(failure)),
        ),
      ]),
    );
  }
}

/// Current and new password. A hidden `username` field carries the account
/// email, so password managers update the right saved login.
final class _PasswordSection extends StatelessComponent {
  const _PasswordSection({
    required this.formKey,
    required this.email,
    required this.current,
    required this.next,
    required this.currentFocus,
    required this.nextFocus,
    required this.onSave,
  });

  final GlobalStateKey<AppFormState> formKey;
  final TextEditingController email;
  final TextEditingController current;
  final TextEditingController next;
  final FocusNode currentFocus;
  final FocusNode nextFocus;
  final VoidCallback onSave;

  @override
  Component build(BuildContext context) {
    return AppForm(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      onSubmit: onSave,
      child: div(classes: 'edit-profile__section', <Component>[
        const div(classes: 'edit-profile__section-heading', <Component>[
          h2(classes: 'edit-profile__section-title', <Component>[Component.text('Change password')]),
          p(classes: 'edit-profile__section-note', <Component>[
            Component.text("You'll be signed out everywhere and asked to log in again."),
          ]),
        ]),
        div(classes: 'edit-profile__password', <Component>[
          ListenableBuilder(
            listenable: email,
            builder: (BuildContext context) => input<String>(
              type: InputType.email,
              name: 'username',
              value: email.text,
              attributes: const <String, String>{
                'autocomplete': 'username',
                'hidden': '',
                'readonly': '',
                'tabindex': '-1',
                'aria-hidden': 'true',
              },
            ),
          ),
          div(classes: 'edit-profile__row', <Component>[
            div(classes: 'edit-profile__field', <Component>[
              AppTextField(
                label: 'Current password',
                controller: current,
                focusNode: currentFocus,
                validator: FormValidators.currentPassword,
                obscureText: true,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.password],
                onFieldSubmitted: (_) => nextFocus.requestFocus(),
              ),
            ]),
            div(classes: 'edit-profile__field', <Component>[
              // No onFieldSubmitted: Enter submits the form.
              AppTextField(
                label: 'New password',
                controller: next,
                focusNode: nextFocus,
                validator: FormValidators.password,
                hintText: '8–72 characters',
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const <String>[AutofillHints.newPassword],
              ),
            ]),
            div(classes: 'edit-profile__row-action', <Component>[
              BlocSignalSelector<EditProfileBloc, EditProfileState, bool>(
                selector: (EditProfileState state) => state.passwordStatus.isLoading,
                builder: (BuildContext context, bool isSaving) => AppButton(
                  label: isSaving ? 'Saving…' : 'Update',
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.field,
                  type: ButtonType.submit,
                  onPressed: isSaving ? null : _submitsEnclosingForm,
                ),
              ),
            ]),
          ]),
          BlocSignalSelector<EditProfileBloc, EditProfileState, Failure?>(
            selector: (EditProfileState state) => state.passwordFailure,
            builder: (BuildContext context, Failure? failure) =>
                _FailureLine(message: failure == null ? null : _profileMessage(failure)),
          ),
        ]),
      ]),
    );
  }
}

final class _SubscriptionSection extends StatelessComponent {
  const _SubscriptionSection();

  @override
  Component build(BuildContext context) {
    return BlocSignalSelector<AccountBloc, AccountState, SubscriptionEntity?>(
      selector: (AccountState state) => state.account?.subscription,
      builder: (BuildContext context, SubscriptionEntity? subscription) {
        if (subscription == null) return const Component.empty();
        final bool isPro = subscription.entitlements.isPro;
        return div(classes: 'edit-profile__section', <Component>[
          div(classes: 'edit-profile__subscription-title', <Component>[
            const h2(classes: 'edit-profile__section-title', <Component>[Component.text('Subscription')]),
            if (subscription.isTestMode) const _TestModeBadge(),
          ]),
          div(classes: 'edit-profile__plan', <Component>[
            _PlanCard(subscription: subscription),
            BlocSignalSelector<SubscriptionBloc, SubscriptionState, Failure?>(
              selector: (SubscriptionState state) => state.portalFailure,
              builder: (BuildContext context, Failure? failure) => _FailureLine(message: failure?.billingMessage),
            ),
          ]),
          p(classes: 'edit-profile__plan-note', <Component>[
            Component.text(
              isPro
                  ? 'Change plan, update the card or cancel in the Stripe '
                        'portal. If you cancel, Pro stays until the end of the '
                        'paid period. Your matches and stats are never deleted.'
                  : 'Free: 5 ranked matches a day, latest 10 matches, basic '
                        'statistics. Pro never changes Elo.',
            ),
          ]),
        ]);
      },
    );
  }
}

final class _PlanCard extends StatelessComponent {
  const _PlanCard({required this.subscription});

  final SubscriptionEntity subscription;

  /// `Renews Nov 14, 2027 · $47.99 / year`.
  String _details(List<SubscriptionPlanEntity> plans) {
    final DateTime? end = subscription.currentPeriodEnd;
    SubscriptionPlanEntity? plan;
    for (final SubscriptionPlanEntity candidate in plans) {
      if (candidate.code == subscription.planCode) plan = candidate;
    }
    final String? price = plan == null || plan.code == PlanCode.free
        ? null
        : '${DisplayFormatters.money(plan.amountCents, plan.currency)} / '
              '${plan.interval == PlanInterval.year ? 'year' : 'month'}';
    final String? period = end == null
        ? null
        : subscription.cancelAtPeriodEnd
        ? 'Pro until ${DisplayFormatters.date(end)}, then Free'
        : 'Renews ${DisplayFormatters.date(end)}';
    final List<String> parts = <String>[?period, ?price];
    if (parts.isEmpty) return 'No paid plan';
    return parts.join(' · ');
  }

  @override
  Component build(BuildContext context) {
    final bool hasProvider = subscription.status != SubscriptionStatus.none;
    final bool isActive = subscription.status == SubscriptionStatus.active;
    return div(classes: 'edit-profile__plan-card', <Component>[
      div(classes: 'edit-profile__plan-text', <Component>[
        p(classes: 'edit-profile__plan-name', <Component>[
          span(<Component>[Component.text(subscription.planCode.label)]),
          if (hasProvider) ...<Component>[
            const span(<Component>[Component.text(' · ')]),
            span(styles: Styles(color: isActive ? AppColors.success : AppColors.danger), <Component>[
              Component.text(subscription.status.label),
            ]),
          ],
        ]),
        BlocSignalSelector<SubscriptionBloc, SubscriptionState, List<SubscriptionPlanEntity>>(
          selector: (SubscriptionState state) => state.plans,
          builder: (BuildContext context, List<SubscriptionPlanEntity> plans) => p(
            classes: 'edit-profile__plan-details',
            <Component>[Component.text(_details(plans))],
          ),
        ),
      ]),
      if (hasProvider)
        BlocSignalSelector<SubscriptionBloc, SubscriptionState, bool>(
          selector: (SubscriptionState state) => state.portalStatus.isLoading,
          builder: (BuildContext context, bool isOpening) => AppButton(
            label: isOpening ? 'Opening…' : 'Manage in Stripe',
            variant: AppButtonVariant.outline,
            size: AppButtonSize.small,
            trailingIcon: AppSvgIcon(
              AppIcons.external,
              width: 12,
              height: 12,
              color: AppButton.foregroundOf(AppButtonVariant.outline, enabled: !isOpening),
            ),
            onPressed: isOpening
                ? null
                : () => context.read<SubscriptionBloc>().add(const SubscriptionPortalRequested()),
          ),
        )
      else
        AppButton(
          label: 'See Pro plans',
          variant: AppButtonVariant.dark,
          size: AppButtonSize.small,
          onPressed: context.goPro,
        ),
    ]);
  }
}

/// "TEST MODE": Stripe runs with test cards only.
final class _TestModeBadge extends StatelessComponent {
  const _TestModeBadge();

  @override
  Component build(BuildContext context) {
    return const span(classes: 'edit-profile__test-badge', <Component>[Component.text('TEST MODE')]);
  }
}

@css
List<StyleRule> get editProfileScreenStyles => <StyleRule>[
  css('.edit-profile').styles(
    display: Display.flex,
    padding: const Padding.symmetric(horizontal: Unit.pixels(64), vertical: Unit.pixels(44)),
    alignItems: AlignItems.start,
    gap: const Gap.column(Unit.pixels(80)),
  ),
  css('.edit-profile__side').styles(
    display: Display.flex,
    width: const Unit.pixels(300),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(20)),
    flex: const Flex(shrink: 0),
  ),
  css('.edit-profile__title').combine(AppTextStyles.displayXs),
  css('.edit-profile__identity-empty').styles(height: const Unit.pixels(56)),
  css('.edit-profile__identity').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(14)),
  ),
  css('.edit-profile__identity-text').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(2)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.edit-profile__identity-name-row').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(8)),
  ),
  css('.edit-profile__identity-name, .edit-profile__identity-meta').styles(
    minWidth: Unit.zero,
    overflow: Overflow.hidden,
    textOverflow: TextOverflow.ellipsis,
    whiteSpace: WhiteSpace.noWrap,
  ),
  css('.edit-profile__identity-name')
      .combine(AppTextStyles.bodyLg)
      .combine(const Styles(fontSize: Unit.pixels(16), fontWeight: FontWeight.w600, lineHeight: Unit.pixels(20))),
  css('.edit-profile__identity-meta').combine(AppTextStyles.bodySm).combine(const Styles(color: AppColors.muted)),
  css('.edit-profile__main').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    maxWidth: const Unit.pixels(720),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(36)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.edit-profile__block').styles(
    padding: const Padding.only(bottom: Unit.pixels(32)),
    border: const Border.only(
      bottom: BorderSide(color: AppColors.divider, width: Unit.pixels(1)),
    ),
  ),
  css('.edit-profile__section').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(16)),
  ),
  css('.edit-profile__section-heading').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(4)),
  ),
  css('.edit-profile__section-title').combine(AppTextStyles.titleMd),
  css('.edit-profile__section-note')
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.muted, lineHeight: Unit.pixels(18))),
  css('.edit-profile__password').styles(display: Display.flex, flexDirection: FlexDirection.column),
  css('.edit-profile__row').styles(
    display: Display.flex,
    alignItems: AlignItems.start,
    gap: const Gap.column(Unit.pixels(16)),
  ),
  css('.edit-profile__field').styles(
    minWidth: Unit.zero,
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  // Label height plus its gap above a 48 px input, so a button lines up
  // with the input box rather than the label.
  css('.edit-profile__row-action').styles(
    padding: const Padding.only(top: Unit.pixels(22)),
    flex: const Flex(shrink: 0),
  ),
  css('.edit-profile__hint').combine(AppTextStyles.bodySm).combine(const Styles(color: AppColors.muted)),
  css('.edit-profile__failure').styles(padding: const Padding.only(top: Unit.pixels(10))),
  css('.edit-profile__subscription-title').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(10)),
  ),
  css('.edit-profile__plan').styles(display: Display.flex, flexDirection: FlexDirection.column),
  css('.edit-profile__plan-card').styles(
    display: Display.flex,
    padding: const Padding.all(Unit.pixels(20)),
    border: Border.all(color: AppColors.border, width: const Unit.pixels(1)),
    radius: const BorderRadius.circular(Unit.pixels(14)),
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(16)),
  ),
  css('.edit-profile__plan-text').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(4)),
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.edit-profile__plan-name').combine(AppTextStyles.buttonLg).combine(const Styles(lineHeight: Unit.pixels(20))),
  css('.edit-profile__plan-details')
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.muted, lineHeight: Unit.pixels(18))),
  css('.edit-profile__plan-note')
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.muted, lineHeight: Unit.pixels(19))),
  css('.edit-profile__test-badge')
      .styles(
        padding: const Padding.symmetric(horizontal: Unit.pixels(6), vertical: Unit.pixels(2)),
        radius: const BorderRadius.circular(Unit.pixels(4)),
      )
      .combine(AppTextStyles.outcome)
      .combine(
        const Styles(
          color: AppColors.pro,
          fontSize: Unit.pixels(10),
          fontWeight: FontWeight.w700,
          letterSpacing: Unit.em(0.06),
          lineHeight: Unit.pixels(12),
          backgroundColor: AppColors.proInk,
        ),
      ),
];
