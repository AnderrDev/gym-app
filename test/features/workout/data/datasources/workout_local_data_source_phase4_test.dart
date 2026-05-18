import 'package:flutter_test/flutter_test.dart';

import 'package:gym_flutter/core/database/dao/workout_cache_dao.dart';
import 'package:gym_flutter/core/database/local_database.dart';
import 'package:gym_flutter/features/workout/data/datasources/workout_local_data_source_impl.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';

import '../../../../helpers/database_test_helper.dart';

/// Round-trip de los métodos nuevos de Phase 4 sobre la implementación
/// con DB en memoria.
void main() {
  late LocalDatabase db;
  late WorkoutLocalDataSourceImpl local;

  setUp(() {
    db = openInMemoryDb();
    local = WorkoutLocalDataSourceImpl(WorkoutCacheDao(db));
  });
  tearDown(() async => db.close());

  // ─── getAssignedRoutines / cacheAssignedRoutines ──────────────────────

  group('assignedRoutines', () {
    test('devuelve null antes de cachear nada', () async {
      final result = await local.getAssignedRoutines('u1');
      expect(result, isNull);
    });

    test('round-trip: cachear → leer devuelve las rutinas', () async {
      const routines = [
        Routine(
          id: 'r1',
          name: 'Push',
          exerciseCount: 5,
          isPublic: true,
          creatorId: 'creator-1',
          creatorName: 'Coach',
        ),
        Routine(
          id: 'r2',
          name: 'Pull',
          exerciseCount: 4,
        ),
      ];
      await local.cacheAssignedRoutines('u1', routines);

      final read = await local.getAssignedRoutines('u1');
      expect(read, isNotNull);
      expect(read!.length, 2);
      final byId = {for (final r in read) r.id: r};
      expect(byId['r1']!.name, 'Push');
      expect(byId['r1']!.isPublic, isTrue);
      expect(byId['r1']!.creatorId, 'creator-1');
      expect(byId['r1']!.creatorName, 'Coach');
      expect(byId['r1']!.exerciseCount, 5);
      expect(byId['r2']!.isPublic, isFalse);
      expect(byId['r2']!.creatorId, isNull);
    });

    test('cachear reemplaza la lista del usuario', () async {
      await local.cacheAssignedRoutines('u1', const [
        Routine(id: 'r1', name: 'Old', exerciseCount: 1),
      ]);
      await local.cacheAssignedRoutines('u1', const [
        Routine(id: 'r9', name: 'New', exerciseCount: 9),
      ]);
      final read = await local.getAssignedRoutines('u1');
      expect(read!.single.id, 'r9');
    });
  });

  // ─── getWeeklyInsights / cacheWeeklyInsights ──────────────────────────

  group('weeklyInsights', () {
    test('round-trip preserva todos los campos', () async {
      final insights = WeeklyInsights(
        weekStart: DateTime.utc(2026, 5, 11),
        weekEnd: DateTime.utc(2026, 5, 17),
        plannedDays: 5,
        completedDays: 3,
        completedSessions: 3,
        adherenceRate: 0.6,
        totalVolume: 1000,
        previousWeekVolume: 900,
        volumeTrendPercent: 11.1,
        personalRecords: 2,
      );

      await local.cacheWeeklyInsights(
        userId: 'u1',
        routineId: 'r1',
        insights: insights,
      );

      final read = await local.getWeeklyInsights(
        'u1',
        'r1',
        DateTime.utc(2026, 5, 11),
      );
      expect(read, isNotNull);
      expect(read!.plannedDays, 5);
      expect(read.completedDays, 3);
      expect(read.adherenceRate, 0.6);
      expect(read.totalVolume, 1000);
      expect(read.previousWeekVolume, 900);
      expect(read.volumeTrendPercent, 11.1);
      expect(read.personalRecords, 2);
    });

    test('devuelve null si no hay snapshot cacheado', () async {
      final read = await local.getWeeklyInsights(
        'u1',
        'r1',
        DateTime.utc(2026, 5, 11),
      );
      expect(read, isNull);
    });

    test('upsert: segunda escritura con misma PK sobrescribe', () async {
      final v1 = WeeklyInsights(
        weekStart: DateTime.utc(2026, 5, 11),
        weekEnd: DateTime.utc(2026, 5, 17),
        plannedDays: 5,
        completedDays: 0,
        completedSessions: 0,
        adherenceRate: 0,
        totalVolume: 0,
        previousWeekVolume: 0,
        volumeTrendPercent: 0,
        personalRecords: 0,
      );
      final v2 = WeeklyInsights(
        weekStart: DateTime.utc(2026, 5, 11),
        weekEnd: DateTime.utc(2026, 5, 17),
        plannedDays: 5,
        completedDays: 4,
        completedSessions: 4,
        adherenceRate: 0.8,
        totalVolume: 2000,
        previousWeekVolume: 1000,
        volumeTrendPercent: 100,
        personalRecords: 3,
      );

      await local.cacheWeeklyInsights(
        userId: 'u1',
        routineId: 'r1',
        insights: v1,
      );
      await local.cacheWeeklyInsights(
        userId: 'u1',
        routineId: 'r1',
        insights: v2,
      );
      final read = await local.getWeeklyInsights(
        'u1',
        'r1',
        DateTime.utc(2026, 5, 11),
      );
      expect(read!.completedDays, 4);
      expect(read.totalVolume, 2000);
    });
  });

  // ─── getWeekSessions / cacheWeekSessions ──────────────────────────────

  group('weekSessions', () {
    test('round-trip devuelve sólo las sesiones del rango y user', () async {
      final inside1 = WorkoutSession(
        id: 's-mon',
        userId: 'u1',
        routineDayId: 'd1',
        sessionDate: DateTime.utc(2026, 5, 11),
      );
      final inside2 = WorkoutSession(
        id: 's-wed',
        userId: 'u1',
        routineDayId: 'd2',
        sessionDate: DateTime.utc(2026, 5, 13),
        completedSetsCount: 2,
        totalTargetSets: 4,
        completedAt: DateTime.utc(2026, 5, 13, 18),
      );
      final outside = WorkoutSession(
        id: 's-next',
        userId: 'u1',
        routineDayId: 'd1',
        sessionDate: DateTime.utc(2026, 5, 18),
      );
      final otherUser = WorkoutSession(
        id: 's-other',
        userId: 'u2',
        routineDayId: 'd1',
        sessionDate: DateTime.utc(2026, 5, 13),
      );

      await local.cacheWeekSessions(
        'u1',
        [inside1, inside2, outside, otherUser],
      );

      final read = await local.getWeekSessions(
        'u1',
        DateTime.utc(2026, 5, 11),
        DateTime.utc(2026, 5, 17),
      );
      expect(read.map((s) => s.id).toList(), ['s-mon', 's-wed']);
      final wed = read.firstWhere((s) => s.id == 's-wed');
      expect(wed.completedSetsCount, 2);
      expect(wed.totalTargetSets, 4);
      expect(wed.completedAt, isNotNull);
    });

    test('lista vacía es no-op (no rompe)', () async {
      await local.cacheWeekSessions('u1', const []);
      final read = await local.getWeekSessions(
        'u1',
        DateTime.utc(2026, 5, 11),
        DateTime.utc(2026, 5, 17),
      );
      expect(read, isEmpty);
    });
  });

  // ─── No-collision write-side: pending nunca lo pisa "synced" del remote ─

  group('no-colision write-side vs SWR remote', () {
    test('cacheWeekSessions NO sobreescribe filas pending', () async {
      // 1) El usuario escribió localmente una sesión (pending).
      final localSession = WorkoutSession(
        id: 'sess-1',
        userId: 'u1',
        routineDayId: 'd1',
        sessionDate: DateTime.utc(2026, 5, 13),
        totalTargetSets: 10,
        completedSetsCount: 5,
      );
      await local.saveCachedSession(localSession);

      // 2) El remote devuelve la misma sesión con conteos distintos.
      final remoteSession = WorkoutSession(
        id: 'sess-1',
        userId: 'u1',
        routineDayId: 'd1',
        sessionDate: DateTime.utc(2026, 5, 13),
        totalTargetSets: 99,
        completedSetsCount: 99,
      );
      await local.cacheWeekSessions('u1', [remoteSession]);

      // 3) La fila no se ha tocado — sigue pending y con los conteos locales.
      final row = await (db.select(db.cachedWorkoutSessions)
            ..where((t) => t.id.equals('sess-1')))
          .getSingle();
      expect(row.syncStatus, 'pending');
      expect(row.totalTargetSets, 10);
      expect(row.completedSetsCount, 5);
    });
  });
}
