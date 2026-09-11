import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_flutter/core/database/dao/workout_cache_dao.dart';
import 'package:gym_flutter/core/database/local_database.dart';

import '../../helpers/database_test_helper.dart';

/// Tests del DAO para los métodos nuevos de Phase 4:
///  - replaceAssignedRoutines / readAssignedRoutines
///  - upsertWeeklyInsight / readWeeklyInsight
///  - readWeekSessions / upsertSyncedSessions
void main() {
  late LocalDatabase db;
  late WorkoutCacheDao dao;

  setUp(() {
    db = openInMemoryDb();
    dao = WorkoutCacheDao(db);
  });

  tearDown(() async => db.close());

  // ─── cached_assigned_routines ─────────────────────────────────────────

  group('replaceAssignedRoutines / readAssignedRoutines', () {
    test(
      'replace reemplaza el contenido del userId y deja al resto intacto',
      () async {
        await dao.replaceAssignedRoutines('u1', [
          CachedAssignedRoutinesCompanion.insert(
            userId: 'u1',
            routineId: 'r1',
            routineName: 'Push',
            fetchedAt: 1,
          ),
          CachedAssignedRoutinesCompanion.insert(
            userId: 'u1',
            routineId: 'r2',
            routineName: 'Pull',
            fetchedAt: 2,
          ),
        ]);
        // Otro usuario debe sobrevivir.
        await dao.replaceAssignedRoutines('u2', [
          CachedAssignedRoutinesCompanion.insert(
            userId: 'u2',
            routineId: 'rX',
            routineName: 'Otro',
            fetchedAt: 1,
          ),
        ]);

        // Second replace para u1 → reemplaza todo.
        await dao.replaceAssignedRoutines('u1', [
          CachedAssignedRoutinesCompanion.insert(
            userId: 'u1',
            routineId: 'r9',
            routineName: 'Legs',
            fetchedAt: 9,
          ),
        ]);

        final u1Rows = await dao.readAssignedRoutines('u1');
        expect(u1Rows.length, 1);
        expect(u1Rows.single.routineId, 'r9');

        // u2 intacto.
        final u2Rows = await dao.readAssignedRoutines('u2');
        expect(u2Rows.single.routineId, 'rX');
      },
    );

    test('replace con lista vacía vacía la caché del usuario', () async {
      await dao.replaceAssignedRoutines('u1', [
        CachedAssignedRoutinesCompanion.insert(
          userId: 'u1',
          routineId: 'r1',
          routineName: 'Push',
          fetchedAt: 1,
        ),
      ]);
      await dao.replaceAssignedRoutines('u1', const []);
      final rows = await dao.readAssignedRoutines('u1');
      expect(rows, isEmpty);
    });
  });

  // ─── cached_weekly_insights ───────────────────────────────────────────

  group('upsertWeeklyInsight / readWeeklyInsight', () {
    test(
      'upsert por PK compuesta (user, routine, weekStart) — el segundo gana',
      () async {
        await dao.upsertWeeklyInsight(
          CachedWeeklyInsightsCompanion.insert(
            userId: 'u1',
            routineId: 'r1',
            weekStart: '2026-05-11',
            payloadJson: '{"v":1}',
            fetchedAt: 1,
          ),
        );
        await dao.upsertWeeklyInsight(
          CachedWeeklyInsightsCompanion.insert(
            userId: 'u1',
            routineId: 'r1',
            weekStart: '2026-05-11',
            payloadJson: '{"v":2}',
            fetchedAt: 2,
          ),
        );

        final row = await dao.readWeeklyInsight('u1', 'r1', '2026-05-11');
        expect(row != null, isTrue);
        expect(row!.payloadJson, '{"v":2}');
      },
    );

    test('read devuelve null cuando no hay fila', () async {
      final row = await dao.readWeeklyInsight('u1', 'r1', '2026-05-11');
      expect(row == null, isTrue);
    });
  });

  // ─── cached_workout_sessions (Phase 4: lectura por semana + upsert) ───

  group('readWeekSessions', () {
    test('filtra por userId y rango ISO inclusive', () async {
      Future<void> insert(String id, String date, String user) =>
          dao.saveCachedSession(
            CachedWorkoutSessionsCompanion.insert(
              id: id,
              userId: user,
              routineDayId: 'd1',
              sessionDate: date,
              startedAt: 1,
              fetchedAt: 1,
            ),
          );

      await insert('s-before', '2026-05-10', 'u1');
      await insert('s-mon', '2026-05-11', 'u1'); // dentro
      await insert('s-wed', '2026-05-13', 'u1'); // dentro
      await insert('s-sun', '2026-05-17', 'u1'); // dentro (fin inclusivo)
      await insert('s-after', '2026-05-18', 'u1');
      await insert('s-other', '2026-05-13', 'u2'); // otro user

      final rows = await dao.readWeekSessions('u1', '2026-05-11', '2026-05-17');

      expect(rows.map((r) => r.id).toList(), ['s-mon', 's-wed', 's-sun']);
    });
  });

  group('upsertSyncedSessions', () {
    test(
      'respeta sync_status pending/syncing/error (no toca esas filas)',
      () async {
        // Sembramos 3 filas con estados protegidos.
        for (final status in const ['pending', 'syncing', 'error']) {
          await dao.saveCachedSession(
            CachedWorkoutSessionsCompanion.insert(
              id: 'sess-$status',
              userId: 'u1',
              routineDayId: 'd1',
              sessionDate: '2026-05-11',
              startedAt: 1,
              totalTargetSets: const Value(10),
              syncStatus: Value(status),
              fetchedAt: 1,
            ),
          );
        }

        // Y una fila ya synced.
        await dao.saveCachedSession(
          CachedWorkoutSessionsCompanion.insert(
            id: 'sess-synced',
            userId: 'u1',
            routineDayId: 'd1',
            sessionDate: '2026-05-11',
            startedAt: 1,
            totalTargetSets: const Value(5),
            syncStatus: const Value('synced'),
            fetchedAt: 1,
          ),
        );

        // Ahora "el remote" devuelve los 4 ids con valores actualizados.
        await dao.upsertSyncedSessions([
          for (final id in const [
            'sess-pending',
            'sess-syncing',
            'sess-error',
            'sess-synced',
          ])
            CachedWorkoutSessionsCompanion.insert(
              id: id,
              userId: 'u1',
              routineDayId: 'd1',
              sessionDate: '2026-05-11',
              startedAt: 999,
              totalTargetSets: const Value(99),
              // Caller envía cualquier status; el DAO lo normaliza a synced.
              syncStatus: const Value('synced'),
              fetchedAt: 999,
            ),
        ]);

        Future<String> status(String id) async {
          final row = await (db.select(
            db.cachedWorkoutSessions,
          )..where((t) => t.id.equals(id))).getSingle();
          return row.syncStatus;
        }

        Future<int> totalTarget(String id) async {
          final row = await (db.select(
            db.cachedWorkoutSessions,
          )..where((t) => t.id.equals(id))).getSingle();
          return row.totalTargetSets;
        }

        expect(await status('sess-pending'), 'pending');
        expect(await status('sess-syncing'), 'syncing');
        expect(await status('sess-error'), 'error');
        expect(await status('sess-synced'), 'synced');

        // Las protegidas mantienen su totalTargetSets.
        expect(await totalTarget('sess-pending'), 10);
        expect(await totalTarget('sess-syncing'), 10);
        expect(await totalTarget('sess-error'), 10);
        // La synced sí se reemplazó.
        expect(await totalTarget('sess-synced'), 99);
      },
    );

    test('inserta filas nuevas como synced cuando no existían', () async {
      await dao.upsertSyncedSessions([
        CachedWorkoutSessionsCompanion.insert(
          id: 'sess-new',
          userId: 'u1',
          routineDayId: 'd1',
          sessionDate: '2026-05-11',
          startedAt: 1,
          syncStatus: const Value('synced'),
          fetchedAt: 1,
        ),
      ]);
      final row = await (db.select(
        db.cachedWorkoutSessions,
      )..where((t) => t.id.equals('sess-new'))).getSingle();
      expect(row.syncStatus, 'synced');
    });

    test('lista vacía es no-op', () async {
      await dao.upsertSyncedSessions(const []);
      final rows = await db.select(db.cachedWorkoutSessions).get();
      expect(rows, isEmpty);
    });
  });
}
