import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/routine_day_model.dart';
import '../models/exercise_model.dart';
import '../models/set_log_model.dart';
import '../models/workout_session_model.dart';
import '../models/routine_model.dart';
import '../../domain/entities/coaching_analysis.dart';

abstract class WorkoutRemoteDataSource {
  Future<List<RoutineModel>> getAssignedRoutines(String userId);
  Future<List<RoutineDayModel>> getRoutineDays(String routineId);
  Future<List<ExerciseModel>> getExercisesForDay(String routineDayId);
  Future<List<WorkoutSessionModel>> getWeekSessions(
      String userId, DateTime weekStart, DateTime weekEnd);
  Future<WorkoutSessionModel> startWorkoutForDay(
      String userId, String routineDayId, DateTime sessionDate);
  Future<WorkoutSessionModel?> getExistingSession(
      String userId, String routineDayId, DateTime sessionDate);
  Future<void> saveSetLog(SetLogModel setLog);
  Future<SetLogModel?> getLastExercisePerformance(String exerciseId);
  Future<void> assignRoutineToUser(String userId, String routineId);
  Future<List<SetLogModel>> getSessionSetLogs(String sessionId);
  Future<List<WorkoutSessionModel>> getRecentSessionsForDay(String userId, String routineDayId, DateTime beforeDate, {int limit = 3});
  Future<void> finishWorkoutSession(String sessionId, {List<CoachingAnalysis>? coachingAnalysis});
  Future<List<Map<String, dynamic>>> getExerciseLogsHistory(String userId, String exerciseId);
  Future<List<Map<String, dynamic>>> getRoutineStats(String userId, String routineId);

  // ─── Nuevos métodos de gestión ──────────────────────────────────────────
  Future<void> saveRoutine(RoutineModel routine);
  Future<void> deleteRoutine(String routineId);
  Future<void> saveRoutineDay(RoutineDayModel day);
  Future<void> deleteRoutineDay(String dayId);
  Future<void> toggleExerciseInDay(String dayId, String exerciseId);
  Future<void> reorderExercisesInDay(String dayId, List<String> exerciseIds);
  Future<void> updateExerciseTarget(String routineDayId, String exerciseId, double targetWeight, int targetReps);
}

class WorkoutRemoteDataSourceImpl implements WorkoutRemoteDataSource {
  final SupabaseClient client;
  WorkoutRemoteDataSourceImpl({required this.client});

  @override
  Future<List<RoutineModel>> getAssignedRoutines(String userId) async {
    final response = await client
        .from('user_routines')
        .select('routine_id, routines(id, name)')
        .eq('user_id', userId);

    return response.map((data) {
      final routineData = data['routines'] as Map<String, dynamic>? ?? {};
      return RoutineModel(
        id: (routineData['id'] ?? data['routine_id']).toString(),
        name: (routineData['name'] ?? 'Rutina').toString(),
        exerciseCount: 0,
      );
    }).toList();
  }

  @override
  Future<List<RoutineDayModel>> getRoutineDays(String routineId) async {
    final response = await client
        .from('routine_days')
        .select('id, routine_id, day_of_week, name, routine_exercises(target_sets)')
        .eq('routine_id', routineId)
        .order('day_of_week', ascending: true);

    return response
        .map((json) => RoutineDayModel.fromJson(json))
        .toList();
  }

  @override
  Future<List<ExerciseModel>> getExercisesForDay(String routineDayId) async {
    final response = await client
        .from('routine_exercises')
        .select('''
          id,
          target_reps,
          target_weight,
          target_sets,
          exercises ( id, name )
        ''')
        .eq('routine_day_id', routineDayId)
        .order('order', ascending: true);

    return response.map((json) {
      final exerciseData = json['exercises'] as Map<String, dynamic>;
      return ExerciseModel(
        id: exerciseData['id'] as String,
        routineDayId: routineDayId,
        name: exerciseData['name'] as String,
        targetMuscle: exerciseData['target_muscle'] as String? ?? 'Desconocido',
        targetWeight: (json['target_weight'] as num?)?.toDouble() ?? 0.0,
        targetReps: json['target_reps'] as int? ?? 0,
        targetSets: json['target_sets'] as int? ?? 3,
        restTimerSeconds: json['rest_timer_seconds'] as int? ?? 90,
      );
    }).toList();
  }

  @override
  Future<List<WorkoutSessionModel>> getWeekSessions(
      String userId, DateTime weekStart, DateTime weekEnd) async {
    final start = '${weekStart.year.toString().padLeft(4, '0')}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
    final end = '${weekEnd.year.toString().padLeft(4, '0')}-${weekEnd.month.toString().padLeft(2, '0')}-${weekEnd.day.toString().padLeft(2, '0')}';

    final response = await client
        .from('view_workout_sessions_summary')
        .select()
        .eq('user_id', userId)
        .gte('session_date', start)
        .lte('session_date', end);

    return response
        .map((json) => WorkoutSessionModel.fromJson(json))
        .toList();
  }

  @override
  Future<WorkoutSessionModel> startWorkoutForDay(
      String userId, String routineDayId, DateTime sessionDate) async {
    final dateStr = '${sessionDate.year.toString().padLeft(4, '0')}-${sessionDate.month.toString().padLeft(2, '0')}-${sessionDate.day.toString().padLeft(2, '0')}';

    // Buscar sesión existente
    final existing = await getExistingSession(userId, routineDayId, sessionDate);
    if (existing != null) {
      return existing;
    }

    // Si no existe, crearla
    final response = await client
        .from('workout_sessions')
        .insert({
          'user_id': userId,
          'routine_day_id': routineDayId,
          'session_date': dateStr,
        })
        .select()
        .single();

    return WorkoutSessionModel.fromJson(response);
  }

  @override
  Future<WorkoutSessionModel?> getExistingSession(
      String userId, String routineDayId, DateTime sessionDate) async {
    final dateStr = '${sessionDate.year.toString().padLeft(4, '0')}-${sessionDate.month.toString().padLeft(2, '0')}-${sessionDate.day.toString().padLeft(2, '0')}';

    final response = await client
        .from('view_workout_sessions_summary')
        .select()
        .eq('user_id', userId)
        .eq('routine_day_id', routineDayId)
        .eq('session_date', dateStr)
        .maybeSingle();

    if (response == null) return null;
    return WorkoutSessionModel.fromJson(response);
  }


  @override
  Future<void> saveSetLog(SetLogModel setLog) async {
    final payload = setLog.toJson();
    payload.remove('id');
    
    // Primero intentamos eliminar cualquier registro previo para este setIndex
    // para evitar duplicados sin requerir constraints complejos en la DB.
    await client
        .from('set_logs')
        .delete()
        .match({
          'session_id': setLog.sessionId,
          'exercise_id': setLog.exerciseId,
          'set_index': setLog.setIndex,
        });

    // Ahora insertamos el nuevo registro
    await client.from('set_logs').insert(payload);
  }

  @override
  Future<SetLogModel?> getLastExercisePerformance(String exerciseId) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final rpcResponse = await client.rpc(
        'get_last_exercise_performance',
        params: {'p_user_id': userId, 'p_exercise_id': exerciseId},
      );
      if (rpcResponse != null) {
        if (rpcResponse is List && rpcResponse.isNotEmpty) {
          return SetLogModel.fromJson(rpcResponse.first as Map<String, dynamic>);
        } else if (rpcResponse is Map<String, dynamic>) {
          return SetLogModel.fromJson(rpcResponse);
        }
      }
    } catch (_) {
      // Fallback silently
    }

    // Fallback: consulta directa con filtrado de usuario (más seguro)
    final response = await client
        .from('set_logs')
        .select('*, workout_sessions!inner(user_id)')
        .eq('exercise_id', exerciseId)
        .eq('workout_sessions.user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    
    // El resultado del select con join!inner suele venir con el objeto workout_sessions anidado
    // Pero SetLogModel.fromJson espera los campos del log. 
    // PostgREST aplana si el campo es de la misma tabla o via asterisco.
    return SetLogModel.fromJson(response);
  }

  @override
  Future<void> assignRoutineToUser(String userId, String routineId) async {
    await client.from('user_routines').insert({
      'user_id': userId,
      'routine_id': routineId,
    });
  }

  @override
  Future<List<SetLogModel>> getSessionSetLogs(String sessionId) async {
    final response = await client
        .from('set_logs')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: true);

    return response.map((json) => SetLogModel.fromJson(json)).toList();
  }

  @override
  Future<List<WorkoutSessionModel>> getRecentSessionsForDay(
      String userId, String routineDayId, DateTime beforeDate, {int limit = 3}) async {
    final dateStr = '${beforeDate.year.toString().padLeft(4, '0')}-${beforeDate.month.toString().padLeft(2, '0')}-${beforeDate.day.toString().padLeft(2, '0')}';

    final response = await client
        .from('view_workout_sessions_summary')
        .select()
        .eq('user_id', userId)
        .eq('routine_day_id', routineDayId)
        .lt('session_date', dateStr)
        .not('completed_at', 'is', null)
        .order('session_date', ascending: false)
        .limit(limit);

    return response.map((json) => WorkoutSessionModel.fromJson(json)).toList();
  }

  @override
  Future<void> finishWorkoutSession(String sessionId, {List<CoachingAnalysis>? coachingAnalysis}) async {
    final Map<String, dynamic> updateData = {
      'completed_at': DateTime.now().toIso8601String(),
    };

    if (coachingAnalysis != null) {
      updateData['coaching_analysis'] = coachingAnalysis.map((e) => e.toJson()).toList();
    }

    await client
        .from('workout_sessions')
        .update(updateData)
        .eq('id', sessionId);
  }

  @override
  Future<List<Map<String, dynamic>>> getExerciseLogsHistory(String userId, String exerciseId) async {
    final response = await client
        .from('set_logs')
        .select('*, workout_sessions!inner(session_date)')
        .eq('exercise_id', exerciseId)
        .eq('workout_sessions.user_id', userId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // ─── Nuevos métodos de gestión ──────────────────────────────────────────

  @override
  Future<void> saveRoutine(RoutineModel routine) async {
    if (routine.id.startsWith('new_') || routine.id.isEmpty) {
      // Create
      await client.from('routines').insert({
        'name': routine.name,
      });
    } else {
      // Update
      await client.from('routines').update({
        'name': routine.name,
      }).eq('id', routine.id);
    }
  }

  @override
  Future<void> deleteRoutine(String routineId) async {
    await client.from('routines').delete().eq('id', routineId);
  }

  @override
  Future<void> saveRoutineDay(RoutineDayModel day) async {
    if (day.id.startsWith('new_') || day.id.isEmpty) {
      await client.from('routine_days').insert({
        'routine_id': day.routineId,
        'name': day.name,
        'day_of_week': day.dayOfWeek,
      });
    } else {
      await client.from('routine_days').update({
        'name': day.name,
        'day_of_week': day.dayOfWeek,
      }).eq('id', day.id);
    }
  }

  @override
  Future<void> deleteRoutineDay(String dayId) async {
    await client.from('routine_days').delete().eq('id', dayId);
  }

  @override
  Future<void> toggleExerciseInDay(String dayId, String exerciseId) async {
    // Verificar si ya existe
    final existing = await client
        .from('routine_exercises')
        .select()
        .eq('routine_day_id', dayId)
        .eq('exercise_id', exerciseId)
        .maybeSingle();

    if (existing != null) {
      // Eliminar
      await client
          .from('routine_exercises')
          .delete()
          .eq('routine_day_id', dayId)
          .eq('exercise_id', exerciseId);
    } else {
      // Calcular el orden (max + 1)
      final lastOrder = await client
          .from('routine_exercises')
          .select('order')
          .eq('routine_day_id', dayId)
          .order('order', ascending: false)
          .limit(1)
          .maybeSingle();
      
      final nextOrder = (lastOrder?['order'] as int? ?? -1) + 1;

      // Insertar
      await client.from('routine_exercises').insert({
        'routine_day_id': dayId,
        'exercise_id': exerciseId,
        'order': nextOrder,
      });
    }
  }

  @override
  Future<void> reorderExercisesInDay(String dayId, List<String> exerciseIds) async {
    for (int i = 0; i < exerciseIds.length; i++) {
      await client
          .from('routine_exercises')
          .update({'order': i})
          .eq('routine_day_id', dayId)
          .eq('exercise_id', exerciseIds[i]);
    }
  }

  @override
  Future<void> updateExerciseTarget(String routineDayId, String exerciseId, double targetWeight, int targetReps) async {
    await client
        .from('routine_exercises')
        .update({
          'target_weight': targetWeight,
          'target_reps': targetReps,
        })
        .match({
          'routine_day_id': routineDayId,
          'exercise_id': exerciseId,
        });
  }

  @override
  Future<List<Map<String, dynamic>>> getRoutineStats(String userId, String routineId) async {
    final response = await client
        .from('workout_sessions')
        .select('''
          id,
          session_date,
          routine_day_id,
          routine_days!inner(name, routine_id),
          set_logs(actual_weight, actual_reps)
        ''')
        .eq('user_id', userId)
        .eq('routine_days.routine_id', routineId)
        .order('session_date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }
}
