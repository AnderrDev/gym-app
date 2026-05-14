import '../../domain/entities/routine_day.dart';
import '../../domain/entities/exercise.dart';
import 'exercise_model.dart';

class RoutineDayModel extends RoutineDay {
  const RoutineDayModel({
    required super.id,
    required super.routineId,
    required super.dayOfWeek,
    required super.name,
    super.exercises,
    super.targetSetsCount,
    super.status,
    super.exerciseNamesPreview,
  });

  factory RoutineDayModel.fromJson(
    Map<String, dynamic> json, {
    List<Exercise> exercises = const [],
  }) {
    final exercisesData = json['routine_exercises'] as List<dynamic>? ?? [];
    var totalTargetSets = 0;
    final names = <String>[];
    for (final ex in exercisesData) {
      final exMap = ex as Map<String, dynamic>;
      totalTargetSets += (exMap['target_sets'] as int? ?? 0);
      // Nombre del ejercicio si el join lo trae (consumer-dependent: getRoutineDays
      // pide `exercises(name)` para preview, pero no todos los queries lo hacen).
      final exerciseJoin = exMap['exercises'] as Map<String, dynamic>?;
      final name = exerciseJoin?['name'] as String?;
      if (name != null && name.isNotEmpty) names.add(name);
    }

    return RoutineDayModel(
      id: json['id'] as String,
      routineId: json['routine_id'] as String,
      dayOfWeek: json['day_of_week'] as int,
      name: json['name'] as String,
      exercises: exercises,
      targetSetsCount: totalTargetSets,
      status: _statusFromName(json['status'] as String?),
      exerciseNamesPreview: List.unmodifiable(names),
    );
  }

  /// Las columnas escribibles son `id`, `routine_id`, `day_of_week`, `name`.
  /// Los campos derivados (`exercises`, `target_sets_count`, `status`) se
  /// incluyen también para que el round-trip `toJson → fromJson` preserve
  /// el estado en memoria (cache, tests, debug); el datasource ignora esas
  /// keys al hacer insert/update.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routine_id': routineId,
      'day_of_week': dayOfWeek,
      'name': name,
      'target_sets_count': targetSetsCount,
      'status': status.name,
      'exercises': exercises
          .map((e) => e is ExerciseModel
              ? e.toJson()
              : ExerciseModel(
                  id: e.id,
                  routineDayId: e.routineDayId,
                  name: e.name,
                  targetMuscle: e.targetMuscle,
                  targetWeight: e.targetWeight,
                  targetReps: e.targetReps,
                  targetSets: e.targetSets,
                  restTimerSeconds: e.restTimerSeconds,
                ).toJson())
          .toList(),
    };
  }

  static WorkoutDayStatus _statusFromName(String? name) {
    if (name == null) return WorkoutDayStatus.pending;
    for (final v in WorkoutDayStatus.values) {
      if (v.name == name) return v;
    }
    return WorkoutDayStatus.pending;
  }

  RoutineDayModel copyWithStatus(WorkoutDayStatus newStatus) {
    return RoutineDayModel(
      id: id,
      routineId: routineId,
      dayOfWeek: dayOfWeek,
      name: name,
      exercises: exercises,
      targetSetsCount: targetSetsCount,
      status: newStatus,
    );
  }

  RoutineDayModel copyWithExercises(List<ExerciseModel> newExercises) {
    int totalTargetSets = 0;
    for (var ex in newExercises) {
      totalTargetSets += ex.targetSets;
    }
    return RoutineDayModel(
      id: id,
      routineId: routineId,
      dayOfWeek: dayOfWeek,
      name: name,
      exercises: newExercises,
      targetSetsCount: totalTargetSets,
      status: status,
    );
  }
}
