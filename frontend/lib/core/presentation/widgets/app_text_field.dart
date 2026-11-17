import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_form.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_input.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_link.dart';

/// A labelled text input of the Paper design: the label above, the 48 px
/// box, and helper or error text below.
///
/// Borders: light at rest, blue 1.5 px when focused, red 1.5 px with an
/// error. A click anywhere on the box or on the label focuses the input, and
/// assistive technology reads the label, the helper and the error with the
/// field.
///
/// Inside an [AppForm] the [validator] runs on `AppFormState.validate()` (and
/// after edits, per the form's [AutovalidateMode]).
final class AppTextField extends StatefulComponent {
  const AppTextField({
    required this.label,
    required this.controller,
    this.focusNode,
    this.validator,
    this.helperText,
    this.errorText,
    this.hintText,
    this.obscureText = false,
    this.canReveal = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.name,
    this.inputFormatters,
    this.onFieldSubmitted,
    super.key,
  });

  final String label;
  final TextEditingController controller;

  /// Focus of the input; when `null` the field has no external focus handle.
  final FocusNode? focusNode;
  final FormFieldValidator<String>? validator;
  final String? helperText;

  /// An error from outside the form (for example the server). A validator
  /// message, when there is one, is shown instead of it.
  final String? errorText;
  final String? hintText;
  final bool obscureText;

  /// With [obscureText]: a "Show" / "Hide" toggle at the right edge.
  final bool canReveal;

  /// `false` draws the read-only grey box with muted text (an email that
  /// can't be changed).
  final bool enabled;

  /// The input type (`InputType.email`, `InputType.number`, ...); text by
  /// default, password with [obscureText].
  final InputType? keyboardType;
  final TextInputAction? textInputAction;

  /// `autocomplete` tokens ([AutofillHints]).
  final Iterable<String>? autofillHints;

  /// The `name` of the input, which password managers use with
  /// [autofillHints] to recognise login and sign-up fields.
  final String? name;
  final List<TextInputFormatter>? inputFormatters;

  /// Enter in the input. Without it Enter submits the enclosing form.
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

final class _AppTextFieldState extends State<AppTextField> implements AppFormFieldHandle {
  static int _nextId = 0;

  late String _id;
  late bool _isRevealed;
  late bool _isFocused;
  late GlobalNodeKey<web.HTMLInputElement> _inputKey;
  String? _validationError;
  AppFormState? _form;

  @override
  void initState() {
    super.initState();
    _id = 'app-text-field-${_nextId++}';
    _isRevealed = false;
    _isFocused = false;
    _inputKey = GlobalNodeKey<web.HTMLInputElement>();
    component.controller.addListener(_onControllerChanged);
    context.binding.addPostFrameCallback(_attachFocusNode);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final AppFormState? form = AppForm.maybeOf(context);
    if (identical(form, _form)) return;
    _form?.unregister(this);
    _form = form?..register(this);
  }

  @override
  void didUpdateComponent(AppTextField oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (!identical(oldComponent.controller, component.controller)) {
      oldComponent.controller.removeListener(_onControllerChanged);
      component.controller.addListener(_onControllerChanged);
    }
    if (!identical(oldComponent.focusNode, component.focusNode)) {
      oldComponent.focusNode?.detachElement(_inputKey.currentNode);
      _attachFocusNode();
    }
  }

  @override
  void dispose() {
    component.controller.removeListener(_onControllerChanged);
    component.focusNode?.detachElement(_inputKey.currentNode);
    _form?.unregister(this);
    super.dispose();
  }

  void _attachFocusNode() {
    final web.HTMLInputElement? input = _inputKey.currentNode;
    if (!mounted || input == null) return;
    component.focusNode?.attachElement(input);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onInput(web.Event event) {
    final web.HTMLInputElement input = event.target! as web.HTMLInputElement;
    final String previous = component.controller.text;
    String next = input.value;
    for (final TextInputFormatter formatter in component.inputFormatters ?? const <TextInputFormatter>[]) {
      next = formatter.formatEditUpdate(previous, next);
    }
    if (next != input.value) input.value = next;
    component.controller.text = next;
    if (shouldValidateOnChange(_form, hasError: _validationError != null)) {
      setState(() => _validationError = component.validator?.call(next));
    }
  }

  void _onKeyDown(web.Event event) {
    final ValueChanged<String>? submit = component.onFieldSubmitted;
    if (submit == null || (event as web.KeyboardEvent).key != 'Enter' || event.isComposing) return;
    event.preventDefault();
    submit(component.controller.text);
  }

  void _setFocused(bool isFocused) {
    component.focusNode?.updateFocus(isFocused);
    setState(() => _isFocused = isFocused);
  }

  @override
  bool validate() {
    final String? error = component.validator?.call(component.controller.text);
    if (mounted) setState(() => _validationError = error);
    return error == null;
  }

  @override
  void reset() {
    if (mounted) setState(() => _validationError = null);
  }

  @override
  Component build(BuildContext context) {
    final AppTextField field = component;
    if (_form?.autovalidateMode == AutovalidateMode.always) {
      _validationError = field.validator?.call(field.controller.text);
    }
    final bool obscure = field.obscureText && !_isRevealed;
    final String? error = _validationError ?? field.errorText;
    final String? helper = error == null ? field.helperText : null;
    final String? note = error ?? helper;
    final String noteId = '$_id-note';
    final Iterable<String>? autofill = field.autofillHints;
    final InputType type = obscure ? InputType.password : field.keyboardType ?? InputType.text;

    return div(classes: 'app-text-field', <Component>[
      label(
        htmlFor: _id,
        classes: 'app-text-field__label',
        <Component>[Component.text(field.label)],
      ),
      div(
        classes: <String>[
          'app-text-field__box',
          if (_isFocused) 'app-text-field__box--focused',
          if (error != null) 'app-text-field__box--error',
          if (!field.enabled) 'app-text-field__box--disabled',
        ].join(' '),
        events: <String, void Function(web.Event)>{
          'mousedown': (web.Event event) {
            // A press on the padding focuses the input instead of blurring it.
            if (event.target != _inputKey.currentNode) {
              event.preventDefault();
              _inputKey.currentNode?.focus();
            }
          },
        },
        <Component>[
          input<String>(
            key: _inputKey,
            id: _id,
            type: type,
            value: field.controller.text,
            disabled: !field.enabled,
            classes: obscure && field.controller.text.isNotEmpty
                ? 'app-text-field__input app-text-field__input--obscured'
                : 'app-text-field__input',
            attributes: <String, String>{
              'placeholder': ?field.hintText,
              if (autofill != null && autofill.isNotEmpty) 'autocomplete': autofill.join(' '),
              if (field.name != null) 'name': field.name!,
              'enterkeyhint': ?field.textInputAction?.value,
              if (note != null) 'aria-describedby': noteId,
              if (error != null) 'aria-invalid': 'true',
            },
            events: <String, void Function(web.Event)>{
              'input': _onInput,
              'keydown': _onKeyDown,
              'focus': (web.Event _) => _setFocused(true),
              'blur': (web.Event _) => _setFocused(false),
            },
          ),
          if (field.obscureText && field.canReveal)
            div(classes: 'app-text-field__reveal', <Component>[
              AppTextLink(
                label: _isRevealed ? 'Hide' : 'Show',
                style: AppTextStyles.bodySm.combine(
                  const Styles(color: AppColors.muted, fontWeight: FontWeight.w500),
                ),
                onPressed: () => setState(() => _isRevealed = !_isRevealed),
              ),
            ]),
        ],
      ),
      if (note != null)
        p(
          id: noteId,
          classes: error == null ? 'app-text-field__note' : 'app-text-field__note app-text-field__note--error',
          attributes: error == null ? null : const <String, String>{'aria-live': 'polite'},
          <Component>[Component.text(note)],
        ),
    ]);
  }
}

@css
List<StyleRule> get appTextFieldStyles => <StyleRule>[
  css('.app-text-field').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(6)),
  ),
  css('.app-text-field__label')
      .styles(cursor: Cursor.text, alignSelf: AlignSelf.start)
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(fontWeight: FontWeight.w500)),
  css('.app-text-field__box').styles(
    display: Display.flex,
    height: const Unit.pixels(48),
    border: Border.all(color: AppColors.border, width: const Unit.pixels(1)),
    radius: const BorderRadius.circular(Unit.pixels(10)),
    cursor: Cursor.text,
    alignItems: AlignItems.center,
    backgroundColor: AppColors.white,
  ),
  css('.app-text-field__box--focused').styles(
    border: Border.all(color: AppColors.primary, width: const Unit.pixels(1)),
    raw: const <String, String>{'box-shadow': 'inset 0 0 0 0.5px #2B4BF2'},
  ),
  css('.app-text-field__box--error').styles(
    border: Border.all(color: AppColors.danger, width: const Unit.pixels(1)),
    raw: const <String, String>{'box-shadow': 'inset 0 0 0 0.5px #E5484D'},
  ),
  css('.app-text-field__box--disabled').styles(
    border: Border.all(color: Colors.transparent, width: const Unit.pixels(1)),
    cursor: Cursor.defaultCursor,
    backgroundColor: AppColors.surface,
  ),
  css('.app-text-field__input')
      .styles(
        height: const Unit.percent(100),
        minWidth: Unit.zero,
        padding: const Padding.symmetric(horizontal: Unit.pixels(14)),
        flex: const Flex(grow: 1, shrink: 1, basis: Unit.zero),
        backgroundColor: Colors.transparent,
        raw: const <String, String>{'border': 'none', 'outline': 'none'},
      )
      .combine(AppTextStyles.bodyLg)
      .combine(const Styles(raw: <String, String>{'caret-color': '#2B4BF2'})),
  css('.app-text-field__input:focus-visible').styles(raw: const <String, String>{'outline': 'none'}),
  css('.app-text-field__input:disabled').styles(
    color: AppColors.muted,
    raw: const <String, String>{'-webkit-text-fill-color': '#6B6F7A', 'opacity': '1'},
  ),
  css('.app-text-field__input--obscured').styles(letterSpacing: const Unit.pixels(3)),
  css('.app-text-field__input::placeholder').styles(
    opacity: 1,
    color: AppColors.faint,
    letterSpacing: Unit.zero,
  ),
  css('.app-text-field__reveal').styles(
    display: Display.flex,
    padding: const Padding.only(left: Unit.pixels(8), right: Unit.pixels(14)),
    flex: const Flex(shrink: 0),
  ),
  css('.app-text-field__note').combine(AppTextStyles.bodySm).combine(const Styles(color: AppColors.muted)),
  css('.app-text-field__note--error').styles(color: AppColors.danger),
];
