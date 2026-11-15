import 'package:flutter_test/flutter_test.dart';

import 'package:skill_battles/core/utils/network/media_url.dart';

const String _path =
    '/media/questions/SAT_MATH/3f5a3602/'
    '224eefc655e44ddac7e07d499e9fad2ba90e28bd8db675e8cd15b31156b7a203.png';

void main() {
  group('resolveMediaUrl', () {
    test('without a configured origin keeps the page scheme, host and port '
        'and drops the page path', () {
      expect(
        resolveMediaUrl(
          _path,
          origin: '',
          base: Uri.parse('https://app.example:8443/battle/abc?x=1#top'),
        ),
        'https://app.example:8443$_path',
      );
    });

    test('a configured origin wins over the page URL', () {
      expect(
        resolveMediaUrl(
          _path,
          origin: 'http://localhost:8080',
          base: Uri.parse('http://localhost:5173/'),
        ),
        'http://localhost:8080$_path',
      );
    });

    test('a configured origin with a path does not add /api/v1 or keep it', () {
      expect(
        resolveMediaUrl(_path, origin: 'https://api.example/api/v1'),
        'https://api.example$_path',
      );
    });

    test('an absolute URL is returned as is', () {
      const String absolute = 'https://cdn.example/a.png';
      expect(resolveMediaUrl(absolute, origin: 'http://x'), absolute);
    });
  });
}
