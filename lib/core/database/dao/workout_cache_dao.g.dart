// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_cache_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkoutCacheDaoMixin on DatabaseAccessor<LocalDatabase> {
  $CachedRoutineDaysTable get cachedRoutineDays =>
      attachedDatabase.cachedRoutineDays;
  $CachedRoutineExercisesTable get cachedRoutineExercises =>
      attachedDatabase.cachedRoutineExercises;
  $CachedExercisesTable get cachedExercises => attachedDatabase.cachedExercises;
  $CachedLastPerformancesTable get cachedLastPerformances =>
      attachedDatabase.cachedLastPerformances;
  $CachedWorkoutSessionsTable get cachedWorkoutSessions =>
      attachedDatabase.cachedWorkoutSessions;
  $CachedSetLogsTable get cachedSetLogs => attachedDatabase.cachedSetLogs;
  $PendingMutationsTable get pendingMutations =>
      attachedDatabase.pendingMutations;
  $CachedAssignedRoutinesTable get cachedAssignedRoutines =>
      attachedDatabase.cachedAssignedRoutines;
  $CachedWeeklyInsightsTable get cachedWeeklyInsights =>
      attachedDatabase.cachedWeeklyInsights;
  WorkoutCacheDaoManager get managers => WorkoutCacheDaoManager(this);
}

class WorkoutCacheDaoManager {
  final _$WorkoutCacheDaoMixin _db;
  WorkoutCacheDaoManager(this._db);
  $$CachedRoutineDaysTableTableManager get cachedRoutineDays =>
      $$CachedRoutineDaysTableTableManager(
        _db.attachedDatabase,
        _db.cachedRoutineDays,
      );
  $$CachedRoutineExercisesTableTableManager get cachedRoutineExercises =>
      $$CachedRoutineExercisesTableTableManager(
        _db.attachedDatabase,
        _db.cachedRoutineExercises,
      );
  $$CachedExercisesTableTableManager get cachedExercises =>
      $$CachedExercisesTableTableManager(
        _db.attachedDatabase,
        _db.cachedExercises,
      );
  $$CachedLastPerformancesTableTableManager get cachedLastPerformances =>
      $$CachedLastPerformancesTableTableManager(
        _db.attachedDatabase,
        _db.cachedLastPerformances,
      );
  $$CachedWorkoutSessionsTableTableManager get cachedWorkoutSessions =>
      $$CachedWorkoutSessionsTableTableManager(
        _db.attachedDatabase,
        _db.cachedWorkoutSessions,
      );
  $$CachedSetLogsTableTableManager get cachedSetLogs =>
      $$CachedSetLogsTableTableManager(_db.attachedDatabase, _db.cachedSetLogs);
  $$PendingMutationsTableTableManager get pendingMutations =>
      $$PendingMutationsTableTableManager(
        _db.attachedDatabase,
        _db.pendingMutations,
      );
  $$CachedAssignedRoutinesTableTableManager get cachedAssignedRoutines =>
      $$CachedAssignedRoutinesTableTableManager(
        _db.attachedDatabase,
        _db.cachedAssignedRoutines,
      );
  $$CachedWeeklyInsightsTableTableManager get cachedWeeklyInsights =>
      $$CachedWeeklyInsightsTableTableManager(
        _db.attachedDatabase,
        _db.cachedWeeklyInsights,
      );
}
