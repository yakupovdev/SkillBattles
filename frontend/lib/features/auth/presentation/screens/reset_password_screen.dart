import 'package:bloc_signals_jaspr/bloc_signals_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/router/app_routes.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_callout.dart';
import 'package:skill_battles/core/presentation/widgets/app_form.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_field.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_input.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/extensions/route_extension.dart';
import 'package:skill_battles/core/utils/form_validators.dart';
import 'package:skill_battles/features/auth/domain/entity/password_reset_confirm_params_entity.dart';
import 'package:skill_battles/features/auth/domain/usecases/confirm_password_reset_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/request_password_reset_usecase.dart';
import 'package:skill_battles/features/auth/presentation/bloc/password_reset_bloc/password_reset_bloc.dart';
import 'package:skill_battles/features/auth/presentation/screens/auth_screen.dart';
import 'package:skill_battles/features/auth/presentation/widgets/auth_failure_message.dart';

/// Opened from the e-mail link (Paper: "13 Reset password"). The one-use token is read once into memory
/// and immediately removed from the address bar (the history entry is replaced); it is never logged.
final class ResetPasswordScreen extends StatefulComponent implements RouteWrapper {
  const ResetPasswordScreen({required this.token, super.key});

  final String? token;

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
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

final class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final GlobalStateKey<AppFormState> _formKey;
  late final TextEditingController _passwordController;
  late final FocusNode _passwordFocus;
  late String? _token;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalStateKey<AppFormState>();
    _passwordController = TextEditingController();
    _passwordFocus = FocusNode();
    _token = component.token;
    if (_token != null) {
      // Drop the token from the URL (and so from history) right away.
      context.binding.addPostFrameCallback(() {
        if (mounted) context.replaceLocation(AppRoutes.resetPassword.path);
      });
    }
  }

  @override
  void didUpdateComponent(ResetPasswordScreen oldComponent) {
    super.didUpdateComponent(oldComponent);
    // The URL rewrite rebuilds the route without a token: keep ours.
    _token ??= component.token;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    final String? token = _token;
    if (token == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<PasswordResetBloc>().add(
      PasswordResetConfirmed(
        PasswordResetConfirmParamsEntity(token: token, newPassword: _passwordController.text),
      ),
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
            final bool done = state.status.isSuccess;
            final Failure? failure = state.failure;
            final bool linkInvalid = _token == null || (failure?.hasCode(ApiErrorCodes.invalidResetToken) ?? false);
            return div(classes: 'auth-form', <Component>[
              const AuthHeading(
                eyebrow: 'Reset password',
                gap: 12,
                title: 'Pick a new password',
                subtitle:
                    "You'll be signed out on all devices and asked to log in "
                    'again.',
              ),
              if (done) ...<Component>[
                const AppCallout(
                  title: 'Password changed',
                  message:
                      'Every device was signed out. Log in with the new '
                      'password.',
                  tone: AppCalloutTone.success,
                ),
                AppButton(
                  label: 'Go to log in',
                  variant: AppButtonVariant.dark,
                  expand: true,
                  onPressed: () => context.goNamed(AppRoutes.auth.name),
                ),
              ] else ...<Component>[
                div(classes: 'auth-form__fields', <Component>[
                  // No onFieldSubmitted: Enter submits the form.
                  AppTextField(
                    label: 'New password',
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    validator: FormValidators.password,
                    helperText: '8–72 characters',
                    obscureText: true,
                    canReveal: true,
                    textInputAction: TextInputAction.done,
                    autofillHints: const <String>[AutofillHints.newPassword],
                  ),
                  if (failure != null && !linkInvalid) AppInlineError(failure.authMessage),
                ]),
                AppButton(
                  label: state.status.isLoading ? 'Saving…' : 'Save and log in',
                  variant: AppButtonVariant.dark,
                  expand: true,
                  type: ButtonType.submit,
                  onPressed: state.status.isLoading || _token == null ? null : _submitsEnclosingForm,
                ),
                if (linkInvalid)
                  AppCallout(
                    title: 'This link has expired or was already used',
                    message: 'Reset links work once, for 20 minutes.',
                    tone: AppCalloutTone.danger,
                    actionLabel: 'Request a new link',
                    onAction: () => context.goNamed(AppRoutes.forgotPassword.name),
                  ),
              ],
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
