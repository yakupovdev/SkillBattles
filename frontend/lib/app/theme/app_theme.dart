import 'package:material_ui/material_ui.dart';

import 'package:skill_battles/app/theme/app_colors.dart';
import 'package:skill_battles/app/theme/app_text_styles.dart';

/// Light theme built from the Paper design (the design has no dark mode).
abstract final class AppTheme {
  static ThemeData get light {
    const ColorScheme colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      secondary: AppColors.accent,
      onSecondary: AppColors.ink,
      error: AppColors.danger,
      onError: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.muted,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
    );

    const OutlineInputBorder baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: AppColors.border),
    );

    return ThemeData(
      useMaterial3: true,
      // Desktop platforms default to compact density, which shrinks inputs by
      // 8 px; the artboards are drawn at standard density.
      visualDensity: VisualDensity.standard,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.white,
      fontFamily: AppFonts.body,
      splashFactory: NoSplash.splashFactory,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primaryRing,
        selectionHandleColor: AppColors.primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        hintStyle: AppTextStyles.bodyLg.copyWith(color: AppColors.faint),
        helperStyle: AppTextStyles.bodySm.copyWith(color: AppColors.muted),
        errorStyle: AppTextStyles.bodySm.copyWith(color: AppColors.danger),
        helperMaxLines: 2,
        errorMaxLines: 2,
        border: baseBorder,
        enabledBorder: baseBorder,
        focusedBorder: baseBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: baseBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: baseBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        width: 360,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
