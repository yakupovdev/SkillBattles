import 'package:flutter_test/flutter_test.dart';

import 'package:skill_battles/core/utils/form_validators.dart';

void main() {
  group('FormValidators.nickname', () {
    test('rejects null, empty and blank values', () {
      expect(FormValidators.nickname(null), 'Enter a nickname');
      expect(FormValidators.nickname(''), 'Enter a nickname');
      expect(FormValidators.nickname('   '), 'Enter a nickname');
    });

    test('rejects too short, too long and forbidden characters', () {
      expect(FormValidators.nickname('ab'), isNotNull);
      expect(FormValidators.nickname('a' * 25), isNotNull);
      expect(FormValidators.nickname('bad name'), isNotNull);
      expect(FormValidators.nickname('bad.name'), isNotNull);
    });

    test('accepts letters, digits, underscore and hyphen (trimmed)', () {
      expect(FormValidators.nickname('aliya_k'), isNull);
      expect(FormValidators.nickname('timur-b9'), isNull);
      expect(FormValidators.nickname('  abc  '), isNull);
      expect(FormValidators.nickname('a' * 24), isNull);
    });
  });

  group('FormValidators.email', () {
    test('rejects null and empty values', () {
      expect(FormValidators.email(null), 'Enter your email');
      expect(FormValidators.email(' '), 'Enter your email');
    });

    test('rejects malformed addresses', () {
      for (final String value in <String>['abc', 'a@b', '@b.co', 'a b@c.co']) {
        expect(
          FormValidators.email(value),
          'Enter a valid email',
          reason: value,
        );
      }
    });

    test('accepts a well-formed address', () {
      expect(FormValidators.email('aliya@mail.kz'), isNull);
    });
  });

  group('FormValidators.password', () {
    test('rejects null and empty values', () {
      expect(FormValidators.password(null), 'Enter a password');
      expect(FormValidators.password(''), 'Enter a password');
    });

    test('rejects a password shorter than the minimum', () {
      expect(FormValidators.password('1234567'), 'Use at least 8 characters');
    });

    test('accepts a password of the minimum length', () {
      expect(FormValidators.password('12345678'), isNull);
    });
  });

  group('FormValidators.duelCode', () {
    test('accepts six upper-case letters or digits', () {
      expect(FormValidators.duelCode('K7Q2MX'), isNull);
    });

    test('rejects shorter, longer or lower-case codes', () {
      expect(FormValidators.duelCode(null), 'Enter the 6-character code');
      expect(FormValidators.duelCode('K7Q2'), isNotNull);
      expect(FormValidators.duelCode('K7Q2MXX'), isNotNull);
      expect(FormValidators.duelCode('k7q2mx'), isNotNull);
    });
  });
}
