import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_flutter/core/database/dao/workout_cache_dao.dart';
import 'package:gym_flutter/core/database/local_database.dart';

import '../../helpers/database_test_helper.dart';

void main() {
  late LocalDatabase db;
  late WorkoutCacheDao dao;

  setUp(() {
    db = openInMemoryDb();
    dao = WorkoutCacheDao(db);
  });

  tearDown(() async => db.close());

  group('readRoutineDays / upsertRoutineDays', () {
    test(
      'upsert reemplaza el contenido por routineId y devuelve por dayOfWeek',
      () async {
        await dao.upsertRoutineDays('r1', [
          CachedRoutineDaysCompanion.insert(
            id: 'd2',
            routineId: 'r1',
            dayOfWeek: 2,
            name: 'Martes',
            fetchedAt: 1,
          ),
          CachedRoutineDaysCompanion.insert(
            id: 'd1',
            routineId: 'r1',
            dayOfWeek: 1,
            name: 'Lunes',
            fetchedAt: 1,
          ),
        ]);

        final rows = await dao.readRoutineDays('r1');
        expect(rows.map((r) => r.id), ['d1', 'd2']);

        // upsert con lista nueva borra los previos.
        await dao.upsertRoutineDays('r1', [
          CachedRoutineDaysCompanion.insert(
            id: 'd9',
            routineId: 'r1',
            dayOfWeek: 3,
            name: 'Miércoles',
            fetchedAt: 2,
          ),
        ]);
        final second = await dao.readRoutineDays('r1');
        expect(second.length, 1);
        expect(second.single.id, 'd9');
      },
    );
  });

  group('replaceExercisesForDay / readExercisesForDay', () {
    test(
      'join devuelve filas ordenadas por position con catálogo asociado',
      () async {
        await dao.replaceExercisesForDay(
          'd1',
          [
            CachedRoutineExercisesCompanion.insert(
              routineDayId: 'd1',
              exerciseId: 'e2',
              position: 1,
              targetSets: 4,
              targetReps: 8,
              targetWeight: 80.0,
              fetchedAt: 1,
            ),
            CachedRoutineExercisesCompanion.insert(
              routineDayId: 'd1',
              exerciseId: 'e1',
              position: 0,
              targetSets: 3,
              targetReps: 10,
              targetWeight: 50.0,
              fetchedAt: 1,
            ),
          ],
          [
            CachedExercisesCompanion.insert(
              id: 'e1',
              name: 'Press Banca',
              muscleGroup: const Value('pecho'),
              fetchedAt: 1,
            ),
            CachedExercisesCompanion.insert(
              id: 'e2',
              name: 'Press Militar',
              muscleGroup: const Value('hombro'),
              fetchedAt: 1,
            ),
          ],
        );

        final rows = await dao.readExercisesForDay('d1');
        expect(rows.length, 2);
        expect(rows[0].ex.id, 'e1');
        expect(rows[0].re.position, 0);
        expect(rows[1].ex.id, 'e2');
        expect(rows[1].re.position, 1);
      },
    );

    test(
      'replace borra los anteriores del día pero conserva catálogo global',
      () async {
        // 1ª escritura.
        await dao.replaceExercisesForDay(
          'd1',
          [
            CachedRoutineExercisesCompanion.insert(
              routineDayId: 'd1',
              exerciseId: 'e1',
              position: 0,
              targetSets: 3,
              targetReps: 10,
              targetWeight: 50.0,
              fetchedAt: 1,
            ),
          ],
          [
            CachedExercisesCompanion.insert(
              id: 'e1',
              name: 'Sentadilla',
              fetchedAt: 1,
            ),
          ],
        );

        // 2ª escritura del mismo día con un set distinto.
        await dao.replaceExercisesForDay(
          'd1',
          [
            CachedRoutineExercisesCompanion.insert(
              routineDayId: 'd1',
              exerciseId: 'e2',
              position: 0,
              targetSets: 5,
              targetReps: 5,
              targetWeight: 100.0,
              fetchedAt: 2,
            ),
          ],
          [
            CachedExercisesCompanion.insert(
              id: 'e2',
              name: 'Peso muerto',
              fetchedAt: 2,
            ),
          ],
        );

        final rows = await dao.readExercisesForDay('d1');
        expect(rows.single.ex.id, 'e2');

        // El catálogo conserva e1 — aunque ya no pertenezca a d1.
        final catalog = await db.select(db.cachedExercises).get();
        expect(catalog.map((r) => r.id).toSet(), {'e1', 'e2'});
      },
    );
  });

  group('readLastPerformances / upsertLastPerformances', () {
    test(
      'upsert por (userId, exerciseId) y read devuelve map por exerciseId',
      () async {
        await dao.upsertLastPerformances('u1', {
          'e1': CachedLastPerformancesCompanion.insert(
            userId: 'u1',
            exerciseId: 'e1',
            sessionId: 's1',
            actualWeight: 60.0,
            actualReps: 10,
            setIndex: 0,
            fetchedAt: 1,
          ),
          'e2': CachedLastPerformancesCompanion.insert(
            userId: 'u1',
            exerciseId: 'e2',
            sessionId: 's1',
            actualWeight: 80.0,
            actualReps: 5,
            setIndex: 2,
            fetchedAt: 1,
          ),
        });

        final read = await dao.readLastPerformances('u1', ['e1', 'e2', 'e3']);
        expect(read.keys.toSet(), {'e1', 'e2'});
        expect(read['e1']!.actualWeight, 60.0);
        expect(read['e2']!.setIndex, 2);

        // Re-upsert misma key actualiza, no duplica.
        await dao.upsertLastPerformances('u1', {
          'e1': CachedLastPerformancesCompanion.insert(
            userId: 'u1',
            exerciseId: 'e1',
            sessionId: 's2',
            actualWeight: 65.0,
            actualReps: 10,
            setIndex: 0,
            fetchedAt: 2,
          ),
        });
        final updated = await dao.readLastPerformances('u1', ['e1']);
        expect(updated['e1']!.actualWeight, 65.0);
        expect(updated['e1']!.sessionId, 's2');

        // Lista vacía → map vacío sin crashear.
        expect(await dao.readLastPerformances('u1', const []), isEmpty);
      },
    );

    test('upsert sólo aplica al userId indicado', () async {
      await dao.upsertLastPerformances('u1', {
        'e1': CachedLastPerformancesCompanion.insert(
          userId: 'u1',
          exerciseId: 'e1',
          sessionId: 's1',
          actualWeight: 1.0,
          actualReps: 1,
          setIndex: 0,
          fetchedAt: 1,
        ),
      });
      await dao.upsertLastPerformances('u2', {
        'e1': CachedLastPerformancesCompanion.insert(
          userId: 'u2',
          exerciseId: 'e1',
          sessionId: 's9',
          actualWeight: 2.0,
          actualReps: 2,
          setIndex: 0,
          fetchedAt: 1,
        ),
      });

      final u1 = await dao.readLastPerformances('u1', ['e1']);
      final u2 = await dao.readLastPerformances('u2', ['e1']);
      expect(u1['e1']!.actualWeight, 1.0);
      expect(u2['e1']!.actualWeight, 2.0);
    });
  });
}
