import 'package:flutter_test/flutter_test.dart';

import 'package:gym_flutter/features/workout/domain/entities/exercise_detail.dart';

void main() {
  group('ExerciseDetail.hasRichContent', () {
    test('false cuando sólo hay id/name/muscleGroup', () {
      const d = ExerciseDetail(id: '1', name: 'Press', muscleGroup: 'Pecho');
      expect(d.hasRichContent, isFalse);
    });

    test('true cuando hay imageUrl', () {
      const d = ExerciseDetail(
        id: '1',
        name: 'Press',
        muscleGroup: 'Pecho',
        imageUrl: 'https://x/y.png',
      );
      expect(d.hasRichContent, isTrue);
    });

    test('true cuando instructions tiene contenido', () {
      const d = ExerciseDetail(
        id: '1',
        name: 'Press',
        muscleGroup: 'Pecho',
        instructions: 'Paso 1...',
      );
      expect(d.hasRichContent, isTrue);
    });

    test('false cuando instructions es sólo whitespace', () {
      const d = ExerciseDetail(
        id: '1',
        name: 'Press',
        muscleGroup: 'Pecho',
        instructions: '   \n  ',
      );
      expect(d.hasRichContent, isFalse);
    });

    test('true cuando sólo videoUrl', () {
      const d = ExerciseDetail(
        id: '1',
        name: 'Press',
        muscleGroup: 'Pecho',
        videoUrl: 'https://youtube.com/watch?v=...',
      );
      expect(d.hasRichContent, isTrue);
    });
  });
}
