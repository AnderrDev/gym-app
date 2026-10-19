import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gym_flutter/core/error/exceptions.dart' as app;
import 'package:gym_flutter/features/workout/data/models/exercise_model.dart';

/// Plan remoto de una sesión; nunca escribe en routine_exercises.
class SessionExerciseRemoteDataSource {
  SessionExerciseRemoteDataSource({required this.client});
  final SupabaseClient client;

  List<ExerciseModel> _parse(dynamic data) => (data as List)
      .map(
        (row) => ExerciseModel.fromJson(Map<String, dynamic>.from(row as Map)),
      )
      .toList();

  Future<List<ExerciseModel>> _call(
    String function,
    Map<String, dynamic> params,
  ) async {
    try {
      return _parse(await client.rpc<dynamic>(function, params: params));
    } on PostgrestException catch (error) {
      switch (error.code) {
        case '23505':
          throw app.ConflictException('Ese ejercicio ya está en esta sesión.');
        case '23514':
          throw app.ValidationException(
            'La sesión cambió o los objetivos no son válidos. Vuelve a abrirla y revisa los datos.',
          );
        case '23503':
          throw app.NotFoundException(
            'El ejercicio seleccionado ya no está disponible.',
          );
        case '42501':
          throw app.AuthException(
            'No tienes permiso para modificar esta sesión.',
          );
        default:
          rethrow;
      }
    }
  }

  Future<List<ExerciseModel>> getSessionExercises(String sessionId) =>
      _call('get_session_exercises_v1', {'p_session_id': sessionId});

  Future<List<ExerciseModel>> adaptSessionExercise(
    String sessionId,
    String exerciseId, {
    required int targetSets,
    required int targetReps,
    required double targetWeight,
    String? replaceExerciseId,
  }) => _call('adapt_session_exercise_v1', {
    'p_session_id': sessionId,
    'p_exercise_id': exerciseId,
    'p_target_sets': targetSets,
    'p_target_reps': targetReps,
    'p_target_weight': targetWeight,
    'p_replace_exercise_id': replaceExerciseId,
  });

  Future<List<ExerciseModel>> updateSessionExerciseTarget(
    String sessionId,
    String exerciseId,
    double targetWeight,
    int targetReps,
  ) => _call('update_session_exercise_target_v1', {
    'p_session_id': sessionId,
    'p_exercise_id': exerciseId,
    'p_target_weight': targetWeight,
    'p_target_reps': targetReps,
  });
}
