import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

/// Text-input plumbing with the Flutter vocabulary, for `AppTextField` and
/// the feature forms: [TextEditingController], [FocusNode],
/// [TextInputFormatter]s, [AutofillHints] and [TextInputAction].

/// The text of an input, owned by the screen's `State` (create it in
/// `initState`, dispose it in `dispose`). Listeners are notified on every
/// change, typed or set from code.
final class TextEditingController extends ChangeNotifier {
  TextEditingController({this._text = ''});

  String _text;

  String get text => _text;

  set text(String value) {
    if (value == _text) return;
    _text = value;
    notifyListeners();
  }

  void clear() => text = '';
}

/// Keyboard focus of one element (an input, or any focusable element).
///
/// The component that renders the element attaches it with
/// [attachElement] / [detachElement] and reports focus changes with
/// [updateFocus]; owners call [requestFocus] / [unfocus] and read
/// [hasFocus] (listeners are notified when it changes).
final class FocusNode extends ChangeNotifier {
  web.HTMLElement? _element;
  bool _hasFocus = false;

  bool get hasFocus => _hasFocus;

  /// Moves the keyboard focus to the attached element.
  void requestFocus() => _element?.focus();

  /// Removes the keyboard focus from the attached element.
  void unfocus() => _element?.blur();

  void attachElement(web.HTMLElement element) => _element = element;

  void detachElement(web.HTMLElement? element) {
    if (element == null || identical(_element, element)) _element = null;
  }

  void updateFocus(bool hasFocus) {
    if (hasFocus == _hasFocus) return;
    _hasFocus = hasFocus;
    notifyListeners();
  }
}

/// Rewrites a typed value before it reaches the controller — the
/// counterpart of Flutter's `TextInputFormatter`.
abstract class TextInputFormatter {
  const TextInputFormatter();

  /// [newValue] as it should be stored; [oldValue] is the previous text.
  String formatEditUpdate(String oldValue, String newValue);
}

/// Cuts the value to [maxLength] characters.
final class LengthLimitingTextInputFormatter extends TextInputFormatter {
  const LengthLimitingTextInputFormatter(this.maxLength);

  final int maxLength;

  @override
  String formatEditUpdate(String oldValue, String newValue) {
    final List<int> runes = newValue.runes.toList();
    return runes.length <= maxLength ? newValue : String.fromCharCodes(runes.take(maxLength));
  }
}

/// Keeps ([FilteringTextInputFormatter.allow]) or drops
/// ([FilteringTextInputFormatter.deny]) the characters matching [pattern].
final class FilteringTextInputFormatter extends TextInputFormatter {
  FilteringTextInputFormatter.allow(this.pattern) : isAllow = true;

  FilteringTextInputFormatter.deny(this.pattern) : isAllow = false;

  /// Only the digits 0–9.
  static final FilteringTextInputFormatter digitsOnly = FilteringTextInputFormatter.allow(RegExp('[0-9]'));

  final Pattern pattern;
  final bool isAllow;

  @override
  String formatEditUpdate(String oldValue, String newValue) {
    if (!isAllow) return newValue.replaceAll(pattern, '');
    return pattern.allMatches(newValue).map((Match match) => match[0]).join();
  }
}

/// `autocomplete` tokens with the names of Flutter's `AutofillHints`.
abstract final class AutofillHints {
  static const String email = 'email';
  static const String username = 'username';
  static const String newUsername = 'username';
  static const String nickname = 'nickname';
  static const String password = 'current-password';
  static const String newPassword = 'new-password';
  static const String oneTimeCode = 'one-time-code';
}

/// The label of the Enter key on virtual keyboards (`enterkeyhint`).
enum TextInputAction {
  done('done'),
  go('go'),
  next('next'),
  previous('previous'),
  search('search'),
  send('send');

  const TextInputAction(this.value);

  final String value;
}
