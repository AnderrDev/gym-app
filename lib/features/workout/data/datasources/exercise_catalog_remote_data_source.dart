import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gym_flutter/core/observability/app_logger.dart';
import 'package:gym_flutter/features/workout/data/models/set_log_model.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_catalog_item.dart';

/// Colaborador interno: catálogo de ejercicios + RPC
/// `get_last_exercise_performances` (con fallback PostgREST).
class ExerciseCatalogRemoteDataSource {
  ExerciseCatalogRemoteDataSource({required this.client});

  final SupabaseClient client;

  static const int _kMaxExerciseIdsPerRpc = 100;

  Future<SetLogModel?> getLastExercisePerformance(String exerciseId) async {
    final results = await getLastExercisePerformances([exerciseId]);
    return results[exerciseId];
  }

  Future<Map<String, SetLogModel?>> getLastExercisePerformances(
    List<String> exerciseIds,
  ) async {
    final userId = client.auth.currentUser?.id;
    final Map<String, SetLogModel?> result = {
      for (final id in exerciseIds) id: null,
    };

    if (userId == null || exerciseIds.isEmpty) return result;

    if (exerciseIds.length > _kMaxExerciseIdsPerRpc) {
      AppLogger.instance.warning(
        'getLastExercisePerformances: ${exerciseIds.length} ejercicios '
        'excede el máximo de $_kMaxExerciseIdsPerRpc; se trunca para evitar '
        'queries gigantes.',
      );
    }
    final cappedIds = exerciseIds.length > _kMaxExerciseIdsPerRpc
        ? exerciseIds.sublist(0, _kMaxExerciseIdsPerRpc)
        : exerciseIds;

    try {
      final rpcResponse = await client.rpc<dynamic>(
        'get_last_exercise_performances',
        params: {'p_user_id': userId, 'p_exercise_ids': cappedIds},
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
      // Fallback acotado: la RPC es la fuente preferida; si falla, traemos
      // suficientes filas para resolver los N ejercicios sin escanear todo
      // el historial del usuario.
    }

    final response = await client
        .from('set_logs')
        .select(
          'id, session_id, exercise_id, set_index, actual_weight, actual_reps, created_at, workout_sessions!inner(user_id)',
        )
        .inFilter('exercise_id', cappedIds)
        .eq('workout_sessions.user_id', userId)
        .order('created_at', ascending: false)
        .limit(cappedIds.length * 5);

    for (final row in response) {
      final json = row;
      final exerciseId = json['exercise_id']?.toString();
      if (exerciseId == null || !result.containsKey(exerciseId)) continue;
      result[exerciseId] ??= SetLogModel.fromJson(json);
    }

    return result;
  }

  Future<List<ExerciseCatalogItem>> getExercisesCatalog({
    String? muscleGroup,
    String? search,
    int limit = 200,
  }) async {
    var query = client
        .from('exercises')
        .select('id, name, description, muscle_group');

    if (muscleGroup != null && muscleGroup.isNotEmpty) {
      query = query.eq('muscle_group', muscleGroup);
    }
    if (search != null && search.isNotEmpty) {
      query = query.ilike('name', '%$search%');
    }

    final response = await query.order('name', ascending: true).limit(limit);

    return (response as List<dynamic>)
        .map((row) {
          final json = row as Map<String, dynamic>;
          final id = json['id'] as String?;
          final name = json['name'] as String?;
          if (id == null || name == null) return null;
          return ExerciseCatalogItem(
            id: id,
            name: name,
            muscleGroup: (json['muscle_group'] as String?) ?? '',
            description: json['description'] as String?,
          );
        })
        .whereType<ExerciseCatalogItem>()
        .toList();
  }
}
