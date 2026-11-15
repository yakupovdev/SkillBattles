import 'package:flutter_test/flutter_test.dart';

import 'package:skill_battles/core/data/models/question_model.dart';
import 'package:skill_battles/core/domain/entity/question_entity.dart';

const String _imageUrl =
    '/media/questions/SAT_MATH/3f5a3602/'
    '224eefc655e44ddac7e07d499e9fad2ba90e28bd8db675e8cd15b31156b7a203.png';

Map<String, dynamic> _json() => <String, dynamic>{
  'id': '44444444-4444-4444-8444-444444444444',
  'topicCode': 'ALGEBRA_LINEAR_SYSTEMS',
  'difficulty': 'HARD',
  'topicName': 'Algebra / Systems of two linear equations in two variables',
  'prompt': r'What system is represented by the lines shown in the $xy$-plane?',
  'options': <Map<String, dynamic>>[
    <String, dynamic>{'id': 'a', 'key': 'A', 'text': r'$8x + 4y = 32$'},
    <String, dynamic>{'id': 'b', 'key': 'B', 'text': r'$8x - 4y = 32$'},
  ],
};

void main() {
  group('QuestionModel.imageUrl', () {
    test('maps a present URL to the entity unchanged', () {
      final QuestionEntity entity = QuestionModel.fromJson(
        _json()..['imageUrl'] = _imageUrl,
      ).toEntity();
      expect(entity.imageUrl, _imageUrl);
    });

    test('maps an explicit null to null', () {
      final QuestionEntity entity = QuestionModel.fromJson(
        _json()..['imageUrl'] = null,
      ).toEntity();
      expect(entity.imageUrl, isNull);
    });

    test('treats an absent key (older snapshots) as null', () {
      expect(QuestionModel.fromJson(_json()).toEntity().imageUrl, isNull);
    });

    test('rejects a non-string value', () {
      expect(
        () => QuestionModel.fromJson(_json()..['imageUrl'] = 42),
        throwsA(isA<Exception>()),
      );
    });

    test('takes part in entity equality', () {
      final QuestionEntity withImage = QuestionModel.fromJson(
        _json()..['imageUrl'] = _imageUrl,
      ).toEntity();
      final QuestionEntity without = QuestionModel.fromJson(_json()).toEntity();
      expect(withImage, isNot(without));
      expect(
        withImage,
        QuestionModel.fromJson(_json()..['imageUrl'] = _imageUrl).toEntity(),
      );
    });
  });
}
