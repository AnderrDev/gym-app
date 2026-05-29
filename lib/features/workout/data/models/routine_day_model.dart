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
    final dayId = json['id'] as String;
    final exercisesData = json['routine_exercises'] as List<dynamic>? ?? [];
    var totalTargetSets = 0;
    final names = <String>[];
    // Hidratamos `exercises` desde el join sólo si el caller no inyectó una
    // lista pre-armada. `getRoutineDays` ahora trae las columnas completas
    // (id, muscle_group, target_*) y el day editor depende de `exercises`
    // para pintar la lista — antes quedaba siempre vacío.
    final hydrated = <Exercise>[];
    final shouldHydrate = exercises.isEmpty;
    for (final ex in exercisesData) {
      final exMap = ex as Map<String, dynamic>;
      totalTargetSets += (exMap['target_sets'] as int? ?? 0);
      final exerciseJoin = exMap['exercises'] as Map<String, dynamic>?;
      final name = exerciseJoin?['name'] as String?;
      if (name != null && name.isNotEmpty) names.add(name);
      if (!shouldHydrate) continue;
      final exId = exerciseJoin?['id'] as String?;
      if (exId == null || name == null || name.isEmpty) continue;
      hydrated.add(
        ExerciseModel(
          id: exId,
          routineDayId: dayId,
          name: name,
          targetMuscle: (exerciseJoin?['muscle_group'] as String?) ?? '',
          targetWeight: (exMap['target_weight'] as num?)?.toDouble() ?? 0.0,
          targetReps: (exMap['target_reps'] as num?)?.toInt() ?? 0,
          targetSets: (exMap['target_sets'] as num?)?.toInt() ?? 3,
          restTimerSeconds:
              (exMap['rest_timer_seconds'] as num?)?.toInt() ?? 90,
        ),
      );
    }

    return RoutineDayModel(
      id: dayId,
      routineId: json['routine_id'] as String,
      dayOfWeek: json['day_of_week'] as int,
      name: json['name'] as String,
      exercises: shouldHydrate ? hydrated : exercises,
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
