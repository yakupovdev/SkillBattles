import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_icons.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_svg_icon.dart';

/// A labelled dropdown matching `AppTextField`: label above, a 48 px box.
final class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    required this.label,
    required this.items,
    required this.labelOf,
    required this.value,
    required this.onChanged,
    this.validator,
    this.hintText,
    this.fieldKey,
    this.style,
    super.key,
  });

  final String label;
  final List<T> items;
  final String Function(T value) labelOf;
  final T? value;
  final ValueChanged<T?> onChanged;
  final FormFieldValidator<T>? validator;
  final String? hintText;
  final GlobalKey<FormFieldState<T>>? fieldKey;

  /// Style of the value; body text by default (the birth year is mono).
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: <Widget>[
          Text(
            label,
            style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w500),
          ),
          DropdownButtonFormField<T>(
            key: fieldKey,
            initialValue: value,
            validator: validator,
            onChanged: onChanged,
            style: style ?? AppTextStyles.bodyLg,
            borderRadius: BorderRadius.circular(10),
            icon: const AppSvgIcon(AppIcons.chevronDown, width: 14, height: 14),
            menuMaxHeight: 320,
            hint: hintText == null ? null : Text(hintText!),
            items: <DropdownMenuItem<T>>[
              for (final T item in items)
                DropdownMenuItem<T>(value: item, child: Text(labelOf(item))),
            ],
          ),
        ],
      ),
    );
  }
}
