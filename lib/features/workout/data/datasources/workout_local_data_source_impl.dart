import 'package:drift/drift.dart';

import 'package:gym_flutter/core/database/dao/workout_cache_dao.dart';
import 'package:gym_flutter/core/database/local_database.dart';
import 'package:gym_flutter/features/workout/data/datasources/workout_local_data_source.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';

/// Implementación de [`WorkoutLocalDataSource`] sobre [`WorkoutCacheDao`].
///
/// Convierte filas drift ↔ entidades de dominio para que el repositorio
/// pueda devolver el mismo tipo en hit local y hit remoto sin condicionales
/// de mapping.
class WorkoutLocalDataSourceImpl implements WorkoutLocalDataSource {
  WorkoutLocalDataSourceImpl(this._dao);

  final WorkoutCacheDao _dao;

  int get _nowMs => DateTime.now().toUtc().millisecondsSinceEpoch;

  // ─── Reads ──────────────────────────────────────────────────────────────

  @override
  Future<List<RoutineDay>> getRoutineDays(String routineId) async {
    final rows = await _dao.readRoutineDays(routineId);
    return rows
        .map(
          (r) => RoutineDay(
            id: r.id,
            routineId: r.routineId,
            dayOfWeek: r.dayOfWeek,
            name: r.name,
            targetSetsCount: r.targetSetsCount,
            status: _statusFromName(r.status),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<Exercise>> getExercisesForDay(String routineDayId) async {
    final rows = await _dao.readExercisesForDay(routineDayId);
    return rows
        .map(
          (row) => Exercise(
            id: row.ex.id,
            routineDayId: row.re.routineDayId,
            name: row.ex.name,
            targetMuscle: row.ex.muscleGroup,
            targetWeight: row.re.targetWeight,
            targetReps: row.re.targetReps,
            targetSets: row.re.targetSets,
            restTimerSeconds: row.re.restTimerSeconds,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<Map<String, SetLog?>> getLastPerformancesForExercises(
    String userId,
    List<String> exerciseIds,
  ) async {
    final rows = await _dao.readLastPerformances(userId, exerciseIds);
    return {
      for (final id in exerciseIds)
        id: rows[id] == null
            ? null
            : SetLog(
                id: rows[id]!.setLogId,
                sessionId: rows[id]!.sessionId,
                exerciseId: rows[id]!.exerciseId,
                actualWeight: rows[id]!.actualWeight,
                actualReps: rows[id]!.actualReps,
                setIndex: rows[id]!.setIndex,
                createdAt: rows[id]!.performedAt == null
                    ? null
                    : DateTime.fromMillisecondsSinceEpoch(
                        rows[id]!.performedAt!,
                        isUtc: true,
                      ),
              ),
    };
  }

  // ─── Writes ─────────────────────────────────────────────────────────────

  @override
  Future<void> cacheRoutineDays(
    String routineId,
    List<RoutineDay> days,
  ) async {
    final now = _nowMs;
    final rows = days
        .map(
          (d) => CachedRoutineDaysCompanion.insert(
            id: d.id,
            routineId: d.routineId,
            dayOfWeek: d.dayOfWeek,
            name: d.name,
            targetSetsCount: Value(d.targetSetsCount),
            status: Value(d.status.name),
            fetchedAt: now,
          ),
        )
        .toList();
    await _dao.upsertRoutineDays(routineId, rows);
  }

  @override
  Future<void> cacheExercisesForDay(
    String routineDayId,
    List<Exercise> exercises,
  ) async {
    final now = _nowMs;
    final junctionRows = <CachedRoutineExercisesCompanion>[];
    final catalogRows = <CachedExercisesCompanion>[];
    for (var i = 0; i < exercises.length; i++) {
      final e = exercises[i];
      junctionRows.add(
        CachedRoutineExercisesCompanion.insert(
          routineDayId: routineDayId,
          exerciseId: e.id,
          position: i,
          targetSets: e.targetSets,
          targetReps: e.targetReps,
          targetWeight: e.targetWeight,
          restTimerSeconds: Value(e.restTimerSeconds),
          fetchedAt: now,
        ),
      );
      catalogRows.add(
        CachedExercisesCompanion.insert(
          id: e.id,
          name: e.name,
          muscleGroup: Value(e.targetMuscle),
          fetchedAt: now,
        ),
      );
    }
    await _dao.replaceExercisesForDay(routineDayId, junctionRows, catalogRows);
  }

  @override
  Future<void> cacheLastPerformances(
    String userId,
    Map<String, SetLog?> performances,
  ) async {
    final now = _nowMs;
    final companions = <String, CachedLastPerformancesCompanion>{};
    performances.forEach((exerciseId, log) {
      if (log == null) return;
      companions[exerciseId] = CachedLastPerformancesCompanion.insert(
        userId: userId,
        exerciseId: exerciseId,
        sessionId: log.sessionId,
        actualWeight: log.actualWeight,
        actualReps: log.actualReps,
        setIndex: log.setIndex,
        setLogId: Value(log.id),
        performedAt:
            Value(log.createdAt?.toUtc().millisecondsSinceEpoch),
        fetchedAt: now,
      );
    });
    if (companions.isEmpty) return;
    await _dao.upsertLastPerformances(userId, companions);
  }

  WorkoutDayStatus _statusFromName(String name) {
    for (final v in WorkoutDayStatus.values) {
      if (v.name == name) return v;
    }
    return WorkoutDayStatus.pending;
  }
}
