import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/workout/data/models/routine_model.dart';
import 'package:gym_flutter/features/workout/data/models/routine_day_model.dart';
import 'package:gym_flutter/features/workout/data/models/exercise_model.dart';
import 'package:gym_flutter/features/workout/data/models/set_log_model.dart';
import 'package:gym_flutter/features/workout/data/models/workout_session_model.dart';

void main() {
  group('Workout Models JSON', () {
    test('RoutineModel should map from/to JSON', () {
      final json = {
        'id': '1',
        'name': 'R1',
        'exercise_count': 5,
        'is_public': true,
      };
      final model = RoutineModel.fromJson(json);
      expect(model.id, '1');
      expect(model.toJson()['name'], 'R1');
    });

    test('RoutineDayModel should map from/to JSON', () {
      final json = {
        'id': '1',
        'routine_id': 'r1',
        'day_of_week': 1,
        'name': 'D1',
      };
      final model = RoutineDayModel.fromJson(json);
      expect(model.id, '1');
      expect(model.toJson()['day_of_week'], 1);
    });

    test('ExerciseModel should map from/to JSON (muscle_group canon)', () {
      final json = {
        'id': '1',
        'routine_day_id': 'rd1',
        'name': 'E1',
        'muscle_group': 'Chest',
        'target_weight': 100.0,
        'target_reps': 10,
        'target_sets': 3,
        'rest_timer_seconds': 60,
      };
      final model = ExerciseModel.fromJson(json);
      expect(model.id, '1');
      expect(model.targetMuscle, 'Chest');
      final out = model.toJson();
      expect(out['target_reps'], 10);
      expect(out['muscle_group'], 'Chest');
    });

    test(
      'ExerciseModel.fromJson ignora `target_muscle` legacy y deja '
      'targetMuscle vacío (con warn) — el campo canónico es `muscle_group`',
      () {
        final json = {
          'id': '1',
          'routine_day_id': 'rd1',
          'name': 'E1',
          'target_muscle': 'LegacyMuscle',
        };
        final model = ExerciseModel.fromJson(json);
        expect(model.targetMuscle, '');
      },
    );

    test('SetLogModel should map from/to JSON', () {
      final json = {
        'id': '1',
        'session_id': 's1',
        'exercise_id': 'e1',
        'set_index': 1,
        'actual_weight': 10.0,
        'actual_reps': 10,
        'created_at': '2026-01-01T00:00:00.000',
      };
      final model = SetLogModel.fromJson(json);
      expect(model.id, '1');
      expect(model.toJson()['actual_reps'], 10);
    });

    test('WorkoutSessionModel should map from/to JSON', () {
      final json = {
        'id': '1',
        'user_id': 'u1',
        'routine_day_id': 'd1',
        'session_date': '2026-01-01',
        'completed_at': null,
        'total_completed_sets': 5,
        'total_target_sets': 10,
      };
      final model = WorkoutSessionModel.fromJson(json);
      expect(model.id, '1');
      expect(model.toJson()['completed_sets_count'], 5);
    });
  });
}
