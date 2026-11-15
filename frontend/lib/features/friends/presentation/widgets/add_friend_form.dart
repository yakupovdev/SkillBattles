import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_card.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_notice.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_field.dart';
import 'package:skill_battles/features/friends/presentation/controllers/friend_code_input.dart';

/// The line under the friend code field after a request was sent or found.
final class AddFriendNotice {
  const AddFriendNotice({
    required this.message,
    this.tone = AppNoticeTone.info,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final AppNoticeTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;
}

/// "Add a friend" card (Paper: "36 Friends — Component sheet", 12 states).
///
/// The screen owns the [formKey], [controller] and [focusNode], validates on
/// submit, builds the params entity and calls [onSubmit] (forms.md). This
/// widget only draws.
///
/// - [isSending]: the field is disabled and Send shows a spinner.
/// - [serverError]: a server field error (codes 8-10, VALIDATION_ERROR); the
///   screen clears it through [onEdited] when the user types.
/// - [rateLimitedUntil]: RATE_LIMITED; the field shows a countdown error and
///   Send stays disabled until it passes, then [onRateLimitElapsed] fires.
/// - [failureMessage]: network / other failure, drawn as an inline error.
/// - [notice]: success / info line.
final class AddFriendForm extends StatelessWidget {
  const AddFriendForm({
    required this.formKey,
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    this.isSending = false,
    this.serverError,
    this.rateLimitedUntil,
    this.clockOffset = Duration.zero,
    this.onRateLimitElapsed,
    this.failureMessage,
    this.notice,
    this.onEdited,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;
  final bool isSending;
  final String? serverError;
  final DateTime? rateLimitedUntil;
  final Duration clockOffset;
  final VoidCallback? onRateLimitElapsed;
  final String? failureMessage;
  final AddFriendNotice? notice;

  /// Called when the user edits the field, to clear a stale server error.
  final VoidCallback? onEdited;

  static const String helperText =
      '12 letters and digits. Hyphens and spaces around it are fine.';

  @override
  Widget build(BuildContext context) {
    final AddFriendNotice? note = notice;
    final String? failure = failureMessage;
    return AppCard(
      color: AppColors.white,
      child: Form(
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
                const Text('Add a friend', style: AppTextStyles.titleMd),
                Text(
                  'Ask for their friend code and send a request. '
                  'They accept it from their notifications.',
                  style: AppTextStyles.bodySm.copyWith(
                    height: 18 / 13,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
            _FieldRow(
              controller: controller,
              focusNode: focusNode,
              isSending: isSending,
              serverError: serverError,
              rateLimitedUntil: rateLimitedUntil,
              clockOffset: clockOffset,
              onRateLimitElapsed: onRateLimitElapsed,
              onSubmit: onSubmit,
              onEdited: onEdited,
            ),
            if (serverError == null &&
                rateLimitedUntil == null &&
                failure == null &&
                note == null)
              Text(
                helperText,
                style: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
              ),
            if (failure != null) AppInlineError(failure),
            if (note != null)
              AppNotice(
                message: note.message,
                tone: note.tone,
                actionLabel: note.actionLabel,
                onAction: note.onAction,
              ),
          ],
        ),
      ),
    );
  }
}

/// The input and the Send button. Owns the one-second tick of a rate limit
/// so only this row rebuilds.
final class _FieldRow extends StatefulWidget {
  const _FieldRow({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.serverError,
    required this.rateLimitedUntil,
    required this.clockOffset,
    required this.onRateLimitElapsed,
    required this.onSubmit,
    required this.onEdited,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final String? serverError;
  final DateTime? rateLimitedUntil;
  final Duration clockOffset;
  final VoidCallback? onRateLimitElapsed;
  final VoidCallback onSubmit;
  final VoidCallback? onEdited;

  @override
  State<_FieldRow> createState() => _FieldRowState();
}

final class _FieldRowState extends State<_FieldRow> {
  late Timer? _timer;
  late Duration? _remaining;
  late String _lastText;

  @override
  void initState() {
    super.initState();
    _timer = null;
    _remaining = null;
    _lastText = widget.controller.text;
    widget.controller.addListener(_onTextChanged);
    _syncTimer();
  }

  @override
  void didUpdateWidget(_FieldRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
      _lastText = widget.controller.text;
    }
    if (oldWidget.rateLimitedUntil != widget.rateLimitedUntil) _syncTimer();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _timer?.cancel();
    super.dispose();
  }

  /// A change of the text (not of the selection) clears a server error.
  void _onTextChanged() {
    final String text = widget.controller.text;
    if (text == _lastText) return;
    _lastText = text;
    if (widget.serverError != null) widget.onEdited?.call();
  }

  Duration? _computeRemaining() {
    final DateTime? until = widget.rateLimitedUntil;
    if (until == null) return null;
    final Duration left = until.difference(
      DateTime.now().add(widget.clockOffset),
    );
    return left > Duration.zero ? left : null;
  }

  void _syncTimer() {
    _timer?.cancel();
    _timer = null;
    _remaining = _computeRemaining();
    if (widget.rateLimitedUntil == null) return;
    if (_remaining == null) {
      // Already over: tell the owner after this frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onRateLimitElapsed?.call();
      });
      return;
    }
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    final Duration? next = _computeRemaining();
    if (next == null) {
      _timer?.cancel();
      _timer = null;
      setState(() => _remaining = null);
      widget.onRateLimitElapsed?.call();
      return;
    }
    if (next.inSeconds != _remaining?.inSeconds) {
      setState(() => _remaining = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Duration? left = _remaining;
    final bool isRateLimited = left != null;
    final String? errorText = isRateLimited
        ? 'Too many requests. Try again in '
              '${DisplayFormatters.clock(Duration(seconds: left.inSeconds + 1))}.'
        : widget.serverError;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: <Widget>[
        Expanded(
          child: AppTextField(
            label: 'Friend code',
            hintText: 'ABCD-2345-EFGH',
            controller: widget.controller,
            focusNode: widget.focusNode,
            validator: FriendCodeInput.validate,
            enabled: !widget.isSending,
            errorText: errorText,
            textInputAction: TextInputAction.send,
            onFieldSubmitted: (_) => _submit(),
            inputFormatters: <TextInputFormatter>[
              LengthLimitingTextInputFormatter(FriendCodeInput.maxLength),
            ],
          ),
        ),
        Padding(
          // Aligns the button with the 48 px input under its label.
          padding: const EdgeInsets.only(top: 22),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.controller,
            builder: (BuildContext context, TextEditingValue value, _) =>
                AppButton(
                  label: 'Send',
                  variant: AppButtonVariant.dark,
                  size: AppButtonSize.field,
                  isLoading: widget.isSending,
                  onPressed: value.text.trim().isEmpty || isRateLimited
                      ? null
                      : _submit,
                ),
          ),
        ),
      ],
    );
  }

  void _submit() {
    if (widget.isSending || _remaining != null) return;
    widget.onSubmit();
  }
}
