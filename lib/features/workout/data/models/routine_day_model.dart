import '../../domain/entities/routine_day.dart';
import '../../domain/entities/exercise.dart';
import 'exercise_model.dart';

/// Modelo de datos para `RoutineDay`. Clase hermana (no extiende la entity
/// freezed): (de)serializa el JSON anidado de la DB. La conversión hacia/desde
/// la entidad vive en `workout_repository_mappers.dart`.
class RoutineDayModel {
  final String id;
  final String routineId;
  final int dayOfWeek;
  final String name;
  final List<Exercise> exercises;
  final int targetSetsCount;
  final WorkoutDayStatus status;
  final List<String> exerciseNamesPreview;

  const RoutineDayModel({
    required this.id,
    required this.routineId,
    required this.dayOfWeek,
    required this.name,
    this.exercises = const [],
    this.targetSetsCount = 0,
    this.status = WorkoutDayStatus.pending,
    this.exerciseNamesPreview = const [],
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
        Exercise(
          id: exId,
          routineDayId: dayId,
          name: name,
          targetMuscle: (exerciseJoin?['muscle_group'] as String?) ?? '',
          targetWeight: (exMap['target_weight'] as num?)?.toDouble() ?? 0.0,
          targetReps: (exMap['target_reps'] as num?)?.toInt() ?? 0,
          targetSets: (exMap['target_sets'] as num?)?.toInt() ?? 3,
          restTimerSeconds: (exMap['rest_timer_seconds'] as num?)?.toInt() ?? 90,
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

  /// Las columnas escribibles son `id`, `routine_id`, `day_of_week`, `name`;
  /// el datasource ignora el resto al hacer insert/update. Los campos
  /// derivados (`exercises`, `target_sets_count`, `status`) se incluyen sólo
  /// para inspección/debug — `fromJson` NO los re-lee (espera el join
  /// `routine_exercises`), así que el round-trip `toJson → fromJson` no es
  /// idempotente para esos campos ni para `exercise_names_preview`.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routine_id': routineId,
      'day_of_week': dayOfWeek,
      'name': name,
      'target_sets_count': targetSetsCount,
      'status': status.name,
      'exercises': exercises
          .map((e) => ExerciseModel.fromEntity(e).toJson())
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
}
