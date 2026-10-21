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
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
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
  ) async => Right(List.of(routines));

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
    final done = _inRange(
      weekStart,
      weekEnd,
    ).where((s) => s.completedAt != null).toList();
    double volume(Iterable<WorkoutSession> list) => list
        .expand((s) => logsOf(s.id))
        .fold(0, (sum, l) => sum + l.actualWeight * l.actualReps);
    return Right(
      WeeklyInsights(
        weekStart: weekStart,
        weekEnd: weekEnd,
        plannedDays: days.length,
        completedDays: done.map((s) => s.routineDayId).toSet().length,
        completedSessions: done.length,
        adherenceRate: days.isEmpty ? 0 : done.length / days.length,
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
    return Right(_dayById(session.routineDayId).exercises);
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
