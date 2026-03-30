import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/routine_model.dart';
import '../models/set_log_model.dart';
import '../models/workout_session_model.dart';
import '../models/exercise_model.dart';

abstract class WorkoutRemoteDataSource {
  Future<List<RoutineModel>> getAssignedRoutines(String userId);
  Future<SetLogModel?> getLastExercisePerformance(String exerciseId);
  Future<void> saveSetLog(SetLogModel setLog);
  Future<void> finishWorkoutSession(String sessionId, double totalVolume);
  Future<void> assignRoutineToUser(String userId, String routineId);
  Future<WorkoutSessionModel> startWorkoutSession(
    String userId,
    String routineId,
  );
  Future<List<ExerciseModel>> getRoutineExercises(String routineId);
}

class WorkoutRemoteDataSourceImpl implements WorkoutRemoteDataSource {
  final SupabaseClient client;

  WorkoutRemoteDataSourceImpl({required this.client});

  @override
  Future<List<RoutineModel>> getAssignedRoutines(String userId) async {
    // Queremos obtener las rutinas asignadas al usuario desde 'user_routines'
    // uniendo (join) 'routines' para su título y 'routine_exercises' para el count.
    final response = await client
        .from('user_routines')
        .select('''
          routine_id,
          routines (
            id,
            name,
            routine_exercises (count)
          )
        ''')
        .eq('user_id', userId);

    return response.map((data) {
      final routineData = data['routines'] as Map<String, dynamic>? ?? {};
      int exerciseCount = 0;

      if (routineData['routine_exercises'] != null &&
          (routineData['routine_exercises'] as List).isNotEmpty) {
        final rawCount = routineData['routine_exercises'][0]['count'];
        exerciseCount = rawCount is int ? rawCount : 0;
      }

      return RoutineModel(
        id: (routineData['id'] ?? data['routine_id']).toString(),
        name: (routineData['name'] ?? 'Rutina Asignada').toString(),
        exerciseCount: exerciseCount,
      );
    }).toList();
  }

  @override
  Future<SetLogModel?> getLastExercisePerformance(String exerciseId) async {
    final response = await client
        .from('set_logs')
        .select()
        .eq('exercise_id', exerciseId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return SetLogModel.fromJson(response);
  }

  @override
  Future<void> saveSetLog(SetLogModel setLog) async {
    final payload = setLog.toJson();
    // Allow Supabase to generate the UUID
    payload.remove('id');
    await client.from('set_logs').insert(payload);
  }

  @override
  Future<void> finishWorkoutSession(
    String sessionId,
    double totalVolume,
  ) async {
    await client
        .from('workout_sessions')
        .update({
          'completed_at': DateTime.now().toIso8601String(),
          'total_volume': totalVolume,
        })
        .eq('id', sessionId);
  }

  @override
  Future<void> assignRoutineToUser(String userId, String routineId) async {
    await client.from('user_routines').insert({
      'user_id': userId,
      'routine_id': routineId,
    });
  }

  @override
  Future<WorkoutSessionModel> startWorkoutSession(
    String userId,
    String routineId,
  ) async {
    final response = await client
        .from('workout_sessions')
        .insert({
          'user_id': userId,
          'routine_id': routineId,
          // 'started_at' is handled by DB default
        })
        .select()
        .single();

    return WorkoutSessionModel.fromJson(response);
  }

  @override
  Future<List<ExerciseModel>> getRoutineExercises(String routineId) async {
    final response = await client
        .from('routine_exercises')
        .select('''
          id,
          order,
          target_sets,
          target_reps,
          target_weight,
          exercises (
            id,
            name
          )
        ''')
        .eq('routine_id', routineId)
        .order('order', ascending: true);

    return response.map((json) {
      final exerciseData = json['exercises'] as Map<String, dynamic>;
      return ExerciseModel(
        id: (json['id'] ?? exerciseData['id']).toString(),
        routineId: routineId,
        name: exerciseData['name'] as String,
        targetWeight: (json['target_weight'] as num?)?.toDouble() ?? 0.0,
        targetReps: json['target_reps'] as int,
      );
    }).toList();
  }
}
