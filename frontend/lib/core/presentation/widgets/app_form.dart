import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

/// Validates a field value: the error text, or `null` when it is valid.
typedef FormFieldValidator<T> = String? Function(T? value);

/// When the fields of an [AppForm] validate by themselves (Flutter's
/// `AutovalidateMode`).
enum AutovalidateMode {
  /// Only on [AppFormState.validate].
  disabled,

  /// On every build.
  always,

  /// After the user changed the field.
  onUserInteraction,

  /// After the user changed a field that shows an error.
  onUserInteractionIfError,
}

/// A field of an [AppForm]: validated and reset with the form.
abstract interface class AppFormFieldHandle {
  /// Shows the validator's error (or clears it); `true` when valid.
  bool validate();

  /// Clears the error.
  void reset();
}

/// Groups fields for validation — the counterpart of Flutter's `Form`.
///
/// Renders a `<form novalidate>` that adds no layout box (`display:
/// contents`), so the browser's Enter-to-submit and password managers work.
/// Submitting (Enter in a field without `onFieldSubmitted`, or an
/// `AppButton(type: ButtonType.submit)`) calls [onSubmit]; the page never
/// reloads. Validate with a `GlobalStateKey<AppFormState>`:
/// `_formKey.currentState?.validate()`.
final class AppForm extends StatefulComponent {
  const AppForm({
    required this.child,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.onSubmit,
    super.key,
  });

  final Component child;
  final AutovalidateMode autovalidateMode;
  final VoidCallback? onSubmit;

  /// The nearest form above [context], if any.
  static AppFormState? maybeOf(BuildContext context) =>
      (context.getElementForInheritedComponentOfExactType<_AppFormScope>()?.component as _AppFormScope?)?.state;

  @override
  State<AppForm> createState() => AppFormState();
}

final class AppFormState extends State<AppForm> {
  late Set<AppFormFieldHandle> _fields;

  AutovalidateMode get autovalidateMode => component.autovalidateMode;

  @override
  void initState() {
    super.initState();
    _fields = <AppFormFieldHandle>{};
  }

  void register(AppFormFieldHandle field) => _fields.add(field);

  void unregister(AppFormFieldHandle field) => _fields.remove(field);

  /// Validates every field (all of them show their errors); `true` when all
  /// are valid.
  bool validate() {
    bool isValid = true;
    for (final AppFormFieldHandle field in _fields.toList()) {
      isValid = field.validate() && isValid;
    }
    return isValid;
  }

  /// Clears the errors of every field.
  void reset() {
    for (final AppFormFieldHandle field in _fields.toList()) {
      field.reset();
    }
  }

  @override
  Component build(BuildContext context) {
    return _AppFormScope(
      state: this,
      child: form(
        classes: 'app-form',
        noValidate: true,
        events: <String, void Function(web.Event)>{
          'submit': (web.Event event) {
            event.preventDefault();
            component.onSubmit?.call();
          },
        },
        <Component>[component.child],
      ),
    );
  }
}

final class _AppFormScope extends InheritedComponent {
  const _AppFormScope({required this.state, required super.child});

  final AppFormState state;

  @override
  bool updateShouldNotify(_AppFormScope oldComponent) => false;
}

/// A custom field of an [AppForm] — the counterpart of Flutter's
/// `FormField`: [builder] draws it from the [AppFormFieldState] (value and
/// error) and calls [AppFormFieldState.didChange] on input.
final class AppFormField<T> extends StatefulComponent {
  const AppFormField({
    required this.builder,
    this.initialValue,
    this.validator,
    super.key,
  });

  final Component Function(AppFormFieldState<T> field) builder;
  final T? initialValue;
  final FormFieldValidator<T>? validator;

  @override
  State<AppFormField<T>> createState() => AppFormFieldState<T>();
}

final class AppFormFieldState<T> extends State<AppFormField<T>> implements AppFormFieldHandle {
  late T? _value;
  String? _errorText;
  AppFormState? _form;

  T? get value => _value;

  String? get errorText => _errorText;

  bool get hasError => _errorText != null;

  @override
  void initState() {
    super.initState();
    _value = component.initialValue;
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
  void dispose() {
    _form?.unregister(this);
    super.dispose();
  }

  /// Stores a value typed or picked by the user and validates it when the
  /// form's [AutovalidateMode] asks for it.
  void didChange(T? value) {
    setState(() {
      _value = value;
      if (shouldValidateOnChange(_form, hasError: hasError)) {
        _errorText = component.validator?.call(value);
      }
    });
  }

  /// Sets the value from code without validating.
  void setValue(T? value) => setState(() => _value = value);

  @override
  bool validate() {
    final String? error = component.validator?.call(_value);
    if (mounted) setState(() => _errorText = error);
    return error == null;
  }

  @override
  void reset() {
    if (mounted) setState(() => _errorText = null);
  }

  @override
  Component build(BuildContext context) {
    if (_form?.autovalidateMode == AutovalidateMode.always) {
      _errorText = component.validator?.call(_value);
    }
    return component.builder(this);
  }
}

/// Whether a field of [form] re-validates after a user change.
bool shouldValidateOnChange(AppFormState? form, {required bool hasError}) => switch (form?.autovalidateMode) {
  AutovalidateMode.always || AutovalidateMode.onUserInteraction => true,
  AutovalidateMode.onUserInteractionIfError => hasError,
  AutovalidateMode.disabled || null => false,
};

@css
List<StyleRule> get appFormStyles => <StyleRule>[
  css('.app-form').styles(display: Display.contents),
];
