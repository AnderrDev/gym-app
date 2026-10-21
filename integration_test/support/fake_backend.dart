import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart' show Fake;

import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/core/notifications/active_workout_notifier.dart';
import 'package:gym_flutter/core/notifications/live_activities_bridge.dart';
import 'package:gym_flutter/core/notifications/notification_service.dart';
import 'package:gym_flutter/core/utils/calendar_dates.dart';
import 'package:gym_flutter/features/auth/domain/entities/user.dart';
import 'package:gym_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:gym_flutter/features/profile/domain/repositories/profile_repository.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_catalog_item.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_history_session.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_history_session.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';

/// Backend en memoria para las pruebas de integración: la app real (router,
/// shell, BLoCs y páginas) corre encima sin Supabase ni red.
///
/// Siembra una rutina "Fuerza" con dos días: "Torso" cae hoy y "Pierna"
/// mañana. "Torso" tiene una sesión cerrada la semana pasada, así la previa
/// muestra "Última vez" y el resumen tiene con qué comparar.
class FakeWorkoutRepository extends Fake implements WorkoutRepository {
  FakeWorkoutRepository({DateTime? now, this.secondRoutine = false})
    : today = DateUtils.dateOnly(now ?? DateTime.now()) {
    _seed();
  }

  static const userId = 'user-it';
  static const routineId = 'routine-fuerza';
  static const torsoDayId = 'day-torso';
  static const piernaDayId = 'day-pierna';
  static const otherRoutineId = 'routine-cardio';

  final DateTime today;

  /// Asigna además una rutina "Cardio" (sin días): con dos rutinas HOY pide
  /// elegir una salvo que recuerde la última.
  final bool secondRoutine;

  final routines = <Routine>[];
  final days = <RoutineDay>[];
  final sessions = <WorkoutSession>[];

  /// Series guardadas por sesión.
  final logs = <String, List<SetLog>>{};

  /// Plan propio de las sesiones adaptadas (cambio o extra en la sesión).
  /// Sin entrada, la sesión usa los ejercicios de su día.
  final sessionPlans = <String, List<Exercise>>{};

  /// Catálogo global (tabla `exercises`).
  final catalog = const [
    ExerciseCatalogItem(
      id: 'ex-press',
      name: 'Press banca',
      muscleGroup: 'Pecho',
    ),
    ExerciseCatalogItem(
      id: 'ex-dominadas',
      name: 'Dominadas',
      muscleGroup: 'Espalda',
    ),
    ExerciseCatalogItem(
      id: 'ex-sentadilla',
      name: 'Sentadilla',
      muscleGroup: 'Piernas',
    ),
    ExerciseCatalogItem(
      id: 'ex-remo',
      name: 'Remo con barra',
      muscleGroup: 'Espalda',
    ),
    ExerciseCatalogItem(
      id: 'ex-press-inclinado',
      name: 'Press inclinado',
      muscleGroup: 'Pecho',
    ),
  ];

  int _ids = 0;

  /// Llamadas registradas, para afirmar qué se persistió.
  final finishedSessionIds = <String>[];
  final discardedSessionIds = <String>[];

  void _seed() {
    routines.add(
      const Routine(id: routineId, name: 'Fuerza', exerciseCount: 3),
    );
    if (secondRoutine) {
      routines.add(
        const Routine(id: otherRoutineId, name: 'Cardio', exerciseCount: 0),
      );
    }
    final torso = [
      const Exercise(
        id: 'ex-press',
        routineDayId: torsoDayId,
        name: 'Press banca',
        targetMuscle: 'Pecho',
        targetWeight: 60,
        targetReps: 10,
        targetSets: 3,
        restTimerSeconds: 90,
      ),
      const Exercise(
        id: 'ex-dominadas',
        routineDayId: torsoDayId,
        name: 'Dominadas',
        targetMuscle: 'Espalda',
        targetWeight: 0,
        targetReps: 8,
        targetSets: 2,
        restTimerSeconds: 90,
      ),
    ];
    final pierna = [
      const Exercise(
        id: 'ex-sentadilla',
        routineDayId: piernaDayId,
        name: 'Sentadilla',
        targetMuscle: 'Piernas',
        targetWeight: 80,
        targetReps: 8,
        targetSets: 3,
        restTimerSeconds: 120,
      ),
    ];
    days
      ..add(_day(torsoDayId, today.weekday, 'Torso', torso))
      ..add(_day(piernaDayId, today.weekday % 7 + 1, 'Pierna', pierna));

    // Sesión cerrada hace una semana: historial de "Torso".
    final lastWeek = AppCalendar.addDays(today, -7);
    final past = WorkoutSession(
      id: 'session-past',
      userId: userId,
      routineDayId: torsoDayId,
      sessionDate: lastWeek,
      completedAt: lastWeek.add(const Duration(hours: 19)),
    );
    sessions.add(past);
    logs[past.id] = [
      for (var i = 1; i <= 3; i++)
        SetLog(
          id: 'log-past-$i',
          sessionId: past.id,
          exerciseId: 'ex-press',
          actualWeight: 57.5,
          actualReps: 10,
          setIndex: i,
        ),
      for (var i = 1; i <= 2; i++)
        SetLog(
          id: 'log-past-d$i',
          sessionId: past.id,
          exerciseId: 'ex-dominadas',
          actualWeight: 0,
          actualReps: 8,
          setIndex: i,
        ),
    ];
  }

  RoutineDay _day(String id, int weekday, String name, List<Exercise> exs) =>
      RoutineDay(
        id: id,
        routineId: routineId,
        dayOfWeek: weekday,
        name: name,
        exercises: exs,
        targetSetsCount: exs.fold(0, (sum, e) => sum + e.targetSets),
        exerciseNamesPreview: [for (final e in exs) e.name],
      );

  RoutineDay _dayById(String id) => days.firstWhere((d) => d.id == id);

  Routine _withExerciseCount(Routine r) => r.copyWith(
    exerciseCount: days
        .where((d) => d.routineId == r.id)
        .fold(0, (sum, d) => sum + d.exercises.length),
  );

  /// Sustituye los ejercicios de [dayId] recalculando los derivados.
  void _setDayExercises(String dayId, List<Exercise> exercises) {
    final i = days.indexWhere((d) => d.id == dayId);
    days[i] = days[i].copyWith(
      exercises: exercises,
      targetSetsCount: exercises.fold(0, (sum, e) => sum + e.targetSets),
      exerciseNamesPreview: [for (final e in exercises) e.name],
    );
  }

  /// La sesión con los contadores que en producción da la vista
  /// `view_workout_sessions_summary`.
  WorkoutSession _withCounts(WorkoutSession s) => s.copyWith(
    completedSetsCount: logs[s.id]?.length ?? 0,
    totalTargetSets: _dayById(s.routineDayId).targetSetsCount,
  );

  WorkoutSession? get openSession =>
      sessions.where((s) => s.completedAt == null).firstOrNull;

  List<SetLog> logsOf(String sessionId) => logs[sessionId] ?? const [];

  // ── Rutinas y días ─────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<Routine>>> getAssignedRoutines(
    String userId,
  ) async => Right(routines.map(_withExerciseCount).toList());

  @override
  Future<Either<Failure, List<RoutineDay>>> getRoutineDays(
    String routineId,
  ) async => Right(days.where((d) => d.routineId == routineId).toList());

  @override
  Future<Either<Failure, List<Exercise>>> getExercisesForDay(
    String routineDayId,
  ) async => Right(_dayById(routineDayId).exercises);

  @override
  Future<Either<Failure, String?>> getRoutineDayNameById(
    String routineDayId,
  ) async => Right(_dayById(routineDayId).name);

  @override
  Future<Either<Failure, WeeklyInsights>> getWeeklyInsights({
    required String routineId,
    required DateTime weekStart,
  }) async {
    final weekEnd = AppCalendar.addDays(weekStart, 6);
    // Como `compute_weekly_insights_v1`: sólo los días de esta rutina, y la
    // adherencia en 0–100 (días distintos completados / días planificados).
    final routineDays = days.where((d) => d.routineId == routineId).toList();
    final dayIds = {for (final d in routineDays) d.id};
    final done = _inRange(weekStart, weekEnd)
        .where((s) => s.completedAt != null && dayIds.contains(s.routineDayId))
        .toList();
    final completedDays = done.map((s) => s.routineDayId).toSet().length;
    double volume(Iterable<WorkoutSession> list) => list
        .expand((s) => logsOf(s.id))
        .fold(0, (sum, l) => sum + l.actualWeight * l.actualReps);
    return Right(
      WeeklyInsights(
        weekStart: weekStart,
        weekEnd: weekEnd,
        plannedDays: routineDays.length,
        completedDays: completedDays,
        completedSessions: done.length,
        adherenceRate: routineDays.isEmpty
            ? 0
            : completedDays / routineDays.length * 100,
        totalVolume: volume(done),
        previousWeekVolume: 0,
        volumeTrendPercent: 0,
        personalRecords: 0,
      ),
    );
  }

  // ── Sesiones ───────────────────────────────────────────────────────────

  Iterable<WorkoutSession> _inRange(DateTime from, DateTime to) =>
      sessions.where(
        (s) =>
            !s.sessionDate.isBefore(DateUtils.dateOnly(from)) &&
            !s.sessionDate.isAfter(DateUtils.dateOnly(to)),
      );

  @override
  Future<Either<Failure, List<WorkoutSession>>> getWeekSessions(
    String userId,
    DateTime weekStart,
    DateTime weekEnd,
  ) async => Right(_inRange(weekStart, weekEnd).map(_withCounts).toList());

  @override
  Future<Either<Failure, WorkoutSession?>> getExistingSession(
    String userId,
    String routineDayId,
    DateTime sessionDate,
  ) async {
    final match = sessions.where(
      (s) =>
          s.routineDayId == routineDayId &&
          (s.completedAt == null ||
              DateUtils.isSameDay(s.sessionDate, sessionDate)),
    );
    return Right(match.isEmpty ? null : _withCounts(match.last));
  }

  @override
  Future<Either<Failure, WorkoutSession?>> getActiveSessionForUser(
    String userId,
  ) async {
    final open = openSession;
    return Right(open == null ? null : _withCounts(open));
  }

  @override
  Future<Either<Failure, List<WorkoutSession>>> getRecentSessionsForDay(
    String userId,
    String routineDayId,
    DateTime beforeDate, {
    int limit = 3,
  }) async {
    final list =
        sessions
            .where(
              (s) =>
                  s.routineDayId == routineDayId &&
                  s.completedAt != null &&
                  s.sessionDate.isBefore(DateUtils.dateOnly(beforeDate)),
            )
            .map(_withCounts)
            .toList()
          ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
    return Right(list.take(limit).toList());
  }

  @override
  Future<Either<Failure, WorkoutSession>> startWorkoutForDay(
    String userId,
    String routineDayId,
    DateTime sessionDate,
  ) async {
    final existing = openSession;
    if (existing != null && existing.routineDayId == routineDayId) {
      return Right(_withCounts(existing));
    }
    final session = WorkoutSession(
      id: 'session-${++_ids}',
      userId: userId,
      routineDayId: routineDayId,
      sessionDate: DateUtils.dateOnly(sessionDate),
    );
    sessions.add(session);
    return Right(_withCounts(session));
  }

  @override
  Future<Either<Failure, List<Exercise>>> getSessionExercises(
    String sessionId, {
    String? routineDayId,
  }) async {
    final session = sessions.firstWhere((s) => s.id == sessionId);
    return Right(
      sessionPlans[sessionId] ?? _dayById(session.routineDayId).exercises,
    );
  }

  /// Como `adapt_session_exercise_v1`: añade [exerciseId] al plan de la
  /// sesión; con [replaceExerciseId] el original se queda con las series ya
  /// hechas y el nuevo ocupa su sitio.
  @override
  Future<Either<Failure, List<Exercise>>> adaptSessionExercise(
    String sessionId,
    String exerciseId, {
    required int targetSets,
    required int targetReps,
    required double targetWeight,
    String? replaceExerciseId,
  }) async {
    final plan = List.of(
      (await getSessionExercises(sessionId)).getOrElse((_) => const []),
    );
    final item = catalog.firstWhere((c) => c.id == exerciseId);
    final session = sessions.firstWhere((s) => s.id == sessionId);
    String? replaces;
    if (replaceExerciseId != null) {
      final i = plan.indexWhere((e) => e.id == replaceExerciseId);
      final done = logsOf(
        sessionId,
      ).where((l) => l.exerciseId == replaceExerciseId).length;
      replaces = plan[i].name;
      plan[i] = plan[i].copyWith(
        targetSets: done,
        replacedByExerciseName: item.name,
      );
    }
    plan.add(
      Exercise(
        id: item.id,
        routineDayId: session.routineDayId,
        name: item.name,
        targetMuscle: item.muscleGroup,
        targetWeight: targetWeight,
        targetReps: targetReps,
        targetSets: targetSets,
        isExtra: replaceExerciseId == null,
        replacesExerciseName: replaces,
      ),
    );
    sessionPlans[sessionId] = plan;
    return Right(plan);
  }

  @override
  Stream<WorkoutSession?> watchSession(String id) => const Stream.empty();

  @override
  Future<Either<Failure, void>> finishWorkoutSession(
    String sessionId, {
    List<CoachingAnalysis>? coachingAnalysis,
  }) async {
    final i = sessions.indexWhere((s) => s.id == sessionId);
    sessions[i] = sessions[i].copyWith(completedAt: DateTime.now());
    finishedSessionIds.add(sessionId);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<RoutineHistorySession>>> getRoutineStats(
    String userId,
    String routineId,
  ) async {
    final dayIds = {
      for (final d in days)
        if (d.routineId == routineId) d.id,
    };
    return Right(
      [
        for (final s in sessions)
          if (s.completedAt != null && dayIds.contains(s.routineDayId))
            RoutineHistorySession(
              sessionId: s.id,
              sessionDate: s.sessionDate,
              routineDayId: s.routineDayId,
              routineDayName: _dayById(s.routineDayId).name,
              totalVolume: logsOf(
                s.id,
              ).fold(0, (sum, l) => sum + l.actualWeight * l.actualReps),
              totalReps: logsOf(s.id).fold(0, (sum, l) => sum + l.actualReps),
              setCount: logsOf(s.id).length,
            ),
      ]..sort((a, b) => b.sessionDate.compareTo(a.sessionDate)),
    );
  }

  @override
  Future<Either<Failure, List<ExerciseHistorySession>>> getExerciseLogsHistory(
    String userId,
    String exerciseId,
  ) async => Right(
    [
      for (final s in sessions)
        if (s.completedAt != null)
          if (logsOf(s.id).where((l) => l.exerciseId == exerciseId).toList()
              case final exLogs when exLogs.isNotEmpty)
            ExerciseHistorySession(sessionDate: s.sessionDate, logs: exLogs),
    ]..sort((a, b) => b.sessionDate.compareTo(a.sessionDate)),
  );

  @override
  Future<Either<Failure, List<CoachingAnalysis>>> getSessionCoaching(
    String sessionId,
  ) async => const Right([]);

  @override
  Future<Either<Failure, void>> discardWorkoutSession(String sessionId) async {
    sessions.removeWhere((s) => s.id == sessionId);
    logs.remove(sessionId);
    discardedSessionIds.add(sessionId);
    return const Right(null);
  }

  // ── Gestión de rutinas ─────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<Routine>>> getAllRoutines() async =>
      Right(routines.map(_withExerciseCount).toList());

  @override
  Future<Either<Failure, Routine>> getRoutineById(String routineId) async =>
      Right(_withExerciseCount(routines.firstWhere((r) => r.id == routineId)));

  @override
  Future<Either<Failure, Routine>> saveRoutine(Routine routine) async {
    final i = routines.indexWhere((r) => r.id == routine.id);
    final saved = i < 0
        ? routine.copyWith(id: 'routine-${++_ids}', creatorId: userId)
        : routine;
    if (i < 0) {
      routines.add(saved);
    } else {
      routines[i] = saved;
    }
    return Right(_withExerciseCount(saved));
  }

  @override
  Future<Either<Failure, void>> assignRoutineToUser(
    String userId,
    String routineId,
  ) async => const Right(null);

  @override
  Future<Either<Failure, RoutineDay>> saveRoutineDay(RoutineDay day) async {
    final i = days.indexWhere((d) => d.id == day.id);
    final saved = i < 0 ? day.copyWith(id: 'day-${++_ids}') : day;
    if (i < 0) {
      days.add(saved);
    } else {
      days[i] = days[i].copyWith(name: day.name, dayOfWeek: day.dayOfWeek);
    }
    return Right(_dayById(saved.id));
  }

  @override
  Future<Either<Failure, List<ExerciseCatalogItem>>> getExercisesCatalog({
    String? muscleGroup,
    String? search,
    int limit = 200,
  }) async => Right(
    catalog
        .where((c) => muscleGroup == null || c.muscleGroup == muscleGroup)
        .where(
          (c) =>
              search == null ||
              c.name.toLowerCase().contains(search.toLowerCase()),
        )
        .take(limit)
        .toList(),
  );

  @override
  Future<Either<Failure, void>> addExerciseToDay(
    String dayId,
    String exerciseId, {
    required int targetSets,
    required int targetReps,
    required double targetWeight,
    int restSeconds = 90,
  }) => addExercisesToDay(dayId, [
    AddExerciseToDayPayload(
      exerciseId: exerciseId,
      targetSets: targetSets,
      targetReps: targetReps,
      targetWeight: targetWeight,
      restSeconds: restSeconds,
    ),
  ]);

  @override
  Future<Either<Failure, void>> addExercisesToDay(
    String dayId,
    List<AddExerciseToDayPayload> items,
  ) async {
    final added = [
      for (final p in items)
        if (catalog.firstWhere((c) => c.id == p.exerciseId) case final item)
          Exercise(
            id: item.id,
            routineDayId: dayId,
            name: item.name,
            targetMuscle: item.muscleGroup,
            targetWeight: p.targetWeight,
            targetReps: p.targetReps,
            targetSets: p.targetSets,
            restTimerSeconds: p.restSeconds,
          ),
    ];
    _setDayExercises(dayId, [..._dayById(dayId).exercises, ...added]);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> removeExerciseFromDay(
    String dayId,
    String exerciseId,
  ) async {
    _setDayExercises(dayId, [
      for (final e in _dayById(dayId).exercises)
        if (e.id != exerciseId) e,
    ]);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateExerciseTarget(
    String routineDayId,
    String exerciseId,
    double targetWeight,
    int targetReps, {
    int? targetSets,
    int? restSeconds,
  }) async {
    _setDayExercises(routineDayId, [
      for (final e in _dayById(routineDayId).exercises)
        if (e.id == exerciseId)
          e.copyWith(
            targetWeight: targetWeight,
            targetReps: targetReps,
            targetSets: targetSets ?? e.targetSets,
            restTimerSeconds: restSeconds ?? e.restTimerSeconds,
          )
        else
          e,
    ]);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> reorderExercisesInDay(
    String dayId,
    List<String> exerciseIds,
  ) async {
    final byId = {for (final e in _dayById(dayId).exercises) e.id: e};
    _setDayExercises(dayId, [for (final id in exerciseIds) byId[id]!]);
    return const Right(null);
  }

  // ── Series ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> saveSetLog(SetLog setLog) async {
    final list = logs.putIfAbsent(setLog.sessionId, () => []);
    list
      ..removeWhere(
        (l) =>
            l.exerciseId == setLog.exerciseId && l.setIndex == setLog.setIndex,
      )
      ..add(setLog.copyWith(id: setLog.id ?? 'log-${++_ids}'));
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> deleteSetLog({
    required String sessionId,
    required String exerciseId,
    required int setIndex,
  }) async {
    logs[sessionId]?.removeWhere(
      (l) => l.exerciseId == exerciseId && l.setIndex == setIndex,
    );
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<SetLog>>> getSessionSetLogs(
    String sessionId,
  ) async => Right(List.of(logsOf(sessionId)));

  @override
  Future<Either<Failure, Map<String, List<SetLog>>>> getSetLogsForSessions(
    List<String> sessionIds,
  ) async => Right({for (final id in sessionIds) id: List.of(logsOf(id))});

  @override
  Future<Either<Failure, Map<String, SetLog?>>> getLastExercisePerformances(
    List<String> exerciseIds,
  ) async {
    final closed = sessions.where((s) => s.completedAt != null).toList()
      ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
    SetLog? best(String exerciseId) {
      for (final s in closed) {
        final sets = logsOf(s.id).where((l) => l.exerciseId == exerciseId);
        if (sets.isEmpty) continue;
        return sets.reduce((a, b) => b.actualWeight > a.actualWeight ? b : a);
      }
      return null;
    }

    return Right({for (final id in exerciseIds) id: best(id)});
  }
}

/// Auth en memoria: arranca sin sesión (o con ella si [signedIn]) y acepta
/// cualquier contraseña salvo [wrongPassword].
class FakeAuthRepository extends Fake implements AuthRepository {
  FakeAuthRepository({bool signedIn = false}) : _signedIn = signedIn;

  static const user = User(
    id: FakeWorkoutRepository.userId,
    email: 'atleta@test.com',
    fullName: 'Atleta Test',
  );
  static const wrongPassword = 'incorrecta';

  bool _signedIn;
  final _auth = StreamController<bool>.broadcast();

  @override
  Stream<bool> get authStateChanges async* {
    yield _signedIn;
    yield* _auth.stream;
  }

  @override
  Stream<void> get passwordRecoveryEvents => const Stream.empty();

  @override
  Future<Either<Failure, User?>> getCurrentUser() async =>
      Right(_signedIn ? user : null);

  @override
  Future<Either<Failure, User>> signInWithEmail(
    String email,
    String password,
  ) async {
    if (password == wrongPassword) {
      return const Left(AuthFailure('Correo o contraseña incorrectos'));
    }
    _signedIn = true;
    _auth.add(true);
    return const Right(user);
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    _signedIn = false;
    _auth.add(false);
    return const Right(null);
  }
}

/// Perfil en memoria: renombrar devuelve el nombre recibido y eliminar la
/// cuenta siempre va bien.
class FakeProfileRepository implements ProfileRepository {
  @override
  Future<Either<Failure, String?>> updateFullName({
    required String userId,
    required String fullName,
  }) async => Right(fullName);

  @override
  Future<Either<Failure, void>> deleteAccount({
    required String confirmation,
  }) async => const Right(null);
}

/// Notificaciones, Live Activities y el notifier de sesión no tienen sentido
/// en las pruebas: cada llamada es un no-op.
class _NoopAsync {
  dynamic _noop(Invocation invocation) {
    if (invocation.isGetter) return false;
    if (invocation.memberName == #requestPermission) {
      return Future<bool>.value(true);
    }
    return Future<void>.value();
  }
}

class NoopNotificationService extends _NoopAsync
    implements NotificationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => _noop(invocation);
}

class NoopLiveActivitiesBridge extends _NoopAsync
    implements LiveActivitiesBridge {
  @override
  dynamic noSuchMethod(Invocation invocation) => _noop(invocation);
}

class NoopActiveWorkoutNotifier extends _NoopAsync
    implements ActiveWorkoutNotifier {
  @override
  dynamic noSuchMethod(Invocation invocation) => _noop(invocation);
}
