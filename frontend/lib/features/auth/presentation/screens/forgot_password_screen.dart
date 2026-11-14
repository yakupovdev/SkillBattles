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
import 'package:skill_battles/core/presentation/widgets/app_callout.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_field.dart';
import 'package:skill_battles/core/utils/extensions/go_router_extension.dart';
import 'package:skill_battles/core/utils/form_validators.dart';
import 'package:skill_battles/features/auth/domain/entity/password_reset_request_params_entity.dart';
import 'package:skill_battles/features/auth/domain/usecases/confirm_password_reset_usecase.dart';
import 'package:skill_battles/features/auth/domain/usecases/request_password_reset_usecase.dart';
import 'package:skill_battles/features/auth/presentation/bloc/password_reset_bloc/password_reset_bloc.dart';
import 'package:skill_battles/features/auth/presentation/screens/auth_screen.dart';
import 'package:skill_battles/features/auth/presentation/widgets/auth_failure_message.dart';

/// "Forgot password" (Paper: "12 Forgot password"): the answer is the same whether the account exists.
final class ForgotPasswordScreen extends StatefulWidget
    implements GoRouterWrapper {
  const ForgotPasswordScreen({super.key});

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
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

final class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _emailController;
  late final FocusNode _emailFocus;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
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
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<PasswordResetBloc>().add(
      PasswordResetRequested(
        PasswordResetRequestParamsEntity(email: _emailController.text),
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
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 32,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: _BackLink(
                    onPressed: () => context.goNamed(AppRoutes.auth.name),
                  ),
                ),
                const AuthHeading(
                  title: 'Forgot your password?',
                  gap: 12,
                  subtitle:
                      "Enter the email you signed up with. We'll send a link "
                      'that works for 20 minutes.',
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: <Widget>[
                    AppTextField(
                      label: 'Email',
                      controller: _emailController,
                      focusNode: _emailFocus,
                      validator: FormValidators.email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autofillHints: const <String>[AutofillHints.email],
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (state.failure != null)
                      AppInlineError(state.failure!.authMessage),
                  ],
                ),
                AppButton(
                  label: state.status.isLoading
                      ? 'Sending…'
                      : state.status.isSuccess
                      ? 'Send again'
                      : 'Send reset link',
                  variant: AppButtonVariant.dark,
                  expand: true,
                  onPressed: state.status.isLoading ? null : _submit,
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
              ],
            );
          },
        ),
      ),
    );
  }
}

/// "‹ Back to log in" above the form.
final class _BackLink extends StatelessWidget {
  const _BackLink({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppTappable(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      semanticLabel: 'Back to log in',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: <Widget>[
          const AppSvgIcon(AppIcons.chevronLeft, width: 16, height: 16),
          Text(
            'Back to log in',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
