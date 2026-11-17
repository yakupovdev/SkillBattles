# Forms and Submission

> Part of the mandatory architecture rules: split out of `.claude/rules/architecture.md` (screens with input fields). Same scope and source-fidelity notes as there: "Existing project conventions" are the original rules, "Added safeguards" apply where compatible with the repository.

## Existing project conventions

### Forms and submission

- Shared form widgets live in `lib/core/presentation/widgets/forms/` and stay generic: they never import feature entities. Feature data is passed in (options, label functions, texts). A picker is `AppPickerField<T>` (a `FormField<T>` with its searchable bottom sheet built in): give it `options`, `titleOf`, `subtitleOf`, `valueLabelOf`, `AppPickerSheetTexts`, `validator`, `errorText`, and `onChanged`, and read its value through a `GlobalKey<FormFieldState<T>>`. Do not create feature-specific picker fields or separate `show...Sheet` helpers.
- Text inputs are a single `TextFormField`; never wrap it in another `FormField` (it already is one). Pass `validator` straight to it, show external errors through `InputDecoration.error`, and render validator messages with `errorBuilder`, so the validator message wins.
- The `TextFormField`'s own `InputDecoration` draws the whole field box (border, fill, label, prefix/suffix icons, `constraints`). Do not draw the box with a `Container` around a borderless input: a tap anywhere on the box must focus the input, and only the decorator gives that. `AppTextField` uses a non-outline `InputBorder` so the label floats inside the box; style the label with `floatingLabelStyle` (`WidgetStateTextStyle` for the error color) and use the decoration's state borders (`enabledBorder`, `focusedBorder`, `errorBorder`, …) instead of tracking focus in a `State`.
- Every screen with input fields is a `StatefulWidget` that owns a `Form` with its own `GlobalKey<FormState>`, and one `TextEditingController` and one `FocusNode` per text field, declared as `late final` fields, created in `initState()`, and disposed in `dispose()`. Pass them into the field widgets (`AppTextField(controller:, focusNode:, validator:)`, `AppPhoneCountryFields(phoneController:, phoneFocusNode:, phoneValidator:)`, `OtpCodeField(controller:, focusNode:, validator:)`); shared field widgets never own the controller of a form field.
- Use `Form(autovalidateMode: AutovalidateMode.onUserInteractionIfError)` so errors appear on submit and clear while the user fixes them.
- Validators are the shared `FormValidators` functions (`lib/core/utils/form_validators.dart`, built on `Validators`); add new rules there, not inline in screens. A non-text input (picker) is an `AppPickerField<T>` with a `GlobalKey<FormFieldState<T>>` and a validator such as `FormValidators.selected`.
- Focus navigation: `TextInputAction.next` + `onSubmitted` requests the next field's `FocusNode`; the last field uses `done` (or submits the form).
- Submit flow: `context.hideKeyboard()` → `if (!(_formKey.currentState?.validate() ?? false)) return;` → build the `<Action>ParamsEntity` from the controllers → `bloc.add(<Action>Submitted(params))`. No business logic in widgets; no intermediate DTOs.
- BLoCs do not mirror form field values (no per-keystroke `XChanged(value)` events, no field values in state). The submit event carries the params entity; the BLoC passes it to the use case. Keep only request status, failures, and server-side field errors in state; a payload-free `XEdited`/`XFieldEdited(field)` event may clear a stale server error when the user edits.
- Server field errors (`ValidationFailure.fieldErrors`) are shown through the field's `errorText`; a local validator message takes precedence over it.
- Use cases still validate their params (single source of business rules); forms validate for immediate feedback with the same `Validators`.
- UI-only enablement (e.g. a submit button enabled once the input is complete) may read the controller through `ValueListenableBuilder`; it never replaces `validate()` on submit.
