import 'package:bloc_signals_jaspr/bloc_signals_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/router/app_routes.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_desktop_viewport.dart';
import 'package:skill_battles/core/presentation/widgets/app_dropdown_field.dart';
import 'package:skill_battles/core/presentation/widgets/app_eyebrow.dart';
import 'package:skill_battles/core/presentation/widgets/app_form.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_logo.dart';
import 'package:skill_battles/core/presentation/widgets/app_segmented_control.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_field.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_input.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_link.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/extensions/route_extension.dart';
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
final class AuthScreen extends StatelessComponent implements RouteWrapper {
  const AuthScreen({super.key});

  @override
  Component wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocSignalProvider<AuthBloc>(
      create: (_) => AuthBloc(
        checkAge: dependencies.getDep<CheckAgeUsecase>(),
        register: dependencies.getDep<RegisterUsecase>(),
        login: dependencies.getDep<LoginUsecase>(),
      ),
      child: this,
    );
  }

  @override
  Component build(BuildContext context) {
    return const AuthLayout(child: _AuthForm());
  }
}

/// The blue hero half and a form half; shared by the auth screens.
///
/// Both halves span the full window width and page height: the hero's blue
/// background stretches with the taller of the two halves.
final class AuthLayout extends StatelessComponent {
  const AuthLayout({required this.child, super.key});

  final Component child;

  @override
  Component build(BuildContext context) {
    return AppDesktopViewport(
      fullBleed: true,
      child: div(classes: 'auth-layout', <Component>[
        const _Hero(),
        div(classes: 'auth-layout__form-side', <Component>[
          div(classes: 'auth-layout__form', <Component>[child]),
        ]),
      ]),
    );
  }
}

final class _Hero extends StatelessComponent {
  const _Hero();

  @override
  Component build(BuildContext context) {
    return const section(classes: 'auth-hero', <Component>[
      _Ring(size: 420, top: 120, right: -120, color: AppColors.onPrimaryRingOuter),
      _Ring(size: 260, top: 200, right: -40, color: AppColors.onPrimaryRingInner),
      AppLogo(variant: AppLogoVariant.onPrimary),
      _HeroCopy(),
      _HeroCaptions(),
    ]);
  }
}

final class _Ring extends StatelessComponent {
  const _Ring({
    required this.size,
    required this.top,
    required this.right,
    required this.color,
  });

  final double size;
  final double top;
  final double right;
  final Color color;

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'auth-hero__ring',
      styles: Styles(
        position: Position.absolute(top: Unit.pixels(top), right: Unit.pixels(right)),
        width: Unit.pixels(size),
        height: Unit.pixels(size),
        border: Border.all(color: color, width: const Unit.pixels(2)),
      ),
      attributes: const <String, String>{'aria-hidden': 'true'},
      const <Component>[],
    );
  }
}

final class _HeroCopy extends StatelessComponent {
  const _HeroCopy();

  @override
  Component build(BuildContext context) {
    return const div(classes: 'auth-hero__copy', <Component>[
      h1(classes: 'auth-hero__title', <Component>[
        Component.text('Five minutes.'),
        br(),
        Component.text('One opponent.'),
        br(),
        span(classes: 'auth-hero__title-accent', <Component>[Component.text('Sharper mind.')]),
      ]),
      p(classes: 'auth-hero__body', <Component>[
        Component.text(
          'Live one-on-one battles in SAT Math and Reading & Writing. Same '
          'questions, same clock — learn from every round.',
        ),
      ]),
    ]);
  }
}

final class _HeroCaptions extends StatelessComponent {
  const _HeroCaptions();

  @override
  Component build(BuildContext context) {
    return const div(classes: 'auth-hero__captions', <Component>[
      span(classes: 'auth-hero__caption', <Component>[Component.text('SAT MATH · 5 ROUNDS')]),
      span(classes: 'auth-hero__caption', <Component>[Component.text('SAT R&W · 5 ROUNDS')]),
      span(classes: 'auth-hero__caption', <Component>[Component.text('ELO RANKED · 27 TIERS')]),
    ]);
  }
}

enum _AuthTab { signUp, logIn }

final class _AuthForm extends StatefulComponent {
  const _AuthForm();

  @override
  State<_AuthForm> createState() => _AuthFormState();
}

final class _AuthFormState extends State<_AuthForm> {
  late final GlobalStateKey<AppFormState> _ageFormKey;
  late final GlobalStateKey<AppFormState> _formKey;
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
    _ageFormKey = GlobalStateKey<AppFormState>();
    _formKey = GlobalStateKey<AppFormState>();
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
    // Typing the day is a birth edit (Flutter: the day field's onChanged).
    _dayController.addListener(_onBirthEdited);
  }

  @override
  void dispose() {
    _dayController.removeListener(_onBirthEdited);
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

  bool get _needsDay => context.read<AuthBloc>().stateValue.ageResult == AgeCheckResult.needsDay;

  void _submitAge() {
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
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final AuthBloc bloc = context.read<AuthBloc>();
    if (!_isSignUp) {
      bloc.add(
        AuthLoginSubmitted(
          LoginParamsEntity(email: _emailController.text, password: _passwordController.text),
        ),
      );
      return;
    }
    final AgeCheckParamsEntity? birth = _birth(withDay: _dayController.text.trim().isNotEmpty);
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
  Component build(BuildContext context) {
    return BlocSignalBuilder<AuthBloc, AuthState>(
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
            result: state.ageResult,
            isSubmitting: state.submitStatus.isLoading,
            onSubmit: _submitAge,
            onLogIn: () => _onTabSelected(_AuthTab.logIn),
          );
        }
        return div(classes: 'auth-form', <Component>[
          AppSegmentedControl<_AuthTab>(
            segments: const <AppSegment<_AuthTab>>[
              AppSegment<_AuthTab>(value: _AuthTab.signUp, label: 'Create account'),
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
            onChangeBirth: _onBirthEdited,
          ),
        ]);
      },
    );
  }
}

/// `onPressed` of a submit button: the click submits the enclosing
/// [AppForm], whose `onSubmit` does the work (also for Enter in a field).
void _submitsEnclosingForm() {}

/// Eyebrow, title and muted subtitle at the top of every auth form.
final class AuthHeading extends StatelessComponent {
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
  Component build(BuildContext context) {
    final String? eyebrow = this.eyebrow;
    return div(
      classes: 'auth-heading',
      styles: Styles(gap: Gap.row(Unit.pixels(gap))),
      <Component>[
        if (eyebrow != null) AppEyebrow(eyebrow),
        h2(classes: 'auth-heading__title', <Component>[Component.text(title)]),
        p(classes: 'auth-heading__subtitle', <Component>[Component.text(subtitle)]),
      ],
    );
  }
}

/// "Already have an account? Log in" — muted text with a blue link.
final class _FooterLink extends StatelessComponent {
  const _FooterLink({required this.text, required this.label, required this.onPressed});

  final String text;
  final String label;
  final VoidCallback onPressed;

  @override
  Component build(BuildContext context) {
    return div(classes: 'auth-footer-link', <Component>[
      if (text.isNotEmpty) span(classes: 'auth-footer-link__text', <Component>[Component.text('$text ')]),
      AppTextLink(
        label: label,
        style: AppTextStyles.bodySm.combine(const Styles(color: AppColors.primary, fontWeight: FontWeight.w500)),
        onPressed: onPressed,
      ),
    ]);
  }
}

final class _AgeStep extends StatelessComponent {
  const _AgeStep({
    required this.formKey,
    required this.dayController,
    required this.dayFocus,
    required this.month,
    required this.year,
    required this.onMonthChanged,
    required this.onYearChanged,
    required this.result,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onLogIn,
  });

  final GlobalStateKey<AppFormState> formKey;
  final TextEditingController dayController;
  final FocusNode dayFocus;
  final int? month;
  final int? year;
  final ValueChanged<int?> onMonthChanged;
  final ValueChanged<int?> onYearChanged;
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
  Component build(BuildContext context) {
    return AppForm(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      onSubmit: onSubmit,
      child: div(classes: 'auth-form', <Component>[
        const AuthHeading(
          eyebrow: 'Step 1 of 2 — About you',
          gap: 12,
          title: 'When were you born?',
          subtitle:
              "We only use this to confirm eligibility. It's never shown "
              'to opponents or on leaderboards.',
        ),
        div(classes: 'auth-form__fields auth-form__fields--age', <Component>[
          div(classes: 'auth-birth', <Component>[
            div(classes: 'auth-birth__month', <Component>[
              AppDropdownField<int>(
                label: 'Month',
                hintText: 'Month',
                items: List<int>.generate(12, (int i) => i + 1),
                labelOf: (int value) => _months[value - 1],
                value: month,
                validator: FormValidators.birthMonth,
                onChanged: onMonthChanged,
              ),
            ]),
            div(classes: 'auth-birth__year', <Component>[
              AppDropdownField<int>(
                label: 'Year',
                hintText: 'YYYY',
                items: _years(),
                labelOf: (int value) => '$value',
                value: year,
                style: AppTextStyles.bodyLg.combine(const Styles(fontFamily: AppFonts.mono)),
                validator: (int? value) => FormValidators.birthYear(value?.toString()),
                onChanged: onYearChanged,
              ),
            ]),
          ]),
          if (result == AgeCheckResult.needsDay) _DayPanel(controller: dayController, focusNode: dayFocus),
          if (result == AgeCheckResult.invalidDate) const AppInlineError('Enter a real date in the past.'),
        ]),
        div(classes: 'auth-form__actions', <Component>[
          AppButton(
            label: 'Continue',
            variant: AppButtonVariant.dark,
            expand: true,
            type: ButtonType.submit,
            trailingIcon: const AppSvgIcon(AppIcons.arrowSmall, width: 16, height: 16),
            onPressed: isSubmitting ? null : _submitsEnclosingForm,
          ),
          _FooterLink(text: 'Already have an account?', label: 'Log in', onPressed: onLogIn),
        ]),
      ]),
    );
  }
}

/// The blue note that asks for the day when the user turns 13 this month.
///
/// Enter in the day field submits the age form.
final class _DayPanel extends StatelessComponent {
  const _DayPanel({required this.controller, required this.focusNode});

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Component build(BuildContext context) {
    return div(classes: 'auth-day', <Component>[
      const p(classes: 'auth-day__note', <Component>[
        Component.text('Please add the day of your birthday, too.'),
      ]),
      div(classes: 'auth-day__row', <Component>[
        // The field keeps its own (visually hidden) "Day" label for
        // assistive technology; this one is the visible caption.
        const span(
          classes: 'auth-day__label',
          attributes: <String, String>{'aria-hidden': 'true'},
          <Component>[Component.text('Day')],
        ),
        div(classes: 'auth-day__field', <Component>[
          AppTextField(
            label: 'Day',
            controller: controller,
            focusNode: focusNode,
            validator: FormValidators.birthDay,
            hintText: 'DD',
            textInputAction: TextInputAction.done,
            autofillHints: const <String>['bday-day'],
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              const LengthLimitingTextInputFormatter(2),
            ],
          ),
        ]),
        const span(classes: 'auth-day__required', <Component>[Component.text('Required')]),
      ]),
    ]);
  }
}

/// Shown when the birth date is under 13 (client check or the server's
/// AGE_RESTRICTED). Nothing typed is kept.
final class _RestrictedStep extends StatelessComponent {
  const _RestrictedStep({required this.onRestart});

  final VoidCallback onRestart;

  @override
  Component build(BuildContext context) {
    return div(classes: 'auth-form', <Component>[
      const div(classes: 'auth-restricted__icon', <Component>[
        AppSvgIcon(AppIcons.alert, width: 26, height: 26),
      ]),
      const div(classes: 'auth-restricted__copy', <Component>[
        h2(classes: 'auth-heading__title', <Component>[Component.text('We can’t create your account yet')]),
        p(classes: 'auth-heading__subtitle', <Component>[
          Component.text(
            'SkillBattles is available to players aged 13 and up. Nothing '
            'you entered has been saved.',
          ),
        ]),
      ]),
      AppButton(
        label: 'Back to start',
        variant: AppButtonVariant.outline,
        expand: true,
        onPressed: onRestart,
      ),
    ]);
  }
}

/// Nickname (sign-up only), email and password in one `<form>`.
///
/// Password managers: the email is the account's login, so it is the
/// `username` on log-in and `email` on sign-up (where the nickname is only
/// a `nickname`, never the saved username); the password is
/// `current-password` / `new-password`.
final class _CredentialsStep extends StatelessComponent {
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
    required this.onChangeBirth,
  });

  final GlobalStateKey<AppFormState> formKey;
  final bool isSignUp;
  final TextEditingController nicknameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode nicknameFocus;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final AuthState state;
  final VoidCallback onSubmit;
  final VoidCallback onChangeBirth;

  @override
  Component build(BuildContext context) {
    final Failure? failure = state.failure;
    final bool isLoading = state.submitStatus.isLoading;

    return AppForm(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteractionIfError,
      onSubmit: onSubmit,
      // A new subtree per tab clears validation errors; the controllers keep
      // what was typed.
      child: div(key: ValueKey<bool>(isSignUp), classes: 'auth-form', <Component>[
        AuthHeading(
          title: isSignUp ? 'Join the arena' : 'Welcome back',
          subtitle: isSignUp
              ? 'Both ratings start at 1000. You can play right away.'
              : 'Log in to keep your ratings and streaks.',
        ),
        div(classes: 'auth-form__fields', <Component>[
          if (isSignUp)
            AppTextField(
              label: 'Nickname',
              controller: nicknameController,
              focusNode: nicknameFocus,
              validator: FormValidators.nickname,
              errorText: state.fieldError('nickname'),
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.nickname],
              name: 'nickname',
              onFieldSubmitted: (_) => emailFocus.requestFocus(),
            ),
          AppTextField(
            label: 'Email',
            controller: emailController,
            focusNode: emailFocus,
            validator: FormValidators.email,
            errorText: state.fieldError('email'),
            keyboardType: InputType.email,
            textInputAction: TextInputAction.next,
            autofillHints: <String>[if (isSignUp) AutofillHints.email else AutofillHints.username],
            name: 'email',
            onFieldSubmitted: (_) => passwordFocus.requestFocus(),
          ),
          // No onFieldSubmitted: Enter submits the form natively, which is
          // what password managers watch for.
          AppTextField(
            label: 'Password',
            controller: passwordController,
            focusNode: passwordFocus,
            validator: FormValidators.password,
            errorText: state.fieldError('password'),
            helperText: isSignUp ? 'At least 8 characters' : null,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: <String>[if (isSignUp) AutofillHints.newPassword else AutofillHints.password],
            name: 'password',
          ),
          if (failure != null) AppInlineError(failure.authMessage),
        ]),
        div(classes: 'auth-form__actions', <Component>[
          AppButton(
            label: isLoading
                ? 'Please wait…'
                : isSignUp
                ? 'Create account & play'
                : 'Log in & play',
            variant: AppButtonVariant.dark,
            expand: true,
            type: ButtonType.submit,
            onPressed: isLoading ? null : _submitsEnclosingForm,
          ),
          if (isSignUp)
            _FooterLink(text: 'Wrong birth date?', label: 'Change it', onPressed: onChangeBirth)
          else
            _FooterLink(
              text: '',
              label: 'Forgot password?',
              onPressed: () => context.goNamed(AppRoutes.forgotPassword.name),
            ),
        ]),
      ]),
    );
  }
}

@css
List<StyleRule> get authScreenStyles => <StyleRule>[
  css('.auth-layout').styles(
    display: Display.flex,
    alignItems: AlignItems.stretch,
    backgroundColor: AppColors.white,
  ),
  css('.auth-hero').styles(
    display: Display.flex,
    position: const Position.relative(),
    minWidth: Unit.zero,
    padding: const Padding.symmetric(horizontal: Unit.pixels(64), vertical: Unit.pixels(56)),
    overflow: Overflow.hidden,
    flexDirection: FlexDirection.column,
    justifyContent: JustifyContent.spaceBetween,
    alignItems: AlignItems.start,
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
    backgroundColor: AppColors.primary,
  ),
  css('.auth-hero > :not(.auth-hero__ring)').styles(position: const Position.relative()),
  css('.auth-hero__ring').styles(
    radius: const BorderRadius.circular(Unit.percent(50)),
    pointerEvents: PointerEvents.none,
  ),
  css('.auth-hero__copy').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(24)),
  ),
  css('.auth-hero__title').combine(AppTextStyles.displayLg).combine(const Styles(color: AppColors.white)),
  css('.auth-hero__title-accent').styles(color: AppColors.accent),
  css('.auth-hero__body')
      .styles(maxWidth: const Unit.pixels(460))
      .combine(AppTextStyles.bodyXl)
      .combine(const Styles(color: AppColors.onPrimaryBody)),
  css('.auth-hero__captions').styles(
    display: Display.flex,
    flexWrap: FlexWrap.wrap,
    gap: const Gap(row: Unit.pixels(8), column: Unit.pixels(32)),
  ),
  css('.auth-hero__caption')
      .combine(AppTextStyles.monoBodySm)
      .combine(const Styles(color: AppColors.onPrimaryMuted, letterSpacing: Unit.em(0.04))),
  css('.auth-layout__form-side').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    padding: const Padding.all(Unit.pixels(32)),
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.auth-layout__form').styles(width: const Unit.percent(100), maxWidth: const Unit.pixels(400)),
  css('.auth-form').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(32)),
  ),
  css('.auth-form__fields').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(16)),
  ),
  css('.auth-form__fields--age').styles(gap: const Gap.row(Unit.pixels(20))),
  css('.auth-form__actions').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(16)),
  ),
  css('.auth-heading').styles(display: Display.flex, flexDirection: FlexDirection.column),
  css('.auth-heading__title').combine(AppTextStyles.headlineLg),
  css('.auth-heading__subtitle')
      .combine(AppTextStyles.bodyLg)
      .combine(const Styles(color: AppColors.muted, lineHeight: Unit.pixels(22))),
  css('.auth-footer-link').styles(
    display: Display.flex,
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
  ),
  css('.auth-footer-link__text')
      .styles(whiteSpace: WhiteSpace.preWrap)
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.muted)),
  css('.auth-birth').styles(
    display: Display.flex,
    alignItems: AlignItems.start,
    gap: const Gap.column(Unit.pixels(12)),
  ),
  css('.auth-birth__month').styles(
    minWidth: Unit.zero,
    flex: const Flex(grow: 14, shrink: 1, basis: Unit.zero),
  ),
  css('.auth-birth__year').styles(
    minWidth: Unit.zero,
    flex: const Flex(grow: 10, shrink: 1, basis: Unit.zero),
  ),
  css('.auth-day').styles(
    display: Display.flex,
    padding: const Padding.all(Unit.pixels(16)),
    border: Border.all(color: AppColors.primaryLine, width: const Unit.pixels(1)),
    radius: const BorderRadius.circular(Unit.pixels(12)),
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(10)),
    backgroundColor: AppColors.primarySurface,
  ),
  css('.auth-day__note')
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.primaryInk, lineHeight: Unit.pixels(19))),
  css('.auth-day__row').styles(
    display: Display.flex,
    alignItems: AlignItems.start,
    gap: const Gap.column(Unit.pixels(12)),
  ),
  css('.auth-day__label')
      .styles(
        display: Display.flex,
        width: const Unit.pixels(40),
        height: const Unit.pixels(44),
        alignItems: AlignItems.center,
        flex: const Flex(shrink: 0),
      )
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(fontWeight: FontWeight.w500)),
  css('.auth-day__required')
      .styles(display: Display.flex, height: const Unit.pixels(44), alignItems: AlignItems.center)
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.muted)),
  css('.auth-day__field').styles(width: const Unit.pixels(96), flex: const Flex(shrink: 0)),
  // The field's own label stays readable by assistive technology only.
  css('.auth-day__field .app-text-field__label').styles(
    position: const Position.absolute(),
    width: const Unit.pixels(1),
    height: const Unit.pixels(1),
    overflow: Overflow.hidden,
    whiteSpace: WhiteSpace.noWrap,
    raw: const <String, String>{'clip-path': 'inset(50%)'},
  ),
  css('.auth-day__field .app-text-field').styles(gap: const Gap.row(Unit.pixels(4))),
  css('.auth-day__field .app-text-field__box').styles(height: const Unit.pixels(44)),
  css('.auth-day__field .app-text-field__input').styles(fontFamily: AppFonts.mono),
  css('.auth-restricted__icon').styles(
    display: Display.flex,
    width: const Unit.pixels(56),
    height: const Unit.pixels(56),
    radius: const BorderRadius.circular(Unit.pixels(16)),
    justifyContent: JustifyContent.center,
    alignItems: AlignItems.center,
    backgroundColor: AppColors.surface,
  ),
  css('.auth-restricted__copy').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(12)),
  ),
];
