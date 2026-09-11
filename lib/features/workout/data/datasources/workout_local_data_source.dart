import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';

/// Contrato de la caché local que sirve al repositorio.
///
/// Phase 1 expuso solo reads (SWR). Phase 2 añade el write-path local-first:
/// el repositorio escribe primero aquí y la outbox empuja al backend.
abstract class WorkoutLocalDataSource {
  // ─── Reads (Phase 1) ────────────────────────────────────────────────────

  /// Días de una rutina (sin `exercises` populated — cargan a través de
  /// [`getExercisesForDay`]).
  Future<List<RoutineDay>> getRoutineDays(String routineId);

  /// Ejercicios del día con su metadata canónica (nombre, grupo muscular).
  Future<List<Exercise>> getExercisesForDay(String routineDayId);

  /// Último `SetLog` cacheado por ejercicio. La key del map es el
  /// `exerciseId`; el valor es `null` si no hay cache para ese ejercicio.
  Future<Map<String, SetLog?>> getLastPerformancesForExercises(
    String userId,
    List<String> exerciseIds,
  );

  // ─── Writes — read-only mirrors (Phase 1) ──────────────────────────────

  Future<void> cacheRoutineDays(String routineId, List<RoutineDay> days);

  Future<void> cacheExercisesForDay(
    String routineDayId,
    List<Exercise> exercises,
  );

  /// Persiste sólo las entradas con valor non-null. Las claves con `null` se
  /// ignoran (no hay nada que cachear).
  Future<void> cacheLastPerformances(
    String userId,
    Map<String, SetLog?> performances,
  );

  // ─── Writes — write-side mirrors (Phase 2) ─────────────────────────────

  /// Persiste (insert-or-replace) la sesión local. `syncStatus` arranca en
  /// `pending` por defecto; el SyncWorker lo actualiza tras el drain.
  Future<void> saveCachedSession(
    WorkoutSession session, {
    String syncStatus = 'pending',
  });

  /// Persiste un set log local. La PK compuesta `(sessionId, exerciseId,
  /// setIndex)` garantiza que un mismo set se actualice y no duplique.
  Future<void> upsertCachedSetLog(SetLog log, {String syncStatus = 'pending'});

  /// Marca una sesión como completada (escribe `completedAt`).
  Future<void> markSessionCompleted(String id, DateTime completedAt);

  /// Persiste el coaching final tras `finalize_workout_session_v1`. Si la
  /// lista entrante es vacía, no escribe.
  Future<void> applyCoachingForSession(
    String id,
    List<CoachingAnalysis> coaching,
  );

  /// Sesión abierta del usuario (completedAt IS NULL). `null` si no hay.
  /// Soporta el fallback offline del repositorio.
  Future<WorkoutSession?> getOpenSessionForUser(String userId);

  /// Stream que emite la fila local cada vez que cambia. La UI puede
  /// reaccionar al drain del worker (p.ej. coaching aplicado).
  Stream<WorkoutSession?> watchSession(String id);

  // ─── Reads (Phase 4 SWR polish) ────────────────────────────────────────

  /// Rutinas asignadas al usuario en caché. `null` si nunca se cacheó
  /// (cache miss "no entry"); lista vacía si está cacheado como "sin
  /// rutinas asignadas".
  Future<List<Routine>?> getAssignedRoutines(String userId);

  /// Snapshot cacheado de `WeeklyInsights` por (usuario, rutina, semana).
  /// `null` si no hay entrada. `weekStart` se trunca al día UTC.
  Future<WeeklyInsights?> getWeeklyInsights(
    String userId,
    String routineId,
    DateTime weekStart,
  );

  /// Sesiones cacheadas del usuario dentro del rango `[weekStart, weekEnd]`
  /// (ambos inclusivos). Lista vacía si no hay nada en cache.
  Future<List<WorkoutSession>> getWeekSessions(
    String userId,
    DateTime weekStart,
    DateTime weekEnd,
  );

  // ─── Writes (Phase 4 SWR polish) ───────────────────────────────────────

  /// Reemplaza la lista cacheada de rutinas asignadas para el usuario.
  Future<void> cacheAssignedRoutines(String userId, List<Routine> routines);

  /// Upserta el snapshot de `WeeklyInsights` cacheado. `weekStart` se
  /// trunca al día UTC para no fragmentar la PK por horas/tz.
  Future<void> cacheWeeklyInsights({
    required String userId,
    required String routineId,
    required WeeklyInsights insights,
  });

  /// Persiste las sesiones de la semana devueltas por el remote. Respeta
  /// cualquier fila local con `sync_status` no-`synced` (pendiente de
  /// drain) — esos los gestiona el SyncWorker.
  Future<void> cacheWeekSessions(String userId, List<WorkoutSession> sessions);
}
