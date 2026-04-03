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
  });

  factory RoutineDayModel.fromJson(Map<String, dynamic> json, {List<Exercise> exercises = const []}) {
    final exercisesData = json['routine_exercises'] as List<dynamic>? ?? [];
    int totalTargetSets = 0;
    for (var ex in exercisesData) {
      totalTargetSets += (ex['target_sets'] as int? ?? 0);
    }

    return RoutineDayModel(
      id: json['id'] as String,
      routineId: json['routine_id'] as String,
      dayOfWeek: json['day_of_week'] as int,
      name: json['name'] as String,
      exercises: exercises,
      targetSetsCount: totalTargetSets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routine_id': routineId,
      'day_of_week': dayOfWeek,
      'name': name,
    };
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
