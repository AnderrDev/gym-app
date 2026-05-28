import 'package:fpdart/fpdart.dart';

import 'package:gym_flutter/core/error/error_mapper.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/data/datasources/workout_remote_data_source.dart';
import 'package:gym_flutter/features/workout/data/models/routine_day_model.dart';
import 'package:gym_flutter/features/workout/data/models/routine_model.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_catalog_item.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_detail.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';

/// Mixin que agrupa los métodos de **gestión** del repositorio (CRUD de
/// rutinas/días/ejercicios + catálogo). Separado del impl principal para que
/// `workout_repository_impl.dart` quede bajo control de complejidad.
mixin WorkoutRepositoryRoutineMgmtMixin on WorkoutRepository {
  WorkoutRemoteDataSource get remoteDataSource;

  @override
  Future<Either<Failure, void>> assignRoutineToUser(
    String userId,
    String routineId,
  ) =>
      guard(() => remoteDataSource.assignRoutineToUser(userId, routineId));

  @override
  Future<Either<Failure, Routine>> saveRoutine(Routine routine) =>
      guard(() async {
        final saved =
            await remoteDataSource.saveRoutine(RoutineModel.fromEntity(routine));
        return saved.toEntity();
      });

  @override
  Future<Either<Failure, void>> deleteRoutine(String routineId) =>
      guard(() => remoteDataSource.deleteRoutine(routineId));

  @override
  Future<Either<Failure, String>> forkRoutine(
    String sourceRoutineId, {
    String? newName,
  }) =>
      guard(
        () => remoteDataSource.forkRoutine(sourceRoutineId, newName: newName),
      );

  @override
  Future<Either<Failure, RoutineDay>> saveRoutineDay(RoutineDay day) =>
      guard(() async {
        final saved =
            await remoteDataSource.saveRoutineDay(RoutineDayModel.fromEntity(day));
        return saved.toEntity();
      });

  @override
  Future<Either<Failure, void>> deleteRoutineDay(String dayId) =>
      guard(() => remoteDataSource.deleteRoutineDay(dayId));

  @override
  Future<Either<Failure, void>> addExerciseToDay(
    String dayId,
    String exerciseId, {
    required int targetSets,
    required int targetReps,
    required double targetWeight,
    int restSeconds = 90,
  }) =>
      guard(
        () => remoteDataSource.addExerciseToDay(
          dayId,
          exerciseId,
          targetSets: targetSets,
          targetReps: targetReps,
          targetWeight: targetWeight,
          restSeconds: restSeconds,
        ),
      );

  @override
  Future<Either<Failure, void>> addExercisesToDay(
    String dayId,
    List<AddExerciseToDayPayload> items,
  ) =>
      guard(
        () => remoteDataSource.addExercisesToDay(
          dayId,
          items
              .map(
                (p) => AddExerciseToDayItem(
                  exerciseId: p.exerciseId,
                  targetSets: p.targetSets,
                  targetReps: p.targetReps,
                  targetWeight: p.targetWeight,
                  restSeconds: p.restSeconds,
                ),
              )
              .toList(),
        ),
      );

  @override
  Future<Either<Failure, void>> removeExerciseFromDay(
    String dayId,
    String exerciseId,
  ) =>
      guard(() => remoteDataSource.removeExerciseFromDay(dayId, exerciseId));

  @override
  Future<Either<Failure, void>> reorderExercisesInDay(
    String dayId,
    List<String> exerciseIds,
  ) =>
      guard(() => remoteDataSource.reorderExercisesInDay(dayId, exerciseIds));

  @override
  Future<Either<Failure, void>> updateExerciseTarget(
    String routineDayId,
    String exerciseId,
    double targetWeight,
    int targetReps, {
    int? targetSets,
    int? restSeconds,
  }) =>
      guard(
        () => remoteDataSource.updateExerciseTarget(
          routineDayId,
          exerciseId,
          targetWeight,
          targetReps,
          targetSets: targetSets,
          restSeconds: restSeconds,
        ),
      );

  @override
  Future<Either<Failure, List<ExerciseCatalogItem>>> getExercisesCatalog({
    String? muscleGroup,
    String? search,
    int limit = 200,
  }) =>
      guard(
        () => remoteDataSource.getExercisesCatalog(
          muscleGroup: muscleGroup,
          search: search,
          limit: limit,
        ),
      );

  @override
  Future<Either<Failure, ExerciseDetail>> getExerciseDetail(
    String exerciseId,
  ) =>
      guard(() => remoteDataSource.getExerciseDetail(exerciseId));

  @override
  Future<Either<Failure, List<Routine>>> getAllRoutines() => guard(
        () async => (await remoteDataSource.getAllRoutines())
            .map((m) => m.toEntity())
            .toList(),
      );

  @override
  Future<Either<Failure, Routine>> getRoutineById(String routineId) =>
      guard(() async => (await remoteDataSource.getRoutineById(routineId)).toEntity());

  @override
  Future<Either<Failure, String?>> getRoutineDayNameById(
    String routineDayId,
  ) =>
      guard(() => remoteDataSource.getRoutineDayNameById(routineDayId));
}
