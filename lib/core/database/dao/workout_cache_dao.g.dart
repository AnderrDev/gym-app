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
}
