import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/workout/data/models/exercise_model.dart';

void main() {
  test(
    'conserva extras y relación de sustitución al serializar el ejercicio real',
    () {
      final model = ExerciseModel.fromJson({
        'id': 'press-machine',
        'routine_day_id': 'day',
        'name': 'Press máquina',
        'muscle_group': 'Pecho',
        'target_sets': 2,
        'target_reps': 10,
        'target_weight': 25,
        'is_extra': true,
        'replaces_exercise_name': 'Press banca',
        'replaced_by_exercise_name': null,
      });
      final json = ExerciseModel.fromEntity(model.toEntity()).toJson();
      expect(json['is_extra'], true);
      expect(json['replaces_exercise_name'], 'Press banca');
      expect(json['id'], 'press-machine');
      expect(json['target_sets'], 2);
    },
  );
}
