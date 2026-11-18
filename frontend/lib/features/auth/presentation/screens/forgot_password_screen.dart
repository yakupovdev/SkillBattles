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
import 'package:skill_battles/core/presentation/widgets/app_callout.dart';
import 'package:skill_battles/core/presentation/widgets/app_form.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_field.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_input.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/extensions/route_extension.dart';
import 'package:skill_battles/core/utils/form_validators.dart';
import 'package:skill_battles/features/auth/domain/entity/password_reset_request_params_entity.dart';
import 'package:skill_battles/features/auth/domain/usecases/confirm_password_reset_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/request_password_reset_usecase.dart';
import 'package:skill_battles/features/auth/presentation/bloc/password_reset_bloc/password_reset_bloc.dart';
import 'package:skill_battles/features/auth/presentation/screens/auth_screen.dart';
import 'package:skill_battles/features/auth/presentation/widgets/auth_failure_message.dart';

/// "Forgot password" (Paper: "12 Forgot password"): the answer is the same whether the account exists.
final class ForgotPasswordScreen extends StatefulComponent implements RouteWrapper {
  const ForgotPasswordScreen({super.key});

  @override
  Component wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocSignalProvider<PasswordResetBloc>(
      create: (_) => PasswordResetBloc(
        requestReset: dependencies.getDep<RequestPasswordResetUsecase>(),
        confirmReset: dependencies.getDep<ConfirmPasswordResetUsecase>(),
      ),
      child: this,
    );
  }

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

final class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final GlobalStateKey<AppFormState> _formKey;
  late final TextEditingController _emailController;
  late final FocusNode _emailFocus;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalStateKey<AppFormState>();
    _emailController = TextEditingController();
    _emailFocus = FocusNode();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<PasswordResetBloc>().add(
      PasswordResetRequested(PasswordResetRequestParamsEntity(email: _emailController.text)),
    );
  }

  @override
  Component build(BuildContext context) {
    return AuthLayout(
      child: AppForm(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteractionIfError,
        onSubmit: _submit,
        child: BlocSignalBuilder<PasswordResetBloc, PasswordResetState>(
          builder: (BuildContext context, PasswordResetState state) {
            final Failure? failure = state.failure;
            return div(classes: 'auth-form', <Component>[
              _BackLink(onPressed: () => context.goNamed(AppRoutes.auth.name)),
              const AuthHeading(
                title: 'Forgot your password?',
                gap: 12,
                subtitle:
                    "Enter the email you signed up with. We'll send a link "
                    'that works for 20 minutes.',
              ),
              div(classes: 'auth-form__fields', <Component>[
                // No onFieldSubmitted: Enter submits the form.
                AppTextField(
                  label: 'Email',
                  controller: _emailController,
                  focusNode: _emailFocus,
                  validator: FormValidators.email,
                  keyboardType: InputType.email,
                  textInputAction: TextInputAction.done,
                  autofillHints: const <String>[AutofillHints.email],
                ),
                if (failure != null) AppInlineError(failure.authMessage),
              ]),
              AppButton(
                label: state.status.isLoading
                    ? 'Sending…'
                    : state.status.isSuccess
                    ? 'Send again'
                    : 'Send reset link',
                variant: AppButtonVariant.dark,
                expand: true,
                type: ButtonType.submit,
                onPressed: state.status.isLoading ? null : _submitsEnclosingForm,
              ),
              if (state.status.isSuccess)
                AppCallout(
                  title: 'Check your inbox',
                  message:
                      state.message ??
                      'If an account exists for this email, password reset '
                          'instructions will be sent.',
                  tone: AppCalloutTone.success,
                ),
            ]);
          },
        ),
      ),
    );
  }
}

/// `onPressed` of the submit button: the click submits the [AppForm], whose
/// `onSubmit` does the work (also for Enter in the field).
void _submitsEnclosingForm() {}

/// "‹ Back to log in" above the form.
final class _BackLink extends StatelessComponent {
  const _BackLink({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Component build(BuildContext context) {
    return AppTappable(
      onTap: onPressed,
      radius: 4,
      classes: 'auth-back-link',
      semanticLabel: 'Back to log in',
      child: const span(classes: 'auth-back-link__row', <Component>[
        AppSvgIcon(AppIcons.chevronLeft, width: 16, height: 16),
        span(classes: 'auth-back-link__label', <Component>[Component.text('Back to log in')]),
      ]),
    );
  }
}

@css
List<StyleRule> get forgotPasswordScreenStyles => <StyleRule>[
  css('.auth-back-link').styles(width: Unit.fitContent),
  css('.auth-back-link__row').styles(
    display: Display.flex,
    alignItems: AlignItems.center,
    gap: const Gap.column(Unit.pixels(8)),
  ),
  css('.auth-back-link__label')
      .combine(AppTextStyles.bodyMd)
      .combine(const Styles(color: AppColors.muted, fontWeight: FontWeight.w500)),
];
