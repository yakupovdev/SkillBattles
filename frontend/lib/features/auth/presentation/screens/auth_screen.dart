import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/router/app_routes.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_dropdown_field.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_logo.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_segmented_control.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_field.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_link.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/extensions/go_router_extension.dart';
import 'package:skill_battles/core/utils/form_validators.dart';
import 'package:skill_battles/features/auth/domain/entity/age_check_params_entity.dart';
import 'package:skill_battles/features/auth/domain/entity/age_check_result.dart';
import 'package:skill_battles/features/auth/domain/entity/login_params_entity.dart';
import 'package:skill_battles/features/auth/domain/entity/register_params_entity.dart';
import 'package:skill_battles/features/auth/domain/usecases/check_age_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/login_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/register_usecase.dart';
import 'package:skill_battles/features/auth/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:skill_battles/features/auth/presentation/widgets/auth_failure_message.dart';

/// Sign-up / log-in (Paper: "01 Auth", "10 Sign up — Age gate",
/// "11 Sign up — Age restricted").
///
/// Sign-up first asks neutrally for the month and year of birth (and the
/// day only when the user turns 13 this ET month), then the credentials.
/// The server re-checks the age and has the final word.
final class AuthScreen extends StatelessWidget implements GoRouterWrapper {
  const AuthScreen({super.key});

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<AuthBloc>(
      create: (_) => AuthBloc(
        checkAge: dependencies.getDep<CheckAgeUsecase>(),
        register: dependencies.getDep<RegisterUsecase>(),
        login: dependencies.getDep<LoginUsecase>(),
      ),
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const AuthLayout(child: _AuthForm());
  }
}

/// The blue hero half and a form half; shared by the auth screens.
final class AuthLayout extends StatelessWidget {
  const AuthLayout({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double windowHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: AppDesktopViewport(
        fullBleed: true,
        // The blue half is painted behind the content, so both halves span
        // the full window width and page height.
        child: Stack(
          children: <Widget>[
            const Positioned.fill(
              child: Row(
                children: <Widget>[
                  Expanded(child: _HeroBackground()),
                  Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: _HeroContent(minHeight: windowHeight)),
                Expanded(
                  child: _FormSide(minHeight: windowHeight, child: child),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _HeroBackground extends StatelessWidget {
  const _HeroBackground();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.primary,
      child: ClipRect(
        child: Stack(
          children: <Widget>[
            Positioned(
              right: -120,
              top: 120,
              child: _Ring(size: 420, color: AppColors.onPrimaryRingOuter),
            ),
            Positioned(
              right: -40,
              top: 200,
              child: _Ring(size: 260, color: AppColors.onPrimaryRingInner),
            ),
          ],
        ),
      ),
    );
  }
}

final class _HeroContent extends StatelessWidget {
  const _HeroContent({required this.minHeight});

  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 56, horizontal: 64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AppLogo(variant: AppLogoVariant.onPrimary),
            _HeroCopy(),
            _HeroCaptions(),
          ],
        ),
      ),
    );
  }
}

final class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
      ),
    );
  }
}

final class _HeroCopy extends StatelessWidget {
  const _HeroCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 24,
      children: <Widget>[
        Text.rich(
          TextSpan(
            style: AppTextStyles.displayLg.copyWith(color: AppColors.white),
            children: const <InlineSpan>[
              TextSpan(text: 'Five minutes.\nOne opponent.\n'),
              TextSpan(
                text: 'Sharper mind.',
                style: TextStyle(color: AppColors.accent),
              ),
            ],
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Text(
            'Live one-on-one battles in SAT Math and Reading & Writing. Same '
            'questions, same clock — learn from every round.',
            style: AppTextStyles.bodyXl.copyWith(
              color: AppColors.onPrimaryBody,
            ),
          ),
        ),
      ],
    );
  }
}

final class _HeroCaptions extends StatelessWidget {
  const _HeroCaptions();

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTextStyles.monoBodySm.copyWith(
      letterSpacing: 0.04 * 13,
      color: AppColors.onPrimaryMuted,
    );

    return Wrap(
      spacing: 32,
      runSpacing: 8,
      children: <Widget>[
        Text('SAT MATH · 5 ROUNDS', style: style),
        Text('SAT R&W · 5 ROUNDS', style: style),
        Text('ELO RANKED · 27 TIERS', style: style),
      ],
    );
  }
}

final class _FormSide extends StatelessWidget {
  const _FormSide({required this.minHeight, required this.child});

  final double minHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: child,
          ),
        ),
      ),
    );
  }
}

enum _AuthTab { signUp, logIn }

final class _AuthForm extends StatefulWidget {
  const _AuthForm();

  @override
  State<_AuthForm> createState() => _AuthFormState();
}

final class _AuthFormState extends State<_AuthForm> {
  late final GlobalKey<FormState> _ageFormKey;
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _dayController;
  late final TextEditingController _nicknameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final FocusNode _dayFocus;
  late final FocusNode _nicknameFocus;
  late final FocusNode _emailFocus;
  late final FocusNode _passwordFocus;
  late _AuthTab _tab;
  late int? _month;
  late int? _year;

  bool get _isSignUp => _tab == _AuthTab.signUp;

  @override
  void initState() {
    super.initState();
    _ageFormKey = GlobalKey<FormState>();
    _formKey = GlobalKey<FormState>();
    _dayController = TextEditingController();
    _nicknameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _dayFocus = FocusNode();
    _nicknameFocus = FocusNode();
    _emailFocus = FocusNode();
    _passwordFocus = FocusNode();
    _tab = _AuthTab.logIn;
    _month = null;
    _year = null;
  }

  @override
  void dispose() {
    _dayController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dayFocus.dispose();
    _nicknameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onTabSelected(_AuthTab tab) {
    if (tab == _tab) return;
    setState(() => _tab = tab);
    context.read<AuthBloc>().add(const AuthFieldEdited());
  }

  AgeCheckParamsEntity? _birth({required bool withDay}) {
    final int? year = _year;
    final int? month = _month;
    if (year == null || month == null) return null;
    return AgeCheckParamsEntity(
      birthYear: year,
      birthMonth: month,
      birthDay: withDay ? int.tryParse(_dayController.text.trim()) : null,
    );
  }

  bool get _needsDay =>
      context.read<AuthBloc>().state.ageResult == AgeCheckResult.needsDay;

  void _submitAge() {
    FocusScope.of(context).unfocus();
    if (!(_ageFormKey.currentState?.validate() ?? false)) return;
    final AgeCheckParamsEntity? birth = _birth(withDay: _needsDay);
    if (birth == null) return;
    context.read<AuthBloc>().add(AuthAgeSubmitted(birth));
  }

  void _onBirthEdited() => context.read<AuthBloc>().add(const AuthAgeEdited());

  /// "Back to start" after an age refusal: nothing typed is kept.
  void _restart() {
    setState(() {
      _month = null;
      _year = null;
    });
    _dayController.clear();
    _onBirthEdited();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final AuthBloc bloc = context.read<AuthBloc>();
    if (!_isSignUp) {
      bloc.add(
        AuthLoginSubmitted(
          LoginParamsEntity(
            email: _emailController.text,
            password: _passwordController.text,
          ),
        ),
      );
      return;
    }
    final AgeCheckParamsEntity? birth = _birth(
      withDay: _dayController.text.trim().isNotEmpty,
    );
    if (birth == null) return;
    bloc.add(
      AuthRegisterSubmitted(
        RegisterParamsEntity(
          email: _emailController.text,
          password: _passwordController.text,
          nickname: _nicknameController.text,
          birthYear: birth.birthYear,
          birthMonth: birth.birthMonth,
          birthDay: birth.birthDay,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (AuthState previous, AuthState current) =>
          previous.ageResult != current.ageResult ||
          previous.submitStatus != current.submitStatus ||
          previous.failure != current.failure,
      builder: (BuildContext context, AuthState state) {
        if (_isSignUp && state.ageResult == AgeCheckResult.restricted) {
          return _RestrictedStep(onRestart: _restart);
        }
        if (_isSignUp && !state.canEnterCredentials) {
          return _AgeStep(
            formKey: _ageFormKey,
            dayController: _dayController,
            dayFocus: _dayFocus,
            month: _month,
            year: _year,
            onMonthChanged: (int? month) {
              setState(() => _month = month);
              _onBirthEdited();
            },
            onYearChanged: (int? year) {
              setState(() => _year = year);
              _onBirthEdited();
            },
            onDayEdited: _onBirthEdited,
            result: state.ageResult,
            isSubmitting: state.submitStatus.isLoading,
            onSubmit: _submitAge,
            onLogIn: () => _onTabSelected(_AuthTab.logIn),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 32,
          children: <Widget>[
            AppSegmentedControl<_AuthTab>(
              segments: const <AppSegment<_AuthTab>>[
                AppSegment<_AuthTab>(
                  value: _AuthTab.signUp,
                  label: 'Create account',
                ),
                AppSegment<_AuthTab>(value: _AuthTab.logIn, label: 'Log in'),
              ],
              selected: _tab,
              onSelected: _onTabSelected,
            ),
            _CredentialsStep(
              formKey: _formKey,
              isSignUp: _isSignUp,
              nicknameController: _nicknameController,
              emailController: _emailController,
              passwordController: _passwordController,
              nicknameFocus: _nicknameFocus,
              emailFocus: _emailFocus,
              passwordFocus: _passwordFocus,
              state: state,
              onSubmit: _submit,
              onEdited: () =>
                  context.read<AuthBloc>().add(const AuthFieldEdited()),
              onChangeBirth: _onBirthEdited,
            ),
          ],
        );
      },
    );
  }
}

/// Eyebrow, title and muted subtitle at the top of every auth form.
final class AuthHeading extends StatelessWidget {
  const AuthHeading({
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.gap = 8,
    super.key,
  });

  final String title;
  final String subtitle;
  final String? eyebrow;

  /// Space between the lines; 12 on the v0.3 artboards.
  final double gap;

  @override
  Widget build(BuildContext context) {
    final String? eyebrow = this.eyebrow;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: gap,
      children: <Widget>[
        if (eyebrow != null) AppEyebrow(eyebrow),
        Text(title, style: AppTextStyles.headlineLg),
        Text(
          subtitle,
          style: AppTextStyles.bodyLg.copyWith(
            height: 22 / 15,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

/// "Already have an account? Log in" — muted text with a blue link.
final class _FooterLink extends StatelessWidget {
  const _FooterLink({
    required this.text,
    required this.label,
    required this.onPressed,
  });

  final String text;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (text.isNotEmpty)
          Text(
            '$text ',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
          ),
        AppTextLink(
          label: label,
          style: AppTextStyles.bodySm.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
          onPressed: onPressed,
        ),
      ],
    );
  }
}

final class _AgeStep extends StatelessWidget {
  const _AgeStep({
    required this.formKey,
    required this.dayController,
    required this.dayFocus,
    required this.month,
    required this.year,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.onDayEdited,
    required this.result,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onLogIn,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController dayController;
  final FocusNode dayFocus;
  final int? month;
  final int? year;
  final ValueChanged<int?> onMonthChanged;
  final ValueChanged<int?> onYearChanged;
  final VoidCallback onDayEdited;
  final AgeCheckResult? result;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final VoidCallback onLogIn;

  static const List<String> _months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// The last 100 years, newest first.
  static List<int> _years() {
    final int current = DateTime.now().year;
    return List<int>.generate(101, (int i) => current - i);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 32,
        children: <Widget>[
          const AuthHeading(
            eyebrow: 'Step 1 of 2 — About you',
            gap: 12,
            title: 'When were you born?',
            subtitle:
                "We only use this to confirm eligibility. It's never shown "
                'to opponents or on leaderboards.',
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 20,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: <Widget>[
                  Expanded(
                    flex: 14,
                    child: AppDropdownField<int>(
                      label: 'Month',
                      hintText: 'Month',
                      items: List<int>.generate(12, (int i) => i + 1),
                      labelOf: (int value) => _months[value - 1],
                      value: month,
                      validator: FormValidators.birthMonth,
                      onChanged: onMonthChanged,
                    ),
                  ),
                  Expanded(
                    flex: 10,
                    child: AppDropdownField<int>(
                      label: 'Year',
                      hintText: 'YYYY',
                      items: _years(),
                      labelOf: (int value) => '$value',
                      value: year,
                      style: AppTextStyles.bodyLg.copyWith(
                        fontFamily: AppFonts.mono,
                      ),
                      validator: (int? value) =>
                          FormValidators.birthYear(value?.toString()),
                      onChanged: onYearChanged,
                    ),
                  ),
                ],
              ),
              if (result == AgeCheckResult.needsDay)
                _DayPanel(
                  controller: dayController,
                  focusNode: dayFocus,
                  onEdited: onDayEdited,
                  onSubmit: onSubmit,
                ),
              if (result == AgeCheckResult.invalidDate)
                const AppInlineError('Enter a real date in the past.'),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: <Widget>[
              AppButton(
                label: 'Continue',
                variant: AppButtonVariant.dark,
                expand: true,
                trailingIcon: const AppSvgIcon(
                  AppIcons.arrowSmall,
                  width: 16,
                  height: 16,
                ),
                onPressed: isSubmitting ? null : onSubmit,
              ),
              _FooterLink(
                text: 'Already have an account?',
                label: 'Log in',
                onPressed: onLogIn,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The blue note that asks for the day when the user turns 13 this month.
final class _DayPanel extends StatelessWidget {
  const _DayPanel({
    required this.controller,
    required this.focusNode,
    required this.onEdited,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onEdited;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final TextStyle labelStyle = AppTextStyles.bodySm.copyWith(
      fontWeight: FontWeight.w500,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLine),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: <Widget>[
            Text(
              'Please add the day of your birthday, too.',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.primaryInk,
                height: 19 / 13,
              ),
            ),
            MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: <Widget>[
                  SizedBox(
                    width: 40,
                    height: 44,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Day', style: labelStyle),
                    ),
                  ),
                  SizedBox(
                    width: 96,
                    child: TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      validator: FormValidators.birthDay,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      onChanged: (_) => onEdited(),
                      onFieldSubmitted: (_) => onSubmit(),
                      style: AppTextStyles.bodyLg.copyWith(
                        fontFamily: AppFonts.mono,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'DD',
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Required',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when the birth date is under 13 (client check or the server's
/// AGE_RESTRICTED). Nothing typed is kept.
final class _RestrictedStep extends StatelessWidget {
  const _RestrictedStep({required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 32,
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const AppSvgIcon(AppIcons.alert, width: 26, height: 26),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: <Widget>[
            const Text(
              'We can’t create your account yet',
              style: AppTextStyles.headlineLg,
            ),
            Text(
              'SkillBattles is available to players aged 13 and up. Nothing '
              'you entered has been saved.',
              style: AppTextStyles.bodyLg.copyWith(
                height: 22 / 15,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        AppButton(
          label: 'Back to start',
          variant: AppButtonVariant.outline,
          expand: true,
          onPressed: onRestart,
        ),
      ],
    );
  }
}

final class _CredentialsStep extends StatelessWidget {
  const _CredentialsStep({
    required this.formKey,
    required this.isSignUp,
    required this.nicknameController,
    required this.emailController,
    required this.passwordController,
    required this.nicknameFocus,
    required this.emailFocus,
    required this.passwordFocus,
    required this.state,
    required this.onSubmit,
    required this.onEdited,
    required this.onChangeBirth,
  });

  final GlobalKey<FormState> formKey;
  final bool isSignUp;
  final TextEditingController nicknameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode nicknameFocus;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final AuthState state;
  final VoidCallback onSubmit;
  final VoidCallback onEdited;
  final VoidCallback onChangeBirth;

  @override
  Widget build(BuildContext context) {
    final Failure? failure = state.failure;
    final bool isLoading = state.submitStatus.isLoading;

    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      // A new subtree per tab clears validation errors; the controllers keep
      // what was typed.
      child: KeyedSubtree(
        key: ValueKey<bool>(isSignUp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 32,
          children: <Widget>[
            AuthHeading(
              title: isSignUp ? 'Join the arena' : 'Welcome back',
              subtitle: isSignUp
                  ? 'Both ratings start at 1000. You can play right away.'
                  : 'Log in to keep your ratings and streaks.',
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: <Widget>[
                if (isSignUp)
                  AppTextField(
                    label: 'Nickname',
                    controller: nicknameController,
                    focusNode: nicknameFocus,
                    validator: FormValidators.nickname,
                    errorText: state.fieldError('nickname'),
                    textInputAction: TextInputAction.next,
                    autofillHints: const <String>[AutofillHints.newUsername],
                    onFieldSubmitted: (_) => emailFocus.requestFocus(),
                  ),
                AppTextField(
                  label: 'Email',
                  controller: emailController,
                  focusNode: emailFocus,
                  validator: FormValidators.email,
                  errorText: state.fieldError('email'),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.email],
                  onFieldSubmitted: (_) => passwordFocus.requestFocus(),
                ),
                AppTextField(
                  label: 'Password',
                  controller: passwordController,
                  focusNode: passwordFocus,
                  validator: FormValidators.password,
                  errorText: state.fieldError('password'),
                  helperText: isSignUp ? 'At least 8 characters' : null,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: <String>[
                    if (isSignUp)
                      AutofillHints.newPassword
                    else
                      AutofillHints.password,
                  ],
                  onFieldSubmitted: (_) => onSubmit(),
                ),
                if (failure != null) AppInlineError(failure.authMessage),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: <Widget>[
                AppButton(
                  label: isLoading
                      ? 'Please wait…'
                      : isSignUp
                      ? 'Create account & play'
                      : 'Log in & play',
                  variant: AppButtonVariant.dark,
                  expand: true,
                  onPressed: isLoading ? null : onSubmit,
                ),
                if (isSignUp)
                  _FooterLink(
                    text: 'Wrong birth date?',
                    label: 'Change it',
                    onPressed: onChangeBirth,
                  )
                else
                  _FooterLink(
                    text: '',
                    label: 'Forgot password?',
                    onPressed: () =>
                        context.goNamed(AppRoutes.forgotPassword.name),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
