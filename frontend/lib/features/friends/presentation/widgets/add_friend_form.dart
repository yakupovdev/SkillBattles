import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/formatters/display_formatters.dart';
import 'package:skill_battles/core/presentation/widgets/app_button.dart';
import 'package:skill_battles/core/presentation/widgets/app_card.dart';
import 'package:skill_battles/core/presentation/widgets/app_form.dart';
import 'package:skill_battles/core/presentation/widgets/app_inline_error.dart';
import 'package:skill_battles/core/presentation/widgets/app_notice.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_field.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_input.dart';
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
/// component only draws.
///
/// - [isSending]: the field is disabled and Send shows a spinner.
/// - [serverError]: a server field error (codes 8-10, VALIDATION_ERROR); the
///   screen clears it through [onEdited] when the user types.
/// - [rateLimitedUntil]: RATE_LIMITED; the field shows a countdown error and
///   Send stays disabled until it passes, then [onRateLimitElapsed] fires.
/// - [failureMessage]: network / other failure, drawn as an inline error.
/// - [notice]: success / info line.
final class AddFriendForm extends StatelessComponent {
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

  final GlobalStateKey<AppFormState> formKey;
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

  static const String helperText = '12 letters and digits. Hyphens and spaces around it are fine.';

  @override
  Component build(BuildContext context) {
    final AddFriendNotice? note = notice;
    final String? failure = failureMessage;
    return AppCard(
      color: AppColors.white,
      child: AppForm(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteractionIfError,
        child: div(classes: 'add-friend-form', <Component>[
          div(classes: 'add-friend-form__heading', <Component>[
            h2(classes: 'add-friend-form__title', <Component>[Component.text('Add a friend')]),
            p(classes: 'add-friend-form__text', <Component>[
              Component.text(
                'Ask for their friend code and send a request. '
                'They accept it from their notifications.',
              ),
            ]),
          ]),
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
          if (serverError == null && rateLimitedUntil == null && failure == null && note == null)
            p(classes: 'add-friend-form__helper', <Component>[Component.text(helperText)]),
          if (failure != null) AppInlineError(failure),
          if (note != null)
            AppNotice(
              message: note.message,
              tone: note.tone,
              actionLabel: note.actionLabel,
              onAction: note.onAction,
            ),
        ]),
      ),
    );
  }
}

/// The input and the Send button. Owns the one-second tick of a rate limit
/// so only this row rebuilds.
final class _FieldRow extends StatefulComponent {
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
    _lastText = component.controller.text;
    component.controller.addListener(_onTextChanged);
    _syncTimer();
  }

  @override
  void didUpdateComponent(_FieldRow oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.controller != component.controller) {
      oldComponent.controller.removeListener(_onTextChanged);
      component.controller.addListener(_onTextChanged);
      _lastText = component.controller.text;
    }
    if (oldComponent.rateLimitedUntil != component.rateLimitedUntil) _syncTimer();
  }

  @override
  void dispose() {
    component.controller.removeListener(_onTextChanged);
    _timer?.cancel();
    super.dispose();
  }

  /// A change of the text clears a server error.
  void _onTextChanged() {
    final String text = component.controller.text;
    if (text == _lastText) return;
    _lastText = text;
    if (component.serverError != null) component.onEdited?.call();
  }

  Duration? _computeRemaining() {
    final DateTime? until = component.rateLimitedUntil;
    if (until == null) return null;
    final Duration left = until.difference(DateTime.now().add(component.clockOffset));
    return left > Duration.zero ? left : null;
  }

  void _syncTimer() {
    _timer?.cancel();
    _timer = null;
    _remaining = _computeRemaining();
    if (component.rateLimitedUntil == null) return;
    if (_remaining == null) {
      // Already over: tell the owner after this frame.
      context.binding.addPostFrameCallback(() {
        if (mounted) component.onRateLimitElapsed?.call();
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
      component.onRateLimitElapsed?.call();
      return;
    }
    if (next.inSeconds != _remaining?.inSeconds) {
      setState(() => _remaining = next);
    }
  }

  void _submit() {
    if (component.isSending || _remaining != null) return;
    component.onSubmit();
  }

  @override
  Component build(BuildContext context) {
    final Duration? left = _remaining;
    final bool isRateLimited = left != null;
    final String? errorText = isRateLimited
        ? 'Too many requests. Try again in '
              '${DisplayFormatters.clock(Duration(seconds: left.inSeconds + 1))}.'
        : component.serverError;
    return div(classes: 'add-friend-form__row', <Component>[
      div(classes: 'add-friend-form__field', <Component>[
        AppTextField(
          label: 'Friend code',
          hintText: 'ABCD-2345-EFGH',
          controller: component.controller,
          focusNode: component.focusNode,
          validator: FriendCodeInput.validate,
          enabled: !component.isSending,
          errorText: errorText,
          textInputAction: TextInputAction.send,
          onFieldSubmitted: (_) => _submit(),
          inputFormatters: const <TextInputFormatter>[
            LengthLimitingTextInputFormatter(FriendCodeInput.maxLength),
          ],
        ),
      ]),
      // Aligns the button with the 48 px input under its label.
      div(classes: 'add-friend-form__send', <Component>[
        ListenableBuilder(
          listenable: component.controller,
          builder: (BuildContext context) => AppButton(
            label: 'Send',
            variant: AppButtonVariant.dark,
            size: AppButtonSize.field,
            isLoading: component.isSending,
            onPressed: component.controller.text.trim().isEmpty || isRateLimited ? null : _submit,
          ),
        ),
      ]),
    ]);
  }
}

@css
List<StyleRule> get addFriendFormStyles => <StyleRule>[
  css('.add-friend-form').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(16)),
  ),
  css('.add-friend-form__heading').styles(
    display: Display.flex,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(4)),
  ),
  css('.add-friend-form__title').combine(AppTextStyles.titleMd),
  css('.add-friend-form__text')
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(color: AppColors.muted, lineHeight: Unit.pixels(18))),
  css('.add-friend-form__row').styles(
    display: Display.flex,
    alignItems: AlignItems.start,
    gap: const Gap.column(Unit.pixels(10)),
  ),
  css('.add-friend-form__field').styles(
    minWidth: Unit.zero,
    flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
  ),
  css('.add-friend-form__send').styles(
    padding: const Padding.only(top: Unit.pixels(22)),
    flex: const Flex(shrink: 0),
  ),
  css('.add-friend-form__helper').combine(AppTextStyles.bodySm).combine(const Styles(color: AppColors.muted)),
];
