import 'package:test/test.dart';

import 'package:skill_battles/features/battle_result/data/models/review_question_model.dart';
import 'package:skill_battles/features/battle_result/domain/entity/review_question_entity.dart';

const String _imageUrl =
    '/media/questions/SAT_RW/0a1b2c3d/'
    '224eefc655e44ddac7e07d499e9fad2ba90e28bd8db675e8cd15b31156b7a203.png';

Map<String, dynamic> _json() => <String, dynamic>{
  'id': '44444444-4444-4444-8444-444444444444',
  'topicCode': 'ALGEBRA_LINEAR_SYSTEMS',
  'difficulty': 'HARD',
  'topicName': 'Algebra',
  'prompt': 'Which system is shown?',
  'options': <Map<String, dynamic>>[
    <String, dynamic>{'id': 'a', 'key': 'A', 'text': '1'},
    <String, dynamic>{'id': 'd', 'key': 'D', 'text': '2'},
  ],
  'correctOptionId': null,
  'explanation': null,
};

void main() {
  group('ReviewQuestionModel.imageUrl', () {
    test('a Free review keeps the illustration while the answer stays '
        'hidden', () {
      final ReviewQuestionEntity entity = ReviewQuestionModel.fromJson(
        _json()..['imageUrl'] = _imageUrl,
      ).toEntity();
      expect(entity.question.imageUrl, _imageUrl);
      expect(entity.correctOptionId, isNull);
      expect(entity.explanation, isNull);
    });

    test('maps an explicit null to null', () {
      expect(
        ReviewQuestionModel.fromJson(_json()..['imageUrl'] = null)
            .toEntity()
            .question
            .imageUrl,
        isNull,
      );
    });

    test('treats an absent key (older saved snapshots) as null', () {
      expect(
        ReviewQuestionModel.fromJson(_json()).toEntity().question.imageUrl,
        isNull,
      );
    });
  });
}
