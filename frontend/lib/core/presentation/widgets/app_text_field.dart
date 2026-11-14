import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';
import 'package:skill_battles/core/presentation/widgets/app_text_link.dart';

/// A labelled text input of the Paper design: the label above, one
/// [TextFormField] whose decoration draws the whole 48 px box (so a tap
/// anywhere on it focuses the input), and helper or error text below.
///
/// Borders come from the theme: light at rest, blue 1.5 px when focused,
/// red 1.5 px with an error. A tap on the label focuses the input too, and
/// assistive technology reads the label with the field.
final class AppTextField extends StatefulWidget {
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
    this.inputFormatters,
    this.onFieldSubmitted,
    super.key,
  });

  final String label;
  final TextEditingController controller;

  /// Focus of the input; when `null` the field owns one.
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
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

final class _AppTextFieldState extends State<AppTextField> {
  static const double _inset = 14;

  /// Used whenever the caller passes no focus node (also after it stops
  /// passing one); owned and disposed here.
  late final FocusNode _ownFocusNode;
  late bool _isRevealed;

  FocusNode get _focusNode => widget.focusNode ?? _ownFocusNode;

  @override
  void initState() {
    super.initState();
    _ownFocusNode = FocusNode();
    _isRevealed = false;
  }

  @override
  void dispose() {
    _ownFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppTextField field = widget;
    final bool obscure = field.obscureText && !_isRevealed;
    final Widget suffix = field.obscureText && field.canReveal
        ? Padding(
            padding: const EdgeInsets.only(left: 8, right: _inset),
            child: AppTextLink(
              label: _isRevealed ? 'Hide' : 'Show',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
              onPressed: () => setState(() => _isRevealed = !_isRevealed),
            ),
          )
        : const SizedBox(width: _inset);

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: <Widget>[
          MouseRegion(
            cursor: SystemMouseCursors.text,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: _focusNode.requestFocus,
              child: Text(
                field.label,
                style: AppTextStyles.bodySm.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          TextFormField(
            controller: field.controller,
            focusNode: _focusNode,
            validator: field.validator,
            obscureText: obscure,
            enabled: field.enabled,
            obscuringCharacter: '•',
            keyboardType: field.keyboardType,
            textInputAction: field.textInputAction,
            autofillHints: field.autofillHints,
            inputFormatters: field.inputFormatters,
            onFieldSubmitted: field.onFieldSubmitted,
            style: AppTextStyles.bodyLg.copyWith(
              letterSpacing: obscure ? 0.2 * 15 : null,
              color: field.enabled ? AppColors.ink : AppColors.muted,
            ),
            decoration: InputDecoration(
              filled: !field.enabled,
              fillColor: AppColors.surface,
              disabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide.none,
              ),
              hintText: field.hintText,
              // The input's dot spacing must not reach the hint.
              hintStyle: AppTextStyles.bodyLg.copyWith(
                color: AppColors.faint,
                letterSpacing: 0,
              ),
              helperText: field.helperText,
              errorText: field.errorText,
              helperStyle: AppTextStyles.bodySm.copyWith(
                color: AppColors.muted,
              ),
              // The 14 px inner inset is drawn by spacers instead of the
              // content padding, so helper and error text start flush with the
              // box edge as in Paper (Flutter indents them by the padding).
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
              prefixIcon: const SizedBox(width: _inset),
              prefixIconConstraints: const BoxConstraints.tightFor(
                width: _inset,
              ),
              suffixIcon: suffix,
              suffixIconConstraints: const BoxConstraints(minWidth: _inset),
            ),
          ),
        ],
      ),
    );
  }
}
