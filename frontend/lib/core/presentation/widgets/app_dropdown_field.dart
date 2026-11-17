import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_form.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';

/// A labelled dropdown matching `AppTextField`: label above, a 48 px box
/// (a native `<select>`, so the menu is the browser's), error below.
///
/// Inside an [AppForm] the [validator] runs on `AppFormState.validate()`.
final class AppDropdownField<T> extends StatefulComponent {
  const AppDropdownField({
    required this.label,
    required this.items,
    required this.labelOf,
    required this.value,
    required this.onChanged,
    this.validator,
    this.hintText,
    this.style,
    super.key,
  });

  final String label;
  final List<T> items;
  final String Function(T value) labelOf;

  /// The selected item; `null` shows [hintText].
  final T? value;
  final ValueChanged<T?> onChanged;
  final FormFieldValidator<T>? validator;
  final String? hintText;

  /// Style of the value; body text by default (the birth year is mono).
  final Styles? style;

  @override
  State<AppDropdownField<T>> createState() => _AppDropdownFieldState<T>();
}

final class _AppDropdownFieldState<T> extends State<AppDropdownField<T>> implements AppFormFieldHandle {
  static int _nextId = 0;

  late String _id;
  String? _error;
  AppFormState? _form;

  @override
  void initState() {
    super.initState();
    _id = 'app-dropdown-field-${_nextId++}';
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

  @override
  bool validate() {
    final String? error = component.validator?.call(component.value);
    if (mounted) setState(() => _error = error);
    return error == null;
  }

  @override
  void reset() {
    if (mounted) setState(() => _error = null);
  }

  void _onChange(web.Event event) {
    final int? index = int.tryParse((event.target! as web.HTMLSelectElement).value);
    final T? picked = index == null || index < 0 || index >= component.items.length ? null : component.items[index];
    component.onChanged(picked);
    if (shouldValidateOnChange(_form, hasError: _error != null)) {
      setState(() => _error = component.validator?.call(picked));
    }
  }

  @override
  Component build(BuildContext context) {
    final AppDropdownField<T> field = component;
    if (_form?.autovalidateMode == AutovalidateMode.always) {
      _error = field.validator?.call(field.value);
    }
    final String? error = _error;
    final int selected = field.value == null ? -1 : field.items.indexOf(field.value as T);
    final String errorId = '$_id-error';

    return div(classes: 'app-dropdown-field', <Component>[
      label(htmlFor: _id, classes: 'app-dropdown-field__label', <Component>[Component.text(field.label)]),
      div(
        classes: error == null ? 'app-dropdown-field__box' : 'app-dropdown-field__box app-dropdown-field__box--error',
        <Component>[
          select(
            id: _id,
            value: selected < 0 ? '' : '$selected',
            classes: selected < 0
                ? 'app-dropdown-field__select app-dropdown-field__select--hint'
                : 'app-dropdown-field__select',
            styles: selected < 0 ? field.style?.combine(const Styles(color: AppColors.faint)) : field.style,
            attributes: <String, String>{
              if (error != null) 'aria-invalid': 'true',
              if (error != null) 'aria-describedby': errorId,
            },
            events: <String, void Function(web.Event)>{'change': _onChange},
            <Component>[
              option(
                value: '',
                disabled: true,
                selected: selected < 0,
                attributes: const <String, String>{'hidden': ''},
                <Component>[Component.text(field.hintText ?? '')],
              ),
              for (int i = 0; i < field.items.length; i++)
                option(
                  value: '$i',
                  selected: i == selected,
                  <Component>[Component.text(field.labelOf(field.items[i]))],
                ),
            ],
          ),
          const span(classes: 'app-dropdown-field__chevron', <Component>[
            AppSvgIcon(AppIcons.chevronDown, width: 14, height: 14),
          ]),
        ],
      ),
      if (error != null)
        p(
          id: errorId,
          classes: 'app-dropdown-field__error',
          attributes: const <String, String>{'aria-live': 'polite'},
          <Component>[Component.text(error)],
        ),
    ]);
  }
}

@css
List<StyleRule> get appDropdownFieldStyles => <StyleRule>[
  css('.app-dropdown-field').styles(
    display: Display.flex,
    minWidth: Unit.zero,
    flexDirection: FlexDirection.column,
    gap: const Gap.row(Unit.pixels(6)),
  ),
  css('.app-dropdown-field__label')
      .styles(alignSelf: AlignSelf.start)
      .combine(AppTextStyles.bodySm)
      .combine(const Styles(fontWeight: FontWeight.w500)),
  css('.app-dropdown-field__box').styles(position: const Position.relative(), height: const Unit.pixels(48)),
  css('.app-dropdown-field__select')
      .styles(
        width: const Unit.percent(100),
        height: const Unit.percent(100),
        padding: const Padding.only(left: Unit.pixels(14), right: Unit.pixels(36)),
        border: Border.all(color: AppColors.border, width: const Unit.pixels(1)),
        radius: const BorderRadius.circular(Unit.pixels(10)),
        appearance: Appearance.none,
        cursor: Cursor.pointer,
        backgroundColor: AppColors.white,
      )
      .combine(AppTextStyles.bodyLg),
  css('.app-dropdown-field__select:focus-visible').styles(
    border: Border.all(color: AppColors.primary, width: const Unit.pixels(1)),
    raw: const <String, String>{'outline': 'none', 'box-shadow': 'inset 0 0 0 0.5px #2B4BF2'},
  ),
  css('.app-dropdown-field__box--error .app-dropdown-field__select').styles(
    border: Border.all(color: AppColors.danger, width: const Unit.pixels(1)),
    raw: const <String, String>{'box-shadow': 'inset 0 0 0 0.5px #E5484D'},
  ),
  css('.app-dropdown-field__select--hint').styles(color: AppColors.faint),
  css('.app-dropdown-field__select option').styles(color: AppColors.ink),
  css('.app-dropdown-field__chevron').styles(
    display: Display.flex,
    position: const Position.absolute(top: Unit.zero, right: Unit.pixels(14), bottom: Unit.zero),
    pointerEvents: PointerEvents.none,
    alignItems: AlignItems.center,
  ),
  css('.app-dropdown-field__error').combine(AppTextStyles.bodySm).combine(const Styles(color: AppColors.danger)),
];
