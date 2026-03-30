import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/set_log_model.dart';
import '../models/workout_session_model.dart';

abstract class WorkoutLocalDataSource {
  Future<void> cacheSetLog(SetLogModel setLog);
  Future<List<SetLogModel>> getUnsyncedSetLogs();
  Future<void> markSetLogAsSynced(String id);
  
  Future<void> cacheWorkoutSession(WorkoutSessionModel session);
  Future<List<WorkoutSessionModel>> getUnsyncedWorkoutSessions();
  Future<void> markWorkoutSessionAsSynced(String id);

  Future<SetLogModel?> getLastExercisePerformance(String exerciseId);
}

class WorkoutLocalDataSourceImpl implements WorkoutLocalDataSource {
  final DatabaseHelper dbHelper;

  WorkoutLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<void> cacheSetLog(SetLogModel setLog) async {
    final db = await dbHelper.database;
    await db.insert(
      'set_logs',
      {
        ...setLog.toJson(),
        'is_synced': 0,
        'created_at': setLog.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
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
    await db.update(
      'set_logs',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> cacheWorkoutSession(WorkoutSessionModel session) async {
    final db = await dbHelper.database;
    await db.insert(
      'workouts',
      {
        ...session.toJson(),
        'is_synced': 0,
      },
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
    await db.update(
      'workouts',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
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
    if (maps.isNotEmpty) {
      return SetLogModel.fromJson(maps.first);
    }
    return null;
  }
}
