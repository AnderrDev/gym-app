import 'package:flutter_test/flutter_test.dart';

import 'package:gym_flutter/core/database/dao/workout_cache_dao.dart';
import 'package:gym_flutter/core/database/local_database.dart';
import 'package:gym_flutter/features/workout/data/datasources/workout_local_data_source_impl.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';

import '../../../../helpers/database_test_helper.dart';

void main() {
  late LocalDatabase db;
  late WorkoutLocalDataSourceImpl local;

  setUp(() {
    db = openInMemoryDb();
    local = WorkoutLocalDataSourceImpl(WorkoutCacheDao(db));
  });
  tearDown(() async => db.close());

  test('round-trip de RoutineDay conserva campos básicos', () async {
    await local.cacheRoutineDays('r1', const [
      RoutineDay(
        id: 'd1',
        routineId: 'r1',
        dayOfWeek: 1,
        name: 'Lunes',
        targetSetsCount: 12,
      ),
      RoutineDay(
        id: 'd2',
        routineId: 'r1',
        dayOfWeek: 2,
        name: 'Martes',
        status: WorkoutDayStatus.inProgress,
      ),
    ]);

    final days = await local.getRoutineDays('r1');
    expect(days.length, 2);
    expect(days[0].id, 'd1');
    expect(days[0].name, 'Lunes');
    expect(days[0].targetSetsCount, 12);
    expect(days[1].status, WorkoutDayStatus.inProgress);
  });

  test('round-trip de Exercise: orden + restTimerSeconds + targetMuscle',
      () async {
    await local.cacheExercisesForDay('d1', const [
      Exercise(
        id: 'e1',
        routineDayId: 'd1',
        name: 'Press Banca',
        targetMuscle: 'pecho',
        targetWeight: 60.0,
        targetReps: 10,
        targetSets: 4,
        restTimerSeconds: 120,
      ),
      Exercise(
        id: 'e2',
        routineDayId: 'd1',
        name: 'Press Militar',
        targetMuscle: 'hombro',
        targetWeight: 40.0,
        targetReps: 8,
      ),
    ]);

    final exercises = await local.getExercisesForDay('d1');
    expect(exercises.map((e) => e.id), ['e1', 'e2']);
    expect(exercises[0].targetMuscle, 'pecho');
    expect(exercises[0].restTimerSeconds, 120);
    expect(exercises[1].targetSets, 3); // default del entity
    expect(exercises[1].restTimerSeconds, 90); // default del entity
  });

  test(
      'getLastPerformancesForExercises devuelve null para keys sin cache y '
      'SetLog para las que sí', () async {
    final createdAt = DateTime.utc(2026, 5, 1, 9, 0, 0);
    await local.cacheLastPerformances('u1', {
      'e1': SetLog(
        id: 'sl-1',
        sessionId: 's1',
        exerciseId: 'e1',
        actualWeight: 60.0,
        actualReps: 10,
        setIndex: 0,
        createdAt: createdAt,
      ),
      'e2': null,
    });

    final map = await local.getLastPerformancesForExercises(
      'u1',
      ['e1', 'e2', 'e3'],
    );
    expect(map.keys.toSet(), {'e1', 'e2', 'e3'});
    expect(map['e1']!.actualWeight, 60.0);
    expect(map['e1']!.createdAt, createdAt);
    expect(map['e2'], isNull);
    expect(map['e3'], isNull);
  });

  test('cacheLastPerformances ignora valores null (no escribe filas)',
      () async {
    await local.cacheLastPerformances('u1', {'e1': null});
    final map = await local.getLastPerformancesForExercises('u1', ['e1']);
    expect(map['e1'], isNull);
  });
}
