import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/workout_completion.dart';

void main() {
  test('series extra de un ejercicio no completan otro pendiente', () {
    const exercises = [
      Exercise(
        id: 'main',
        routineDayId: 'd',
        name: 'Press',
        targetMuscle: 'Pecho',
        targetWeight: 20,
        targetReps: 10,
      ),
      Exercise(
        id: 'extra',
        routineDayId: 'd',
        name: 'Remo',
        targetMuscle: 'Espalda',
        targetWeight: 20,
        targetReps: 10,
        isExtra: true,
      ),
    ];
    final logs = [
      for (var i = 1; i <= 6; i++)
        SetLog(
          sessionId: 's',
          exerciseId: 'extra',
          setIndex: i,
          actualWeight: 20,
          actualReps: 10,
        ),
    ];
    expect(completedTargetSets(exercises, logs), 3);
    expect(totalTargetSets(exercises), 6);
  });
}
