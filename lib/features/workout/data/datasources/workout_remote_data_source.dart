import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/routine_day_model.dart';
import '../models/exercise_model.dart';
import '../models/set_log_model.dart';
import '../models/workout_session_model.dart';
import '../models/routine_model.dart';
import '../../domain/entities/coaching_analysis.dart';
import '../../domain/entities/weekly_insights.dart';

abstract class WorkoutRemoteDataSource {
  Future<List<RoutineModel>> getAssignedRoutines(String userId);
  Future<List<RoutineDayModel>> getRoutineDays(String routineId);
  Future<List<ExerciseModel>> getExercisesForDay(String routineDayId);
  Future<List<WorkoutSessionModel>> getWeekSessions(
    String userId,
    DateTime weekStart,
    DateTime weekEnd,
  );
  Future<WorkoutSessionModel> startWorkoutForDay(
    String userId,
    String routineDayId,
    DateTime sessionDate,
  );
  Future<WorkoutSessionModel?> getExistingSession(
    String userId,
    String routineDayId,
    DateTime sessionDate,
  );
  Future<void> saveSetLog(SetLogModel setLog);
  Future<SetLogModel?> getLastExercisePerformance(String exerciseId);
  Future<Map<String, SetLogModel?>> getLastExercisePerformances(
    List<String> exerciseIds,
  );
  Future<void> assignRoutineToUser(String userId, String routineId);
  Future<List<SetLogModel>> getSessionSetLogs(String sessionId);
  Future<Map<String, List<SetLogModel>>> getSetLogsForSessions(
    List<String> sessionIds,
  );
  Future<List<WorkoutSessionModel>> getRecentSessionsForDay(
    String userId,
    String routineDayId,
    DateTime beforeDate, {
    int limit = 3,
  });
  Future<void> finishWorkoutSession(
    String sessionId, {
    List<CoachingAnalysis>? coachingAnalysis,
  });
  Future<WeeklyInsights> getWeeklyInsights({
    required String routineId,
    required DateTime weekStart,
  });
  Future<List<Map<String, dynamic>>> getExerciseLogsHistory(
    String userId,
    String exerciseId,
  );
  Future<List<Map<String, dynamic>>> getRoutineStats(
    String userId,
    String routineId,
  );

  /// Busca cualquier sesión sin completar para el usuario (para reanudación al abrir app)
  Future<WorkoutSessionModel?> getActiveSessionForUser(String userId);
  Future<String?> getRoutineDayNameById(String routineDayId);

  // ─── Nuevos métodos de gestión ──────────────────────────────────────────
  Future<void> saveRoutine(RoutineModel routine);
  Future<void> deleteRoutine(String routineId);
  Future<void> saveRoutineDay(RoutineDayModel day);
  Future<void> deleteRoutineDay(String dayId);
  Future<void> toggleExerciseInDay(String dayId, String exerciseId);
  Future<void> reorderExercisesInDay(String dayId, List<String> exerciseIds);
  Future<void> updateExerciseTarget(
    String routineDayId,
    String exerciseId,
    double targetWeight,
    int targetReps,
  );
  Future<List<RoutineModel>> getAllRoutines();
  Future<RoutineModel> getRoutineById(String routineId);
}

class WorkoutRemoteDataSourceImpl implements WorkoutRemoteDataSource {
  final SupabaseClient client;
  WorkoutRemoteDataSourceImpl({required this.client});

  @override
  Future<List<RoutineModel>> getAssignedRoutines(String userId) async {
    final response = await client
        .from('user_routines')
        .select('routine_id, routines(id, name, is_public, creator_id)')
        .eq('user_id', userId);

    return response.map((data) {
      final routineData = data['routines'] as Map<String, dynamic>? ?? {};
      return RoutineModel(
        id: (routineData['id'] ?? data['routine_id']).toString(),
        name: (routineData['name'] ?? 'Rutina').toString(),
        exerciseCount: 0,
        isPublic: routineData['is_public'] as bool? ?? false,
        creatorId: routineData['creator_id'] as String?,
      );
    }).toList();
  }

  @override
  Future<List<RoutineDayModel>> getRoutineDays(String routineId) async {
    final response = await client
        .from('routine_days')
        .select(
          'id, routine_id, day_of_week, name, routine_exercises(target_sets)',
        )
        .eq('routine_id', routineId)
        .order('day_of_week', ascending: true);

    return response.map((json) => RoutineDayModel.fromJson(json)).toList();
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
          rest_timer_seconds,
          exercises ( id, name, muscle_group )
        ''')
        .eq('routine_day_id', routineDayId)
        .order('order', ascending: true);

    return response.map((json) {
      final exerciseData = json['exercises'] as Map<String, dynamic>;
      return ExerciseModel(
        id: exerciseData['id'] as String,
        routineDayId: routineDayId,
        name: exerciseData['name'] as String,
        targetMuscle: exerciseData['muscle_group'] as String? ?? 'Desconocido',
        targetWeight: (json['target_weight'] as num?)?.toDouble() ?? 0.0,
        targetReps: json['target_reps'] as int? ?? 0,
        targetSets: json['target_sets'] as int? ?? 3,
        restTimerSeconds: json['rest_timer_seconds'] as int? ?? 90,
      );
    }).toList();
  }

  @override
  Future<List<WorkoutSessionModel>> getWeekSessions(
    String userId,
    DateTime weekStart,
    DateTime weekEnd,
  ) async {
    final start =
        '${weekStart.year.toString().padLeft(4, '0')}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
    final end =
        '${weekEnd.year.toString().padLeft(4, '0')}-${weekEnd.month.toString().padLeft(2, '0')}-${weekEnd.day.toString().padLeft(2, '0')}';

    final response = await client
        .from('view_workout_sessions_summary')
        .select(
          'id, user_id, routine_day_id, session_date, completed_at, total_target_sets, total_completed_sets',
        )
        .eq('user_id', userId)
        .gte('session_date', start)
        .lte('session_date', end);

    return response.map((json) => WorkoutSessionModel.fromJson(json)).toList();
  }

  @override
  Future<WorkoutSessionModel> startWorkoutForDay(
    String userId,
    String routineDayId,
    DateTime sessionDate,
  ) async {
    final dateStr =
        '${sessionDate.year.toString().padLeft(4, '0')}-${sessionDate.month.toString().padLeft(2, '0')}-${sessionDate.day.toString().padLeft(2, '0')}';

    // Regla de negocio: solo puede existir una sesión activa por usuario.
    final activeSession = await getActiveSessionForUser(userId);
    if (activeSession != null) {
      return activeSession;
    }

    // Buscar sesión existente
    final existing = await getExistingSession(
      userId,
      routineDayId,
      sessionDate,
    );
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
        .select('id, user_id, routine_day_id, session_date, completed_at')
        .single();

    return WorkoutSessionModel.fromJson(response);
  }

  @override
  Future<WorkoutSessionModel?> getExistingSession(
    String userId,
    String routineDayId,
    DateTime sessionDate,
  ) async {
    final dateStr =
        '${sessionDate.year.toString().padLeft(4, '0')}-${sessionDate.month.toString().padLeft(2, '0')}-${sessionDate.day.toString().padLeft(2, '0')}';

    final response = await client
        .from('view_workout_sessions_summary')
        .select(
          'id, user_id, routine_day_id, session_date, completed_at, total_target_sets, total_completed_sets',
        )
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

    await client
        .from('set_logs')
        .upsert(payload, onConflict: 'session_id,exercise_id,set_index');
  }

  @override
  Future<SetLogModel?> getLastExercisePerformance(String exerciseId) async {
    final results = await getLastExercisePerformances([exerciseId]);
    return results[exerciseId];
  }

  @override
  Future<Map<String, SetLogModel?>> getLastExercisePerformances(
    List<String> exerciseIds,
  ) async {
    final userId = client.auth.currentUser?.id;
    final Map<String, SetLogModel?> result = {
      for (final id in exerciseIds) id: null,
    };

    if (userId == null || exerciseIds.isEmpty) return result;

    try {
      final rpcResponse = await client.rpc(
        'get_last_exercise_performances',
        params: {'p_user_id': userId, 'p_exercise_ids': exerciseIds},
      );

      if (rpcResponse is List) {
        for (final row in rpcResponse) {
          final json = row as Map<String, dynamic>;
          final exerciseId = json['exercise_id']?.toString();
          if (exerciseId == null || !result.containsKey(exerciseId)) continue;
          result[exerciseId] ??= SetLogModel.fromJson(json);
        }
        return result;
      }
    } catch (_) {
      // Fallback to direct query
    }

    final response = await client
        .from('set_logs')
        .select(
          'id, session_id, exercise_id, set_index, actual_weight, actual_reps, created_at, workout_sessions!inner(user_id)',
        )
        .inFilter('exercise_id', exerciseIds)
        .eq('workout_sessions.user_id', userId)
        .order('created_at', ascending: false);

    for (final row in response) {
      final json = row as Map<String, dynamic>;
      final exerciseId = json['exercise_id']?.toString();
      if (exerciseId == null || !result.containsKey(exerciseId)) continue;
      result[exerciseId] ??= SetLogModel.fromJson(json);
    }

    return result;
  }

  @override
  Future<WorkoutSessionModel?> getActiveSessionForUser(String userId) async {
    final response = await client
        .from('workout_sessions')
        .select('id, user_id, routine_day_id, session_date, completed_at')
        .eq('user_id', userId)
        .filter('completed_at', 'is', null)
        .order('session_date', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return WorkoutSessionModel.fromJson(response);
  }

  @override
  Future<String?> getRoutineDayNameById(String routineDayId) async {
    final response = await client
        .from('routine_days')
        .select('name')
        .eq('id', routineDayId)
        .maybeSingle();

    if (response == null) return null;
    return response['name']?.toString();
  }

  @override
  Future<void> assignRoutineToUser(String userId, String routineId) async {
    // Database unique constraint will handle duplicates if we just try to insert,
    // but better use upsert or explicit logic for the single routine rule.
    await client.from('user_routines').upsert({
      'user_id': userId,
      'routine_id': routineId,
    }, onConflict: 'user_id');
  }

  @override
  Future<List<SetLogModel>> getSessionSetLogs(String sessionId) async {
    final response = await client
        .from('set_logs')
        .select(
          'id, session_id, exercise_id, set_index, actual_weight, actual_reps, created_at',
        )
        .eq('session_id', sessionId)
        .order('created_at', ascending: true);

    return response.map((json) => SetLogModel.fromJson(json)).toList();
  }

  @override
  Future<Map<String, List<SetLogModel>>> getSetLogsForSessions(
    List<String> sessionIds,
  ) async {
    if (sessionIds.isEmpty) return {};

    final response = await client
        .from('set_logs')
        .select(
          'id, session_id, exercise_id, set_index, actual_weight, actual_reps, created_at',
        )
        .inFilter('session_id', sessionIds)
        .order('created_at', ascending: true);

    final grouped = <String, List<SetLogModel>>{};
    for (final row in response) {
      final model = SetLogModel.fromJson(row as Map<String, dynamic>);
      grouped.putIfAbsent(model.sessionId, () => <SetLogModel>[]).add(model);
    }

    return grouped;
  }

  @override
  Future<List<WorkoutSessionModel>> getRecentSessionsForDay(
    String userId,
    String routineDayId,
    DateTime beforeDate, {
    int limit = 3,
  }) async {
    final dateStr =
        '${beforeDate.year.toString().padLeft(4, '0')}-${beforeDate.month.toString().padLeft(2, '0')}-${beforeDate.day.toString().padLeft(2, '0')}';

    final response = await client
        .from('view_workout_sessions_summary')
        .select(
          'id, user_id, routine_day_id, session_date, completed_at, total_target_sets, total_completed_sets',
        )
        .eq('user_id', userId)
        .eq('routine_day_id', routineDayId)
        .lt('session_date', dateStr)
        .not('completed_at', 'is', null)
        .order('session_date', ascending: false)
        .limit(limit);

    return response.map((json) => WorkoutSessionModel.fromJson(json)).toList();
  }

  @override
  Future<void> finishWorkoutSession(
    String sessionId, {
    List<CoachingAnalysis>? coachingAnalysis,
  }) async {
    final Map<String, dynamic> payload = {'session_id': sessionId};

    if (coachingAnalysis != null) {
      payload['coaching_analysis'] = coachingAnalysis
          .map((e) => e.toJson())
          .toList();
    }

    try {
      final token = await _getValidAccessToken();

      if (token == null) {
        throw const WorkoutFunctionException(
          code: 'UNAUTHORIZED',
          userMessage: 'Tu sesión expiró. Inicia sesión nuevamente.',
        );
      }

      final response = await client.functions
          .invoke(
            'finalize_workout_session_v1',
            body: payload,
            headers: {'X-User-Token': token},
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw const WorkoutFunctionException(
              code: 'TIMEOUT',
              userMessage: 'La solicitud tardó demasiado. Intenta nuevamente.',
            ),
          );

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final statusCode = response.status;
      final code = data['code']?.toString();
      final success = data['success'] == true;

      if (statusCode == 404 || code == 'NOT_FOUND_OR_ALREADY_COMPLETED') {
        throw const WorkoutFunctionException(
          code: 'NOT_FOUND_OR_ALREADY_COMPLETED',
          userMessage: 'Esta sesión ya fue finalizada o no existe.',
        );
      }

      if (statusCode == 400 || code == 'VALIDATION_ERROR') {
        throw const WorkoutFunctionException(
          code: 'VALIDATION_ERROR',
          userMessage: 'No se pudo finalizar la sesión por datos inválidos.',
        );
      }

      if (statusCode == 401 || code == 'UNAUTHORIZED') {
        throw const WorkoutFunctionException(
          code: 'UNAUTHORIZED',
          userMessage: 'Tu sesión expiró. Inicia sesión nuevamente.',
        );
      }

      if (!success || statusCode < 200 || statusCode >= 300) {
        throw WorkoutFunctionException(
          code: code ?? 'UNKNOWN_FUNCTION_ERROR',
          userMessage:
              'No se pudo finalizar la sesión en este momento. Intenta nuevamente.',
        );
      }
      return;
    } on FunctionException catch (e) {
      final status = e.status;
      final errorMessage = e.details?.toString() ?? e.toString();

      if (status == 401) {
        throw const WorkoutFunctionException(
          code: 'UNAUTHORIZED',
          userMessage: 'Tu sesión expiró (401). Inicia sesión nuevamente.',
        );
      }

      throw WorkoutFunctionException(
        code: 'FUNCTION_ERROR_$status',
        userMessage: 'Error del servidor ($status): $errorMessage',
      );
    } catch (e) {
      if (e is WorkoutFunctionException) {
        rethrow;
      }
      throw WorkoutFunctionException(
        code: 'EDGE_RUNTIME_ERROR',
        userMessage: 'No se pudo conectar con el servidor: ${e.toString()}',
      );
    }
  }

  @override
  Future<WeeklyInsights> getWeeklyInsights({
    required String routineId,
    required DateTime weekStart,
  }) async {
    try {
      final weekStartIso =
          '${weekStart.year.toString().padLeft(4, '0')}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';

      final token = await _getValidAccessToken();
      if (token == null) {
        throw const WorkoutFunctionException(
          code: 'UNAUTHORIZED',
          userMessage: 'Tu sesión expiró. Inicia sesión nuevamente.',
        );
      }

      final payload = {'routine_id': routineId, 'week_start': weekStartIso};

      final response = await client.functions
          .invoke(
            'get_weekly_insights_v1',
            body: payload,
            headers: {'X-User-Token': token},
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw const WorkoutFunctionException(
              code: 'TIMEOUT',
              userMessage: 'La solicitud tardó demasiado. Intenta nuevamente.',
            ),
          );

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final statusCode = response.status;
      final success = data['success'] == true;

      if (!success || statusCode < 200 || statusCode >= 300) {
        final code = data['code']?.toString() ?? 'WEEKLY_INSIGHTS_ERROR';
        throw WorkoutFunctionException(
          code: code,
          userMessage: 'No se pudieron cargar los insights semanales.',
        );
      }

      final body = data['data'];
      if (body is! Map<String, dynamic>) {
        throw const WorkoutFunctionException(
          code: 'INVALID_INSIGHTS_PAYLOAD',
          userMessage: 'La respuesta de insights no es válida.',
        );
      }

      return WeeklyInsights.fromJson(body);
    } on FunctionException catch (e) {
      final status = e.status;
      final errorMessage = e.details?.toString() ?? e.toString();

      if (status == 401) {
        throw const WorkoutFunctionException(
          code: 'UNAUTHORIZED',
          userMessage: 'Tu sesión expiró (401). Inicia sesión nuevamente.',
        );
      }

      throw WorkoutFunctionException(
        code: 'INSIGHTS_FUNCTION_ERROR_$status',
        userMessage: 'Error de insights ($status): $errorMessage',
      );
    } catch (e) {
      if (e is WorkoutFunctionException) {
        rethrow;
      }
      throw WorkoutFunctionException(
        code: 'INSIGHTS_ERROR',
        userMessage: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  Future<String?> _getValidAccessToken() async {
    final current = client.auth.currentSession?.accessToken;
    if (current != null && current.isNotEmpty) return current;

    final refreshed = (await client.auth.refreshSession()).session?.accessToken;
    if (refreshed != null && refreshed.isNotEmpty) return refreshed;
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> getExerciseLogsHistory(
    String userId,
    String exerciseId,
  ) async {
    final response = await client
        .from('set_logs')
        .select(
          'id, exercise_id, actual_weight, actual_reps, set_index, created_at, workout_sessions!inner(session_date)',
        )
        .eq('exercise_id', exerciseId)
        .eq('workout_sessions.user_id', userId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> saveRoutine(RoutineModel routine) async {
    if (routine.id.startsWith('new_') || routine.id.isEmpty) {
      await client.from('routines').insert({
        'name': routine.name,
        'is_public': routine.isPublic,
        'creator_id': client.auth.currentUser?.id,
      });
    } else {
      await client
          .from('routines')
          .update({'name': routine.name, 'is_public': routine.isPublic})
          .eq('id', routine.id);
    }
  }

  @override
  Future<RoutineModel> getRoutineById(String routineId) async {
    final response = await client
        .from('routines_view')
        .select('id, name, exercise_count, is_public, creator_id, creator_name')
        .eq('id', routineId)
        .single();

    return RoutineModel.fromJson(response);
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
      await client
          .from('routine_days')
          .update({'name': day.name, 'day_of_week': day.dayOfWeek})
          .eq('id', day.id);
    }
  }

  @override
  Future<void> deleteRoutineDay(String dayId) async {
    await client.from('routine_days').delete().eq('id', dayId);
  }

  @override
  Future<void> toggleExerciseInDay(String dayId, String exerciseId) async {
    final existing = await client
        .from('routine_exercises')
        .select('id')
        .eq('routine_day_id', dayId)
        .eq('exercise_id', exerciseId)
        .maybeSingle();

    if (existing != null) {
      await client
          .from('routine_exercises')
          .delete()
          .eq('routine_day_id', dayId)
          .eq('exercise_id', exerciseId);
    } else {
      final lastOrder = await client
          .from('routine_exercises')
          .select('order')
          .eq('routine_day_id', dayId)
          .order('order', ascending: false)
          .limit(1)
          .maybeSingle();

      final nextOrder = (lastOrder?['order'] as int? ?? -1) + 1;

      await client.from('routine_exercises').insert({
        'routine_day_id': dayId,
        'exercise_id': exerciseId,
        'order': nextOrder,
      });
    }
  }

  @override
  Future<void> reorderExercisesInDay(
    String dayId,
    List<String> exerciseIds,
  ) async {
    for (int i = 0; i < exerciseIds.length; i++) {
      await client
          .from('routine_exercises')
          .update({'order': i})
          .eq('routine_day_id', dayId)
          .eq('exercise_id', exerciseIds[i]);
    }
  }

  @override
  Future<void> updateExerciseTarget(
    String routineDayId,
    String exerciseId,
    double targetWeight,
    int targetReps,
  ) async {
    await client
        .from('routine_exercises')
        .update({'target_weight': targetWeight, 'target_reps': targetReps})
        .match({'routine_day_id': routineDayId, 'exercise_id': exerciseId});
  }

  @override
  Future<List<Map<String, dynamic>>> getRoutineStats(
    String userId,
    String routineId,
  ) async {
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

  @override
  Future<List<RoutineModel>> getAllRoutines() async {
    final userId = client.auth.currentUser?.id;

    final response = await client
        .from('routines_view')
        .select('id, name, exercise_count, is_public, creator_id, creator_name')
        .or(
          'is_public.eq.true${userId != null ? ",creator_id.eq.$userId" : ""}',
        )
        .order('name', ascending: true);

    return response.map((json) => RoutineModel.fromJson(json)).toList();
  }
}

class WorkoutFunctionException implements Exception {
  final String code;
  final String userMessage;
  const WorkoutFunctionException({
    required this.code,
    required this.userMessage,
  });

  @override
  String toString() => userMessage;
}
