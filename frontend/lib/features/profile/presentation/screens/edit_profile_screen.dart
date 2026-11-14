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
import 'package:skill_battles/core/domain/entity/subscription_status.dart';
import 'package:skill_battles/core/domain/entity/user_entity.dart';
import 'package:skill_battles/core/domain/usecases/generate_id_usecase.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/utils/open_external_url.dart';
import 'package:skill_battles/core/presentation/widgets/app_avatar.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_field.dart';
import 'package:skill_battles/core/presentation/widgets/pro_badge.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/core/utils/extensions/go_router_extension.dart';
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
final class EditProfileScreen extends StatefulWidget
    implements GoRouterWrapper {
  const EditProfileScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<EditProfileBloc>(
          create: (_) => EditProfileBloc(
            updateProfile: dependencies.getDep<UpdateProfileUsecase>(),
          ),
        ),
        BlocProvider<SubscriptionBloc>(
          create: (_) => SubscriptionBloc(
            getPlans: dependencies.getDep<GetPlansUsecase>(),
            getSubscription: dependencies.getDep<GetSubscriptionUsecase>(),
            startCheckout: dependencies.getDep<StartCheckoutUsecase>(),
            openPortal: dependencies.getDep<OpenPortalUsecase>(),
            generateId: dependencies.getDep<GenerateIdUsecase>(),
          )..add(const SubscriptionStarted()),
        ),
      ],
      child: this,
    );
  }

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

/// Sections of the page, in order; the left menu scrolls to them.
enum _Section {
  profile('Profile'),
  password('Password'),
  subscription('Subscription');

  const _Section(this.label);

  final String label;
}

final class _EditProfileScreenState extends State<EditProfileScreen> {
  late final GlobalKey<FormState> _nicknameForm;
  late final GlobalKey<FormState> _passwordForm;
  late final Map<_Section, GlobalKey> _sectionKeys;
  late final TextEditingController _nickname;
  late final TextEditingController _email;
  late final TextEditingController _current;
  late final TextEditingController _next;
  late final FocusNode _currentFocus;
  late final FocusNode _nextFocus;
  late final ValueNotifier<_Section> _section;

  @override
  void initState() {
    super.initState();
    _nicknameForm = GlobalKey<FormState>();
    _passwordForm = GlobalKey<FormState>();
    _sectionKeys = <_Section, GlobalKey>{
      for (final _Section section in _Section.values) section: GlobalKey(),
    };
    final UserEntity? user = context.read<AccountBloc>().state.account?.user;
    _nickname = TextEditingController(text: user?.nickname ?? '');
    _email = TextEditingController(text: user?.email ?? '');
    _current = TextEditingController();
    _next = TextEditingController();
    _currentFocus = FocusNode();
    _nextFocus = FocusNode();
    _section = ValueNotifier<_Section>(_Section.profile);
  }

  @override
  void dispose() {
    _nickname.dispose();
    _email.dispose();
    _current.dispose();
    _next.dispose();
    _currentFocus.dispose();
    _nextFocus.dispose();
    _section.dispose();
    super.dispose();
  }

  void _saveNickname() {
    FocusScope.of(context).unfocus();
    if (!(_nicknameForm.currentState?.validate() ?? false)) return;
    context.read<EditProfileBloc>().add(
      EditProfileNicknameSubmitted(
        UpdateProfileParamsEntity(nickname: _nickname.text),
      ),
    );
  }

  void _savePassword() {
    FocusScope.of(context).unfocus();
    if (!(_passwordForm.currentState?.validate() ?? false)) return;
    context.read<EditProfileBloc>().add(
      EditProfilePasswordSubmitted(
        UpdateProfileParamsEntity(
          currentPassword: _current.text,
          newPassword: _next.text,
        ),
      ),
    );
  }

  void _showSection(_Section section) {
    _section.value = section;
    final BuildContext? target = _sectionKeys[section]?.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  /// The account arrives after the screen opened (a reload): fill the
  /// fields once, without touching what the user already typed.
  void _onUserLoaded(UserEntity user) {
    if (_nickname.text.isEmpty) _nickname.text = user.nickname;
    _email.text = user.email;
  }

  @override
  Widget build(BuildContext context) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    return MultiBlocListener(
      listeners: <BlocListener<dynamic, dynamic>>[
        BlocListener<AccountBloc, AccountState>(
          listenWhen: (AccountState previous, AccountState current) =>
              previous.account?.user != current.account?.user &&
              current.account != null,
          listener: (BuildContext context, AccountState state) =>
              _onUserLoaded(state.account!.user),
        ),
        BlocListener<EditProfileBloc, EditProfileState>(
          listenWhen: (EditProfileState previous, EditProfileState current) =>
              previous.nicknameStatus != current.nicknameStatus &&
              current.nicknameStatus.isSuccess,
          listener: (BuildContext context, EditProfileState state) {
            context.read<AccountBloc>().add(const AccountRefreshRequested());
            messenger.showSnackBar(
              const SnackBar(content: Text('Nickname saved')),
            );
          },
        ),
        BlocListener<EditProfileBloc, EditProfileState>(
          listenWhen: (EditProfileState previous, EditProfileState current) =>
              previous.passwordStatus != current.passwordStatus &&
              current.passwordStatus.isSuccess,
          // The session is already cleared; the router opens log-in.
          listener: (BuildContext context, EditProfileState state) =>
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Password changed. Log in with the new one.'),
                ),
              ),
        ),
        BlocListener<SubscriptionBloc, SubscriptionState>(
          listenWhen: (SubscriptionState previous, SubscriptionState current) =>
              previous.externalUrlSerial != current.externalUrlSerial &&
              current.externalUrl != null,
          listener: (BuildContext context, SubscriptionState state) async {
            final bool opened = await openExternalUrl(
              context,
              state.externalUrl!,
            );
            if (!opened) {
              messenger.showSnackBar(
                const SnackBar(content: Text("Couldn't open Stripe.")),
              );
            }
          },
        ),
      ],
      child: AppDesktopViewport(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 44),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 80,
            children: <Widget>[
              SizedBox(
                width: 300,
                child: ValueListenableBuilder<_Section>(
                  valueListenable: _section,
                  builder: (BuildContext context, _Section section, _) =>
                      _SideColumn(selected: section, onSelected: _showSection),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 36,
                      children: <Widget>[
                        _SectionBlock(
                          key: _sectionKeys[_Section.profile],
                          child: _ProfileSection(
                            formKey: _nicknameForm,
                            nickname: _nickname,
                            email: _email,
                            onSave: _saveNickname,
                          ),
                        ),
                        _SectionBlock(
                          key: _sectionKeys[_Section.password],
                          child: _PasswordSection(
                            formKey: _passwordForm,
                            current: _current,
                            next: _next,
                            currentFocus: _currentFocus,
                            nextFocus: _nextFocus,
                            onSave: _savePassword,
                          ),
                        ),
                        KeyedSubtree(
                          key: _sectionKeys[_Section.subscription],
                          child: const _SubscriptionSection(),
                        ),
                      ],
                    ),
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

/// Title, identity and the section menu.
final class _SideColumn extends StatelessWidget {
  const _SideColumn({required this.selected, required this.onSelected});

  final _Section selected;
  final ValueChanged<_Section> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 20,
      children: <Widget>[
        const Text('Account', style: AppTextStyles.displayXs),
        const _Identity(),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 2,
            children: <Widget>[
              for (final _Section section in _Section.values)
                _MenuItem(
                  label: section.label,
                  isSelected: section == selected,
                  onTap: () => onSelected(section),
                ),
              _MenuItem(
                label: 'Log out',
                isSelected: false,
                isDanger: true,
                onTap: () => context.read<AccountBloc>().add(
                  const AccountLogoutRequested(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _Identity extends StatelessWidget {
  const _Identity();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountBloc, AccountState>(
      buildWhen: (AccountState previous, AccountState current) =>
          previous.account?.user != current.account?.user ||
          previous.isPro != current.isPro,
      builder: (BuildContext context, AccountState state) {
        final UserEntity? user = state.account?.user;
        if (user == null) return const SizedBox(height: 56);
        return Row(
          spacing: 14,
          children: <Widget>[
            AppAvatar(nickname: user.nickname, size: AppAvatarSize.settings),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: <Widget>[
                  Row(
                    spacing: 8,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          user.nickname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyLg.copyWith(
                            fontSize: 16,
                            height: 20 / 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (state.isPro) const ProBadge(tone: ProBadgeTone.amber),
                    ],
                  ),
                  Text(
                    '${user.email} · since '
                    '${DisplayFormatters.monthYear(user.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

final class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isDanger = false,
  });

  final String label;
  final bool isSelected;
  final bool isDanger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(8);
    return AppTappable(
      onTap: onTap,
      isSelected: isSelected,
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : null,
          borderRadius: radius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isDanger
                  ? AppColors.danger
                  : isSelected
                  ? AppColors.ink
                  : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

/// A server error under a block, or nothing.
final class _FailureLine extends StatelessWidget {
  const _FailureLine({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final String? message = this.message;
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: AppInlineError(message),
    );
  }
}

/// A settings block with a line and 32 px below it.
final class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Padding(padding: const EdgeInsets.only(bottom: 32), child: child),
    );
  }
}

/// Label height plus its gap above a 48 px input, so a button lines up with
/// the input box rather than the label.
const double _fieldLabelOffset = 22;

final class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.formKey,
    required this.nickname,
    required this.email,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nickname;
  final TextEditingController email;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: <Widget>[
          const Text('Profile', style: AppTextStyles.titleMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: <Widget>[
              Expanded(
                child: AppTextField(
                  label: 'Nickname',
                  controller: nickname,
                  validator: FormValidators.nickname,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => onSave(),
                ),
              ),
              Expanded(
                child: AppTextField(
                  label: 'Email',
                  controller: email,
                  enabled: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: _fieldLabelOffset),
                child: BlocSelector<EditProfileBloc, EditProfileState, bool>(
                  selector: (EditProfileState state) =>
                      state.nicknameStatus.isLoading,
                  builder: (BuildContext context, bool isSaving) => AppButton(
                    label: isSaving ? 'Saving…' : 'Save',
                    variant: AppButtonVariant.dark,
                    size: AppButtonSize.field,
                    onPressed: isSaving ? null : onSave,
                  ),
                ),
              ),
            ],
          ),
          Text(
            "3–24 letters, numbers, _ or -. Email can't be changed.",
            style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
          ),
          BlocSelector<EditProfileBloc, EditProfileState, Failure?>(
            selector: (EditProfileState state) => state.nicknameFailure,
            builder: (BuildContext context, Failure? failure) => failure == null
                ? const SizedBox.shrink()
                : AppInlineError(_profileMessage(failure)),
          ),
        ],
      ),
    );
  }
}

final class _PasswordSection extends StatelessWidget {
  const _PasswordSection({
    required this.formKey,
    required this.current,
    required this.next,
    required this.currentFocus,
    required this.nextFocus,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController current;
  final TextEditingController next;
  final FocusNode currentFocus;
  final FocusNode nextFocus;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: <Widget>[
              const Text('Change password', style: AppTextStyles.titleMd),
              Text(
                "You'll be signed out everywhere and asked to log in again.",
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.muted,
                  height: 18 / 13,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: <Widget>[
                  Expanded(
                    child: AppTextField(
                      label: 'Current password',
                      controller: current,
                      focusNode: currentFocus,
                      validator: FormValidators.currentPassword,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.password],
                      onFieldSubmitted: (_) => nextFocus.requestFocus(),
                    ),
                  ),
                  Expanded(
                    child: AppTextField(
                      label: 'New password',
                      controller: next,
                      focusNode: nextFocus,
                      validator: FormValidators.password,
                      hintText: '8–72 characters',
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const <String>[AutofillHints.newPassword],
                      onFieldSubmitted: (_) => onSave(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: _fieldLabelOffset),
                    child:
                        BlocSelector<EditProfileBloc, EditProfileState, bool>(
                          selector: (EditProfileState state) =>
                              state.passwordStatus.isLoading,
                          builder: (BuildContext context, bool isSaving) =>
                              AppButton(
                                label: isSaving ? 'Saving…' : 'Update',
                                variant: AppButtonVariant.outline,
                                size: AppButtonSize.field,
                                onPressed: isSaving ? null : onSave,
                              ),
                        ),
                  ),
                ],
              ),
              BlocSelector<EditProfileBloc, EditProfileState, Failure?>(
                selector: (EditProfileState state) => state.passwordFailure,
                builder: (BuildContext context, Failure? failure) =>
                    _FailureLine(
                      message: failure == null
                          ? null
                          : _profileMessage(failure),
                    ),
              ),
            ],
          ),
          BlocSelector<EditProfileBloc, EditProfileState, Failure?>(
            selector: (EditProfileState state) => state.passwordFailure,
            builder: (BuildContext context, Failure? failure) => failure == null
                ? const SizedBox.shrink()
                : AppInlineError(_profileMessage(failure)),
          ),
        ],
      ),
    );
  }
}

final class _SubscriptionSection extends StatelessWidget {
  const _SubscriptionSection();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AccountBloc, AccountState, SubscriptionEntity?>(
      selector: (AccountState state) => state.account?.subscription,
      builder: (BuildContext context, SubscriptionEntity? subscription) {
        if (subscription == null) return const SizedBox.shrink();
        final bool isPro = subscription.entitlements.isPro;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: <Widget>[
            Row(
              spacing: 10,
              children: <Widget>[
                const Text('Subscription', style: AppTextStyles.titleMd),
                if (subscription.isTestMode) const _TestModeBadge(),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _PlanCard(subscription: subscription),
                BlocSelector<SubscriptionBloc, SubscriptionState, Failure?>(
                  selector: (SubscriptionState state) => state.portalFailure,
                  builder: (BuildContext context, Failure? failure) =>
                      _FailureLine(message: failure?.billingMessage),
                ),
              ],
            ),
            Text(
              isPro
                  ? 'Change plan, update the card or cancel in the Stripe '
                        'portal. If you cancel, Pro stays until the end of the '
                        'paid period. Your matches and stats are never deleted.'
                  : 'Free: 5 ranked matches a day, latest 10 matches, basic '
                        'statistics. Pro never changes Elo.',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.muted,
                height: 19 / 13,
              ),
            ),
          ],
        );
      },
    );
  }
}

final class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.subscription});

  final SubscriptionEntity subscription;

  @override
  Widget build(BuildContext context) {
    final bool hasProvider = subscription.status != SubscriptionStatus.none;
    final bool isActive = subscription.status == SubscriptionStatus.active;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          spacing: 16,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: <Widget>[
                  Text.rich(
                    TextSpan(
                      style: AppTextStyles.buttonLg.copyWith(height: 20 / 15),
                      children: <InlineSpan>[
                        TextSpan(text: subscription.planCode.label),
                        if (hasProvider) ...<InlineSpan>[
                          const TextSpan(text: ' · '),
                          TextSpan(
                            text: subscription.status.label,
                            style: TextStyle(
                              color: isActive
                                  ? AppColors.success
                                  : AppColors.danger,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  BlocSelector<
                    SubscriptionBloc,
                    SubscriptionState,
                    List<SubscriptionPlanEntity>
                  >(
                    selector: (SubscriptionState state) => state.plans,
                    builder:
                        (
                          BuildContext context,
                          List<SubscriptionPlanEntity> plans,
                        ) => Text(
                          _details(plans),
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.muted,
                            height: 18 / 13,
                          ),
                        ),
                  ),
                ],
              ),
            ),
            if (hasProvider)
              BlocSelector<SubscriptionBloc, SubscriptionState, bool>(
                selector: (SubscriptionState state) =>
                    state.portalStatus.isLoading,
                builder: (BuildContext context, bool isOpening) => AppButton(
                  label: isOpening ? 'Opening…' : 'Manage in Stripe',
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.small,
                  trailingIcon: const AppSvgIcon(
                    AppIcons.external,
                    width: 12,
                    height: 12,
                  ),
                  onPressed: isOpening
                      ? null
                      : () => context.read<SubscriptionBloc>().add(
                          const SubscriptionPortalRequested(),
                        ),
                ),
              )
            else
              AppButton(
                label: 'See Pro plans',
                variant: AppButtonVariant.dark,
                size: AppButtonSize.small,
                onPressed: context.goPro,
              ),
          ],
        ),
      ),
    );
  }

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
}

/// "TEST MODE": Stripe runs with test cards only.
final class _TestModeBadge extends StatelessWidget {
  const _TestModeBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.proInk,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          'TEST MODE',
          style: AppTextStyles.outcome.copyWith(
            fontSize: 10,
            height: 12 / 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.06 * 10,
            color: AppColors.pro,
          ),
        ),
      ),
    );
  }
}
