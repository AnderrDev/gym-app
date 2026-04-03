import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/exercise_model.dart';
import '../models/routine_day_model.dart';
import '../models/set_log_model.dart';
import '../models/workout_session_model.dart';

abstract class WorkoutLocalDataSource {
  // Set Logs
  Future<void> cacheSetLog(SetLogModel setLog);
  Future<List<SetLogModel>> getUnsyncedSetLogs();
  Future<void> markSetLogAsSynced(String id);
  Future<SetLogModel?> getLastExercisePerformance(String exerciseId);
  Future<List<SetLogModel>> getSessionSetLogs(String sessionId);

  // Workout Sessions
  Future<void> cacheWorkoutSession(WorkoutSessionModel session);
  Future<List<WorkoutSessionModel>> getUnsyncedWorkoutSessions();
  Future<void> markWorkoutSessionAsSynced(String id);
  Future<List<WorkoutSessionModel>> getWeekSessionsLocal(DateTime weekStart, DateTime weekEnd);

  // Exercises (per day)
  Future<void> cacheExercisesForDay(String routineDayId, List<ExerciseModel> exercises);
  Future<List<ExerciseModel>> getExercisesForDayLocal(String routineDayId);

  // Routine Days
  Future<void> cacheRoutineDays(List<RoutineDayModel> days);
  Future<List<RoutineDayModel>> getRoutineDaysLocal(String routineId);
}

class WorkoutLocalDataSourceImpl implements WorkoutLocalDataSource {
  final DatabaseHelper dbHelper;
  WorkoutLocalDataSourceImpl({required this.dbHelper});

  // ─── SET LOGS ────────────────────────────────────────────────────────────────
  // Bug Fix: id es nullable en set_logs; created_at tiene DEFAULT en SQLite.
  // Nunca pasamos id al INSERT (SQLite usará rowid interno), ni created_at.
  @override
  Future<void> cacheSetLog(SetLogModel setLog) async {
    final db = await dbHelper.database;
    await db.insert(
      'set_logs',
      {
        'session_id':    setLog.sessionId,
        'exercise_id':   setLog.exerciseId,
        'actual_weight': setLog.actualWeight,
        'actual_reps':   setLog.actualReps,
        'set_index':     setLog.setIndex,
        'is_synced':     0,
        // created_at: el DEFAULT de SQLite lo genera automáticamente
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  @override
  Future<List<SetLogModel>> getUnsyncedSetLogs() async {
    final db = await dbHelper.database;
    final maps = await db.query('set_logs', where: 'is_synced = 0');
    return maps.map((json) => SetLogModel.fromJson(json)).toList();
  }

  @override
  Future<void> markSetLogAsSynced(String id) async {
    final db = await dbHelper.database;
    await db.update('set_logs', {'is_synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<SetLogModel?> getLastExercisePerformance(String exerciseId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'set_logs',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) return SetLogModel.fromJson(maps.first);
    return null;
  }

  @override
  Future<List<SetLogModel>> getSessionSetLogs(String sessionId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'set_logs',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'set_index ASC',
    );
    return maps.map((json) => SetLogModel.fromJson(json)).toList();
  }

  // ─── WORKOUT SESSIONS ────────────────────────────────────────────────────────
  @override
  Future<void> cacheWorkoutSession(WorkoutSessionModel session) async {
    final db = await dbHelper.database;
    await db.insert(
      'workouts',
      {...session.toJson(), 'is_synced': 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<WorkoutSessionModel>> getUnsyncedWorkoutSessions() async {
    final db = await dbHelper.database;
    final maps = await db.query('workouts', where: 'is_synced = 0');
    return maps.map((json) => WorkoutSessionModel.fromJson(json)).toList();
  }

  @override
  Future<void> markWorkoutSessionAsSynced(String id) async {
    final db = await dbHelper.database;
    await db.update('workouts', {'is_synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<WorkoutSessionModel>> getWeekSessionsLocal(
      DateTime weekStart, DateTime weekEnd) async {
    final db = await dbHelper.database;
    final startStr = _dateStr(weekStart);
    final endStr   = _dateStr(weekEnd);
    final maps = await db.query(
      'workouts',
      where: 'session_date >= ? AND session_date <= ?',
      whereArgs: [startStr, endStr],
    );
    return maps.map((json) => WorkoutSessionModel.fromJson(json)).toList();
  }

  // ─── EXERCISES ───────────────────────────────────────────────────────────────
  // Bug Fix: PK = '{routineDayId}_{exerciseId}' para que el mismo ejercicio
  // de catálogo pueda estar cacheado para múltiples días sin conflicto.
  @override
  Future<void> cacheExercisesForDay(
      String routineDayId, List<ExerciseModel> exercises) async {
    final db = await dbHelper.database;
    await db.delete('exercises', where: 'routine_day_id = ?', whereArgs: [routineDayId]);

    final batch = db.batch();
    for (final e in exercises) {
      batch.insert(
        'exercises',
        {
          'id':            '${routineDayId}_${e.id}', // composite PK
          'routine_day_id': routineDayId,
          'exercise_id':    e.id,                      // ID real del catálogo
          'name':           e.name,
          'target_weight':  e.targetWeight,
          'target_reps':    e.targetReps,
          'target_sets':    e.targetSets,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<ExerciseModel>> getExercisesForDayLocal(String routineDayId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'exercises',
      where: 'routine_day_id = ?',
      whereArgs: [routineDayId],
    );
    return maps.map((row) {
      return ExerciseModel(
        id: row['exercise_id'] as String,
        routineDayId: row['routine_day_id'] as String,
        name: row['name'] as String,
        targetMuscle: row['target_muscle'] as String? ?? 'Desconocido',
        targetWeight: (row['target_weight'] as num).toDouble(),
        targetReps: row['target_reps'] as int,
        targetSets: row['target_sets'] as int,
        restTimerSeconds: 90,
      );
    }).toList();
  }

  // ─── ROUTINE DAYS ────────────────────────────────────────────────────────────
  @override
  Future<void> cacheRoutineDays(List<RoutineDayModel> days) async {
    final db = await dbHelper.database;
    final batch = db.batch();
    for (final day in days) {
      batch.insert('routine_days', day.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<RoutineDayModel>> getRoutineDaysLocal(String routineId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'routine_days',
      where: 'routine_id = ?',
      whereArgs: [routineId],
      orderBy: 'day_of_week ASC',
    );
    return maps.map((json) => RoutineDayModel.fromJson(json)).toList();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────
  static String _dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
