import 'dart:convert';

/// Shared form field validators (forms.md). Each returns the error text, or
/// `null` when the value is valid. Rules mirror the API contract; the server
/// still validates everything.
abstract final class FormValidators {
  static final RegExp _nickname = RegExp(r'^[A-Za-z0-9_-]{3,24}$');
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static const int minPasswordLength = 8;
  static const int maxPasswordBytes = 72;
  static const int maxEmailLength = 254;

  /// Length of a private duel code.
  static const int duelCodeLength = 6;
  static final RegExp _duelCode = RegExp(r'^[A-Z0-9]{6}$');

  static String? nickname(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter a nickname';
    if (!_nickname.hasMatch(text)) {
      return '3–24 characters: letters, digits, _ and -';
    }
    return null;
  }

  static String? email(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your email';
    if (text.length > maxEmailLength || !_email.hasMatch(text)) {
      return 'Enter a valid email';
    }
    return null;
  }

  /// 8–72 UTF-8 bytes, not trimmed.
  static String? password(String? value) {
    final String text = value ?? '';
    if (text.isEmpty) return 'Enter a password';
    if (text.length < minPasswordLength) {
      return 'Use at least $minPasswordLength characters';
    }
    if (utf8.encode(text).length > maxPasswordBytes) {
      return 'Use at most $maxPasswordBytes bytes';
    }
    return null;
  }

  /// The current password only needs to be present.
  static String? currentPassword(String? value) =>
      (value ?? '').isEmpty ? 'Enter your current password' : null;

  static String? duelCode(String? value) {
    if (_duelCode.hasMatch(value ?? '')) return null;
    return 'Enter the $duelCodeLength-character code';
  }

  static String? birthYear(String? value) {
    final int? year = int.tryParse(value?.trim() ?? '');
    if (year == null || year < 1900 || year > 9999) return 'Enter the year';
    return null;
  }

  static String? birthMonth(int? value) =>
      value == null ? 'Choose the month' : null;

  static String? birthDay(String? value) {
    final int? day = int.tryParse(value?.trim() ?? '');
    if (day == null || day < 1 || day > 31) return 'Enter the day';
    return null;
  }

  static String? requiredText(String? value, {required String message}) =>
      (value?.trim() ?? '').isEmpty ? message : null;
}
