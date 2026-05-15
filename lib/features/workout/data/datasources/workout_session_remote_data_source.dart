import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gym_flutter/core/error/exceptions.dart';
import 'package:gym_flutter/features/workout/data/datasources/_edge_function_invoker.dart';
import 'package:gym_flutter/features/workout/data/models/set_log_model.dart';
import 'package:gym_flutter/features/workout/data/models/workout_session_model.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';

/// Colaborador interno de `WorkoutRemoteDataSourceImpl`: maneja sesiones,
/// set_logs y las 3 Edge Functions (`finalize_workout_session_v1`,
/// `generate_coaching_v1`, `get_weekly_insights_v1`).
class WorkoutSessionRemoteDataSource {
  WorkoutSessionRemoteDataSource({required this.client})
      : _invoker = EdgeFunctionInvoker(client: client);

  final SupabaseClient client;
  final EdgeFunctionInvoker _invoker;

  static const int _historyLimit = 365;
  static const String _sessionsSummarySelect =
      'id, user_id, routine_day_id, session_date, completed_at, '
      'total_target_sets, total_completed_sets';
  static const String _sessionsBaseSelect =
      'id, user_id, routine_day_id, session_date, completed_at';

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<List<WorkoutSessionModel>> getWeekSessions(
    String userId,
    DateTime weekStart,
    DateTime weekEnd,
  ) async {
    final response = await client
        .from('view_workout_sessions_summary')
        .select(_sessionsSummarySelect)
        .eq('user_id', userId)
        .gte('session_date', _isoDate(weekStart))
        .lte('session_date', _isoDate(weekEnd));

    return response.map((json) => WorkoutSessionModel.fromJson(json)).toList();
  }

  Future<WorkoutSessionModel> startWorkoutForDay(
    String userId,
    String routineDayId,
    DateTime sessionDate,
  ) async {
    // Regla de negocio: solo puede existir una sesión activa por usuario.
    final activeSession = await getActiveSessionForUser(userId);
    if (activeSession != null) return activeSession;

    final existing = await getExistingSession(
      userId,
      routineDayId,
      sessionDate,
    );
    if (existing != null) return existing;

    final response = await client
        .from('workout_sessions')
        .insert({
          'user_id': userId,
          'routine_day_id': routineDayId,
          'session_date': _isoDate(sessionDate),
        })
        .select(_sessionsBaseSelect)
        .single();

    return WorkoutSessionModel.fromJson(response);
  }

  Future<WorkoutSessionModel?> getExistingSession(
    String userId,
    String routineDayId,
    DateTime sessionDate,
  ) async {
    final response = await client
        .from('view_workout_sessions_summary')
        .select(_sessionsSummarySelect)
        .eq('user_id', userId)
        .eq('routine_day_id', routineDayId)
        .eq('session_date', _isoDate(sessionDate))
        .maybeSingle();

    if (response == null) return null;
    return WorkoutSessionModel.fromJson(response);
  }

  Future<void> saveSetLog(SetLogModel setLog) async {
    final payload = setLog.toJson()..remove('id');
    await client
        .from('set_logs')
        .upsert(payload, onConflict: 'session_id,exercise_id,set_index');
  }

  Future<void> deleteSetLog({
    required String sessionId,
    required String exerciseId,
    required int setIndex,
  }) async {
    await client
        .from('set_logs')
        .delete()
        .eq('session_id', sessionId)
        .eq('exercise_id', exerciseId)
        .eq('set_index', setIndex);
  }

  Future<WorkoutSessionModel?> getActiveSessionForUser(String userId) async {
    final response = await client
        .from('workout_sessions')
        .select(_sessionsBaseSelect)
        .eq('user_id', userId)
        .filter('completed_at', 'is', null)
        .order('session_date', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return WorkoutSessionModel.fromJson(response);
  }

  Future<List<SetLogModel>> getSessionSetLogs(String sessionId) async {
    final response = await client
        .from('set_logs')
        .select(
          'id, session_id, exercise_id, set_index, '
          'actual_weight, actual_reps, created_at',
        )
        .eq('session_id', sessionId)
        .order('created_at', ascending: true);

    return response.map((json) => SetLogModel.fromJson(json)).toList();
  }

  Future<Map<String, List<SetLogModel>>> getSetLogsForSessions(
    List<String> sessionIds,
  ) async {
    if (sessionIds.isEmpty) return {};

    final response = await client
        .from('set_logs')
        .select(
          'id, session_id, exercise_id, set_index, '
          'actual_weight, actual_reps, created_at',
        )
        .inFilter('session_id', sessionIds)
        .order('created_at', ascending: true);

    final grouped = <String, List<SetLogModel>>{};
    for (final row in response) {
      final model = SetLogModel.fromJson(row);
      grouped.putIfAbsent(model.sessionId, () => <SetLogModel>[]).add(model);
    }

    return grouped;
  }

  Future<List<WorkoutSessionModel>> getRecentSessionsForDay(
    String userId,
    String routineDayId,
    DateTime beforeDate, {
    int limit = 3,
  }) async {
    final response = await client
        .from('view_workout_sessions_summary')
        .select(_sessionsSummarySelect)
        .eq('user_id', userId)
        .eq('routine_day_id', routineDayId)
        .lt('session_date', _isoDate(beforeDate))
        .not('completed_at', 'is', null)
        .order('session_date', ascending: false)
        .limit(limit);

    return response.map((json) => WorkoutSessionModel.fromJson(json)).toList();
  }

  Future<List<Map<String, dynamic>>> getExerciseLogsHistory(
    String userId,
    String exerciseId,
  ) async {
    final response = await client
        .from('set_logs')
        .select(
          'id, session_id, exercise_id, actual_weight, actual_reps, '
          'set_index, created_at, workout_sessions!inner(session_date)',
        )
        .eq('exercise_id', exerciseId)
        .eq('workout_sessions.user_id', userId)
        .order('created_at', ascending: false)
        .limit(_historyLimit);

    return List<Map<String, dynamic>>.from(response);
  }

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

  Future<void> finishWorkoutSession(
    String sessionId, {
    List<CoachingAnalysis>? coachingAnalysis,
  }) async {
    final payload = <String, dynamic>{'session_id': sessionId};
    if (coachingAnalysis != null) {
      payload['coaching_analysis'] =
          coachingAnalysis.map((e) => e.toJson()).toList();
    }

    await _invoker.invoke(
      functionName: 'finalize_workout_session_v1',
      body: payload,
      errorCodePrefix: 'FINALIZE',
      genericErrorMessage:
          'No se pudo finalizar la sesión en este momento. Intenta nuevamente.',
      statusMappings: const {
        404: WorkoutFunctionException(
          code: 'NOT_FOUND_OR_ALREADY_COMPLETED',
          userMessage: 'Esta sesión ya fue finalizada o no existe.',
        ),
        400: WorkoutFunctionException(
          code: 'VALIDATION_ERROR',
          userMessage: 'No se pudo finalizar la sesión por datos inválidos.',
        ),
      },
      codeMappings: const {
        'NOT_FOUND_OR_ALREADY_COMPLETED': WorkoutFunctionException(
          code: 'NOT_FOUND_OR_ALREADY_COMPLETED',
          userMessage: 'Esta sesión ya fue finalizada o no existe.',
        ),
        'VALIDATION_ERROR': WorkoutFunctionException(
          code: 'VALIDATION_ERROR',
          userMessage: 'No se pudo finalizar la sesión por datos inválidos.',
        ),
      },
    );
  }

  Future<WeeklyInsights> getWeeklyInsights({
    required String routineId,
    required DateTime weekStart,
  }) async {
    final data = await _invoker.invoke(
      functionName: 'get_weekly_insights_v1',
      body: {'routine_id': routineId, 'week_start': _isoDate(weekStart)},
      errorCodePrefix: 'INSIGHTS',
      genericErrorMessage: 'No se pudieron cargar los insights semanales.',
    );

    final body = data['data'];
    if (body is! Map<String, dynamic>) {
      throw const WorkoutFunctionException(
        code: 'INVALID_INSIGHTS_PAYLOAD',
        userMessage: 'La respuesta de insights no es válida.',
      );
    }

    return WeeklyInsights.fromJson(body);
  }
}
