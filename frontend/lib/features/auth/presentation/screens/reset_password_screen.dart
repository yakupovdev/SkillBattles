import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/di/app_dependencies.dart';
import 'package:skill_battles/app/di/app_dependencies_provider.dart';
import 'package:skill_battles/app/router/app_routes.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_callout.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_field.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/extensions/go_router_extension.dart';
import 'package:skill_battles/core/utils/form_validators.dart';
import 'package:skill_battles/features/auth/domain/entity/password_reset_confirm_params_entity.dart';
import 'package:skill_battles/features/auth/domain/usecases/confirm_password_reset_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/request_password_reset_usecase.dart';
import 'package:skill_battles/features/auth/presentation/bloc/password_reset_bloc/password_reset_bloc.dart';
import 'package:skill_battles/features/auth/presentation/screens/auth_screen.dart';
import 'package:skill_battles/features/auth/presentation/widgets/auth_failure_message.dart';

/// Opened from the e-mail link (Paper: "13 Reset password"). The one-use token is read once into memory
/// and immediately removed from the address bar; it is never logged.
final class ResetPasswordScreen extends StatefulWidget
    implements GoRouterWrapper {
  const ResetPasswordScreen({required this.token, super.key});

  final String? token;

  @override
  Widget wrappedRoute(BuildContext context) {
    final AppDependencies dependencies = AppDependenciesProvider.of(context);
    return BlocProvider<PasswordResetBloc>(
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
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _passwordController;
  late final FocusNode _passwordFocus;
  late String? _token;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _passwordController = TextEditingController();
    _passwordFocus = FocusNode();
    _token = widget.token;
    if (_token != null) {
      // Drop the token from the URL (and so from history) right away.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.replaceNamed(AppRoutes.resetPassword.name);
      });
    }
  }

  @override
  void didUpdateWidget(ResetPasswordScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The URL rewrite rebuilds the route without a token: keep ours.
    _token ??= widget.token;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final String? token = _token;
    if (token == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<PasswordResetBloc>().add(
      PasswordResetConfirmed(
        PasswordResetConfirmParamsEntity(
          token: token,
          newPassword: _passwordController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteractionIfError,
        child: BlocBuilder<PasswordResetBloc, PasswordResetState>(
          builder: (BuildContext context, PasswordResetState state) {
            final bool done = state.status.isSuccess;
            final Failure? failure = state.failure;
            final bool linkInvalid =
                _token == null ||
                (failure?.hasCode(ApiErrorCodes.invalidResetToken) ?? false);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 32,
              children: <Widget>[
                const AuthHeading(
                  eyebrow: 'Reset password',
                  gap: 12,
                  title: 'Pick a new password',
                  subtitle:
                      "You'll be signed out on all devices and asked to log in "
                      'again.',
                ),
                if (done) ...<Widget>[
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
                ] else ...<Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 16,
                    children: <Widget>[
                      AppTextField(
                        label: 'New password',
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        validator: FormValidators.password,
                        helperText: '8–72 characters',
                        obscureText: true,
                        canReveal: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const <String>[
                          AutofillHints.newPassword,
                        ],
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      if (failure != null && !linkInvalid)
                        AppInlineError(failure.authMessage),
                    ],
                  ),
                  AppButton(
                    label: state.status.isLoading
                        ? 'Saving…'
                        : 'Save and log in',
                    variant: AppButtonVariant.dark,
                    expand: true,
                    onPressed: state.status.isLoading || _token == null
                        ? null
                        : _submit,
                  ),
                  if (linkInvalid)
                    AppCallout(
                      title: 'This link has expired or was already used',
                      message: 'Reset links work once, for 20 minutes.',
                      tone: AppCalloutTone.danger,
                      actionLabel: 'Request a new link',
                      onAction: () =>
                          context.goNamed(AppRoutes.forgotPassword.name),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
