/// Client-side rules of a friend code, mirroring the server and
/// `SendFriendRequestUsecase`: trim, drop ASCII hyphens, upper case, then
/// exactly 12 characters without I, L, O, 0 and 1.
///
/// Lives here because `lib/core/utils/form_validators.dart` is owned by the
/// logic side; move it to `FormValidators` when convenient.
abstract final class FriendCodeInput {
  static const int maxLength = 32;

  static final RegExp _code = RegExp(
    r'^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{12}$',
  );

  static const String invalidMessage =
      'Enter 12 characters like ABCD-2345-EFGH. '
      'Codes never use I, L, O, 0 or 1.';

  /// The validator of the friend code field.
  static String? validate(String? value) {
    final String code = (value ?? '').trim().replaceAll('-', '').toUpperCase();
    return _code.hasMatch(code) ? null : invalidMessage;
  }

  /// `XXXX-XXXX-XXXX` for a 12 character code; anything else as is. Display
  /// only: copying writes the canonical code.
  static String grouped(String code) {
    if (code.length != 12) return code;
    return '${code.substring(0, 4)}-${code.substring(4, 8)}-'
        '${code.substring(8)}';
  }
}
