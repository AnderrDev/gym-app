import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:gym_flutter/core/database/dao/workout_cache_dao.dart';
import 'package:gym_flutter/core/database/local_database.dart';
import 'package:gym_flutter/features/workout/data/datasources/workout_local_data_source.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';

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
  Future<void> cacheRoutineDays(String routineId, List<RoutineDay> days) async {
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
        performedAt: Value(log.createdAt?.toUtc().millisecondsSinceEpoch),
        fetchedAt: now,
      );
    });
    if (companions.isEmpty) return;
    await _dao.upsertLastPerformances(userId, companions);
  }

  // ─── Writes / reads (Phase 2: write-side mirror) ───────────────────────

  @override
  Future<void> saveCachedSession(
    WorkoutSession session, {
    String syncStatus = 'pending',
  }) {
    final now = _nowMs;
    final coachingJson =
        (session.coachingAnalysis == null || session.coachingAnalysis!.isEmpty)
        ? null
        : jsonEncode(session.coachingAnalysis!.map((c) => c.toJson()).toList());
    return _dao.saveCachedSession(
      CachedWorkoutSessionsCompanion.insert(
        id: session.id,
        userId: session.userId,
        routineDayId: session.routineDayId,
        sessionDate: _isoDate(session.sessionDate),
        startedAt: now,
        completedAt: Value(session.completedAt?.toUtc().millisecondsSinceEpoch),
        totalTargetSets: Value(session.totalTargetSets),
        completedSetsCount: Value(session.completedSetsCount),
        coachingAnalysisJson: Value(coachingJson),
        syncStatus: Value(syncStatus),
        fetchedAt: now,
      ),
    );
  }

  @override
  Future<void> upsertCachedSetLog(SetLog log, {String syncStatus = 'pending'}) {
    final now = _nowMs;
    final createdMs = log.createdAt?.toUtc().millisecondsSinceEpoch ?? now;
    return _dao.upsertCachedSetLog(
      CachedSetLogsCompanion.insert(
        sessionId: log.sessionId,
        exerciseId: log.exerciseId,
        setIndex: log.setIndex,
        actualWeight: log.actualWeight,
        actualReps: log.actualReps,
        createdAt: createdMs,
        remoteId: Value(log.id),
        syncStatus: Value(syncStatus),
        fetchedAt: now,
      ),
    );
  }

  @override
  Future<void> deleteCachedSetLog({
    required String sessionId,
    required String exerciseId,
    required int setIndex,
  }) async {
    await _dao.deleteCachedSetLog(
      sessionId: sessionId,
      exerciseId: exerciseId,
      setIndex: setIndex,
    );
  }

  @override
  Future<void> markSessionCompleted(String id, DateTime completedAt) {
    return _dao.markSessionCompleted(
      id,
      completedAt.toUtc().millisecondsSinceEpoch,
    );
  }

  @override
  Future<void> applyCoachingForSession(
    String id,
    List<CoachingAnalysis> coaching,
  ) {
    if (coaching.isEmpty) return Future.value();
    final json = jsonEncode(coaching.map((c) => c.toJson()).toList());
    return _dao.applyCoachingForSession(id, json);
  }

  @override
  Future<WorkoutSession?> getOpenSessionForUser(String userId) async {
    final row = await _dao.readOpenSessionForUser(userId);
    return row == null ? null : _mapSession(row);
  }

  @override
  Stream<WorkoutSession?> watchSession(String id) {
    return _dao
        .watchSession(id)
        .map((row) => row == null ? null : _mapSession(row));
  }

  // ─── Phase 4 SWR polish ────────────────────────────────────────────────

  @override
  Future<List<Routine>?> getAssignedRoutines(String userId) async {
    final rows = await _dao.readAssignedRoutines(userId);
    if (rows.isEmpty) {
      // Para distinguir "nunca cacheado" vs "cacheado como vacío", el
      // repositorio hace su propia decisión usando un flag separado. Aquí
      // devolvemos `null` cuando no hay filas — y el repo lo trata como
      // "no usar cache". Si fuera necesario diferenciar más adelante,
      // bastaría una marca en `app_meta`.
      return null;
    }
    return rows
        .map(
          (r) => Routine(
            id: r.routineId,
            name: r.routineName,
            exerciseCount: r.exerciseCount,
            isPublic: r.isPublic,
            creatorId: r.creatorId,
            creatorName: r.creatorName,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> cacheAssignedRoutines(
    String userId,
    List<Routine> routines,
  ) async {
    final now = _nowMs;
    final rows = routines
        .map(
          (r) => CachedAssignedRoutinesCompanion.insert(
            userId: userId,
            routineId: r.id,
            routineName: r.name,
            isPublic: Value(r.isPublic),
            creatorId: Value(r.creatorId),
            creatorName: Value(r.creatorName),
            exerciseCount: Value(r.exerciseCount),
            fetchedAt: now,
          ),
        )
        .toList(growable: false);
    await _dao.replaceAssignedRoutines(userId, rows);
  }

  @override
  Future<WeeklyInsights?> getWeeklyInsights(
    String userId,
    String routineId,
    DateTime weekStart,
  ) async {
    final row = await _dao.readWeeklyInsight(
      userId,
      routineId,
      _isoDate(weekStart.toUtc()),
    );
    if (row == null) return null;
    final decoded = jsonDecode(row.payloadJson);
    if (decoded is! Map<String, dynamic>) return null;
    return WeeklyInsights.fromJson(decoded);
  }

  @override
  Future<void> cacheWeeklyInsights({
    required String userId,
    required String routineId,
    required WeeklyInsights insights,
  }) {
    final now = _nowMs;
    return _dao.upsertWeeklyInsight(
      CachedWeeklyInsightsCompanion.insert(
        userId: userId,
        routineId: routineId,
        weekStart: _isoDate(insights.weekStart.toUtc()),
        payloadJson: jsonEncode(insights.toJson()),
        fetchedAt: now,
      ),
    );
  }

  @override
  Future<List<WorkoutSession>> getWeekSessions(
    String userId,
    DateTime weekStart,
    DateTime weekEnd,
  ) async {
    final rows = await _dao.readWeekSessions(
      userId,
      _isoDate(weekStart.toUtc()),
      _isoDate(weekEnd.toUtc()),
    );
    return rows.map(_mapSession).toList(growable: false);
  }

  @override
  Future<void> cacheWeekSessions(
    String userId,
    List<WorkoutSession> sessions,
  ) async {
    if (sessions.isEmpty) return;
    final now = _nowMs;
    final rows = sessions
        .map((s) {
          final coachingJson =
              (s.coachingAnalysis == null || s.coachingAnalysis!.isEmpty)
              ? null
              : jsonEncode(s.coachingAnalysis!.map((c) => c.toJson()).toList());
          return CachedWorkoutSessionsCompanion.insert(
            id: s.id,
            userId: s.userId,
            routineDayId: s.routineDayId,
            sessionDate: _isoDate(s.sessionDate),
            startedAt: now,
            completedAt: Value(s.completedAt?.toUtc().millisecondsSinceEpoch),
            totalTargetSets: Value(s.totalTargetSets),
            completedSetsCount: Value(s.completedSetsCount),
            coachingAnalysisJson: Value(coachingJson),
            // Marcado como `synced` porque viene del remote; el DAO
            // se encarga de respetar filas pending/syncing/error.
            syncStatus: const Value('synced'),
            fetchedAt: now,
          );
        })
        .toList(growable: false);
    await _dao.upsertSyncedSessions(rows);
  }

  // ─── Helpers ───────────────────────────────────────────────────────────

  WorkoutSession _mapSession(CachedWorkoutSessionRow row) {
    List<CoachingAnalysis>? coaching;
    final raw = row.coachingAnalysisJson;
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        coaching = decoded
            .whereType<Map<String, dynamic>>()
            .map(CoachingAnalysis.fromJson)
            .toList(growable: false);
      }
    }
    return WorkoutSession(
      id: row.id,
      userId: row.userId,
      routineDayId: row.routineDayId,
      sessionDate: DateTime.parse(row.sessionDate),
      completedAt: row.completedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.completedAt!, isUtc: true),
      completedSetsCount: row.completedSetsCount,
      totalTargetSets: row.totalTargetSets,
      coachingAnalysis: coaching,
    );
  }

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  WorkoutDayStatus _statusFromName(String name) {
    for (final v in WorkoutDayStatus.values) {
      if (v.name == name) return v;
    }
    return WorkoutDayStatus.pending;
  }
}
