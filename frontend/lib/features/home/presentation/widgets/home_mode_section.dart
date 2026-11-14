import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/router/app_navigation.dart';
import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';
import 'package:skill_battles/core/presentation/widgets/app_tappable.dart';
import 'package:skill_battles/core/utils/error/api_error_codes.dart';
import 'package:skill_battles/core/utils/error/failure.dart';
import 'package:skill_battles/core/utils/error/failure_message.dart';
import 'package:skill_battles/core/utils/form_validators.dart';
import 'package:skill_battles/features/account/domain/entity/limits_entity.dart';
import 'package:skill_battles/features/catalog/domain/entity/discipline_entity.dart';
import 'package:skill_battles/features/home/presentation/bloc/home_bloc/home_bloc.dart';
import 'package:skill_battles/features/home/presentation/widgets/home_daily_limit_dialog.dart';
import 'package:skill_battles/features/private_duel/domain/entity/join_duel_params_entity.dart';

/// Ranked (with the shared Free daily limit), private duel (always
/// unlimited) and join by code, with the limit meter below.
final class HomeModeSection extends StatelessWidget {
  const HomeModeSection({
    required this.discipline,
    required this.limits,
    super.key,
  });

  final DisciplineEntity? discipline;
  final LimitsEntity? limits;

  @override
  Widget build(BuildContext context) {
    final LimitsEntity? limits = this.limits;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20,
          children: <Widget>[
            Expanded(
              flex: 13,
              child: _RankedTile(discipline: discipline, limits: limits),
            ),
            Expanded(flex: 10, child: _PrivateTile(discipline: discipline)),
            const Expanded(flex: 10, child: _CodeTile()),
          ],
        ),
        if (limits != null && !limits.entitlements.unlimitedRanked)
          _LimitMeter(limits: limits),
      ],
    );
  }
}

final class _RankedTile extends StatelessWidget {
  const _RankedTile({required this.discipline, required this.limits});

  final DisciplineEntity? discipline;
  final LimitsEntity? limits;

  @override
  Widget build(BuildContext context) {
    final DisciplineEntity? discipline = this.discipline;
    final LimitsEntity? limits = this.limits;
    final bool limitReached = limits != null && !limits.canStartRanked;
    final bool enabled = discipline != null && discipline.contentAvailable;
    final String subtitle = enabled
        ? 'Opponent near your ${discipline.displayName} rating'
        : 'Not available right now';

    return SizedBox(
      height: 88,
      child: AppTappable(
        borderRadius: BorderRadius.circular(14),
        semanticLabel: 'Find ranked match. $subtitle',
        onTap: !enabled
            ? null
            : limitReached
            ? () => showHomeDailyLimitDialog(
                context,
                limits: limits,
                disciplineCode: discipline.code,
              )
            : () => context.goRankedSearch(disciplineCode: discipline.code),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: enabled ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              spacing: 12,
              children: <Widget>[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: <Widget>[
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Find ranked match',
                          style: AppTextStyles.titleLg.copyWith(
                            color: enabled ? AppColors.white : AppColors.faint,
                          ),
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySm.copyWith(
                          color: enabled
                              ? AppColors.onPrimarySubtle
                              : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (enabled)
                  const ExcludeSemantics(
                    child: AppSvgIcon(
                      AppIcons.arrowRight,
                      width: 28,
                      height: 28,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _PrivateTile extends StatelessWidget {
  const _PrivateTile({required this.discipline});

  final DisciplineEntity? discipline;

  @override
  Widget build(BuildContext context) {
    final DisciplineEntity? discipline = this.discipline;
    final bool enabled = discipline != null && discipline.contentAvailable;
    final BorderRadius radius = BorderRadius.circular(14);
    return SizedBox(
      height: 88,
      child: AppTappable(
        borderRadius: radius,
        semanticLabel: 'Create private duel, unlimited, no rating change',
        onTap: enabled
            ? () => context.goPrivateDuel(disciplineCode: discipline.code)
            : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: enabled ? AppColors.ink : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: <Widget>[
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Create private duel',
                    style: AppTextStyles.titleMd.copyWith(
                      color: enabled ? AppColors.ink : AppColors.faint,
                    ),
                  ),
                ),
                Text(
                  'Unlimited · no rating change',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Free daily ranked usage: one bar per match, then the count and reset.
final class _LimitMeter extends StatelessWidget {
  const _LimitMeter({required this.limits});

  final LimitsEntity limits;

  @override
  Widget build(BuildContext context) {
    final int total = limits.freeRankedLimit;
    final int remaining = (limits.freeRankedRemaining ?? 0).clamp(0, total);
    return Row(
      spacing: 16,
      children: <Widget>[
        ExcludeSemantics(
          child: Row(
            spacing: 4,
            children: <Widget>[
              for (int i = 0; i < total; i++)
                SizedBox(
                  width: 20,
                  height: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: i < remaining
                          ? AppColors.primary
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Flexible(
          child: Text.rich(
            TextSpan(
              style: AppTextStyles.bodySm,
              children: <InlineSpan>[
                TextSpan(
                  text: '$remaining of $total',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const TextSpan(text: ' free ranked matches left today'),
                TextSpan(
                  text:
                      ' · resets ${DisplayFormatters.time(limits.resetsAt)} '
                      'your time',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

final class _CodeTile extends StatefulWidget {
  const _CodeTile();

  @override
  State<_CodeTile> createState() => _CodeTileState();
}

final class _CodeTileState extends State<_CodeTile> {
  static const int _codeLength = FormValidators.duelCodeLength;

  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  /// Client validation message; the tile has no room for it inside.
  late final ValueNotifier<String?> _localError;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _localError = ValueNotifier<String?>(null);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _localError.dispose();
    super.dispose();
  }

  void _submit() {
    final String? error = FormValidators.duelCode(_controller.text);
    _localError.value = error;
    if (error != null) {
      _focusNode.requestFocus();
      return;
    }
    context.read<HomeBloc>().add(
      HomeJoinDuelSubmitted(JoinDuelParamsEntity(code: _controller.text)),
    );
  }

  static String _joinMessage(Failure failure) {
    if (failure.hasCode(ApiErrorCodes.duelNotFound)) {
      return 'No room with this code.';
    }
    if (failure.hasCode(ApiErrorCodes.duelExpired)) {
      return 'This code has expired.';
    }
    if (failure.hasCode(ApiErrorCodes.selfJoinNotAllowed)) {
      return "That's your own room — share the code with a friend.";
    }
    if (failure.hasCode(ApiErrorCodes.duelNotJoinable)) {
      return 'This room already has an opponent.';
    }
    if (failure.hasCode(ApiErrorCodes.activityConflict)) {
      return 'Finish or leave your current match first.';
    }
    return failure.userMessage;
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle codeStyle = AppTextStyles.monoSm.copyWith(
      letterSpacing: 0.18 * 22,
    );
    final BorderRadius radius = BorderRadius.circular(14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: <Widget>[
        ListenableBuilder(
          listenable: _focusNode,
          builder: (BuildContext context, Widget? child) => AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 88,
            padding: const EdgeInsets.only(left: 20, right: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: radius,
              border: Border.all(
                color: _focusNode.hasFocus
                    ? AppColors.primary
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: child,
          ),
          child: Row(
            spacing: 12,
            children: <Widget>[
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  excludeFromSemantics: true,
                  onTap: _focusNode.requestFocus,
                  child: MergeSemantics(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: <Widget>[
                        Text(
                          'Have a code?',
                          style: AppTextStyles.bodyXs.copyWith(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          onChanged: (_) {
                            _localError.value = null;
                            context.read<HomeBloc>().add(
                              const HomeJoinCodeEdited(),
                            );
                          },
                          onSubmitted: (_) => _submit(),
                          maxLines: 1,
                          cursorColor: AppColors.ink,
                          textCapitalization: TextCapitalization.characters,
                          textInputAction: TextInputAction.go,
                          autocorrect: false,
                          enableSuggestions: false,
                          style: codeStyle,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                              RegExp('[A-Za-z0-9]'),
                            ),
                            const _UpperCaseFormatter(),
                            LengthLimitingTextInputFormatter(_codeLength),
                          ],
                          // Collapsed and borderless: the tile draws the box.
                          decoration:
                              InputDecoration.collapsed(
                                hintText: 'K7Q2__',
                                border: InputBorder.none,
                                hintStyle: codeStyle.copyWith(
                                  color: AppColors.faint,
                                ),
                              ).copyWith(
                                filled: false,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              BlocSelector<HomeBloc, HomeState, bool>(
                selector: (HomeState state) => state.joinStatus.isLoading,
                builder: (BuildContext context, bool isJoining) => AppButton(
                  label: isJoining ? 'Joining…' : 'Join',
                  variant: AppButtonVariant.dark,
                  size: AppButtonSize.small,
                  onPressed: isJoining ? null : _submit,
                ),
              ),
            ],
          ),
        ),
        ValueListenableBuilder<String?>(
          valueListenable: _localError,
          builder: (BuildContext context, String? localError, _) =>
              BlocSelector<HomeBloc, HomeState, Failure?>(
                selector: (HomeState state) => state.joinFailure,
                builder: (BuildContext context, Failure? failure) {
                  final String? message =
                      localError ??
                      (failure == null ? null : _joinMessage(failure));
                  return message == null
                      ? const SizedBox.shrink()
                      : AppInlineError(message);
                },
              ),
        ),
      ],
    );
  }
}

final class _UpperCaseFormatter extends TextInputFormatter {
  const _UpperCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
