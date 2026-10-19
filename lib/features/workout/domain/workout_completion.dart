import 'dart:math' as math;
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';

int totalTargetSets(List<Exercise> exercises) =>
    exercises.fold(0, (sum, exercise) => sum + exercise.targetSets);

int completedTargetSets(List<Exercise> exercises, List<SetLog> logs) =>
    exercises.fold(
      0,
      (sum, exercise) =>
          sum +
          math.min(
            exercise.targetSets,
            logs.where((log) => log.exerciseId == exercise.id).length,
          ),
    );
