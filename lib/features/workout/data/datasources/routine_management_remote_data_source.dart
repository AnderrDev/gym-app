import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:gym_flutter/core/observability/app_logger.dart';
import 'package:gym_flutter/features/workout/data/datasources/add_exercise_to_day_item.dart';
import 'package:gym_flutter/features/workout/data/models/exercise_model.dart';
import 'package:gym_flutter/features/workout/data/models/routine_day_model.dart';
import 'package:gym_flutter/features/workout/data/models/routine_model.dart';

export 'package:gym_flutter/features/workout/data/datasources/add_exercise_to_day_item.dart'
    show AddExerciseToDayItem;

/// Colaborador interno: CRUD de rutinas / días / ejercicios y consultas
/// relacionadas (rutinas asignadas, días, ejercicios por día).
class RoutineManagementRemoteDataSource {
  RoutineManagementRemoteDataSource({required this.client});

  final SupabaseClient client;

  static const int _kDefaultRoutineListLimit = 100;
  static const String _routineSelect = 'id, name, is_public, creator_id';
  static const String _routineViewSelect =
      'id, name, exercise_count, is_public, creator_id, creator_name';
  static const String _routineDaySelect = 'id, routine_id, day_of_week, name';

  bool _isNewId(String id) => id.startsWith('new_') || id.isEmpty;

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

  Future<List<RoutineDayModel>> getRoutineDays(String routineId) async {
    // Traemos las columnas completas del join para que `RoutineDayModel.fromJson`
    // pueda hidratar tanto `exerciseNamesPreview` (card del dashboard) como
    // `exercises` (day editor). Sin la versión completa, el editor ve siempre
    // `exercises = []` aunque el día tenga filas en `routine_exercises`.
    final response = await client
        .from('routine_days')
        .select(
          'id, routine_id, day_of_week, name, '
          'routine_exercises('
          'target_sets, target_reps, target_weight, rest_timer_seconds, "order", '
          'exercises(id, name, muscle_group)'
          ')',
        )
        .eq('routine_id', routineId)
        .order('day_of_week', ascending: true);

    return response.map((json) {
      // El select de PostgREST no garantiza el orden del array embebido —
      // lo ordenamos por `"order"` antes de pasarlo a `fromJson`.
      final embedded = json['routine_exercises'] as List<dynamic>?;
      if (embedded != null) {
        embedded.sort((a, b) {
          final ao = (a as Map<String, dynamic>)['order'] as int? ?? 0;
          final bo = (b as Map<String, dynamic>)['order'] as int? ?? 0;
          return ao.compareTo(bo);
        });
      }
      return RoutineDayModel.fromJson(json);
    }).toList();
  }

  Future<List<ExerciseModel>> getExercisesForDay(String routineDayId) async {
    final response = await client
        .from('routine_exercises')
        .select(
          'id, target_reps, target_weight, target_sets, rest_timer_seconds, '
          'exercises ( id, name, muscle_group )',
        )
        .eq('routine_day_id', routineDayId)
        .order('order', ascending: true);

    return response
        .map((json) {
          // El join `exercises(...)` no usa `!inner`: si el ejercicio fue
          // borrado o cae por RLS, el campo viene null. Filtramos esa fila.
          final exerciseData = json['exercises'] as Map<String, dynamic>?;
          final id = exerciseData?['id'] as String?;
          final name = exerciseData?['name'] as String?;
          if (id == null || name == null) return null;
          final muscle = exerciseData?['muscle_group'] as String?;
          if (muscle == null || muscle.isEmpty) {
            AppLogger.instance.warning(
              'getExercisesForDay: muscle_group vacío para exercise id=$id',
            );
          }
          return ExerciseModel(
            id: id,
            routineDayId: routineDayId,
            name: name,
            targetMuscle: muscle ?? '',
            targetWeight: (json['target_weight'] as num?)?.toDouble() ?? 0.0,
            targetReps: (json['target_reps'] as num?)?.toInt() ?? 0,
            targetSets: (json['target_sets'] as num?)?.toInt() ?? 3,
            restTimerSeconds:
                (json['rest_timer_seconds'] as num?)?.toInt() ?? 90,
          );
        })
        .whereType<ExerciseModel>()
        .toList();
  }

  Future<String?> getRoutineDayNameById(String routineDayId) async {
    final response = await client
        .from('routine_days')
        .select('name')
        .eq('id', routineDayId)
        .maybeSingle();
    return response?['name']?.toString();
  }

  Future<void> assignRoutineToUser(String userId, String routineId) =>
      client.from('user_routines').upsert(
        {'user_id': userId, 'routine_id': routineId},
        onConflict: 'user_id',
      );

  Future<RoutineModel> saveRoutine(RoutineModel routine) async {
    final payload = {
      'name': routine.name,
      'is_public': routine.isPublic,
    };
    final isNew = _isNewId(routine.id);
    final query = isNew
        ? client.from('routines').insert({
            ...payload,
            'creator_id': client.auth.currentUser?.id,
          })
        : client.from('routines').update(payload).eq('id', routine.id);

    final result = await query.select(_routineSelect).single();
    return RoutineModel(
      id: result['id'] as String,
      name: (result['name'] as String?) ?? routine.name,
      exerciseCount: isNew ? 0 : routine.exerciseCount,
      isPublic: (result['is_public'] as bool?) ?? routine.isPublic,
      creatorId: result['creator_id'] as String?,
    );
  }

  Future<RoutineModel> getRoutineById(String routineId) async {
    final response = await client
        .from('routines_view')
        .select(_routineViewSelect)
        .eq('id', routineId)
        .single();
    return RoutineModel.fromJson(response);
  }

  Future<void> deleteRoutine(String routineId) async {
    await client.from('routines').delete().eq('id', routineId);
  }

  /// Crea una copia privada de una rutina visible para el caller (propia o
  /// pública) vía RPC `fork_routine_v1`. Devuelve el id de la nueva rutina.
  ///
  /// El RPC es `SECURITY DEFINER` y rechaza copias sobre rutinas a las que
  /// el usuario no tenga visibilidad — la BD es la última línea de defensa,
  /// la UI ya debería gatear la acción.
  Future<String> forkRoutine(String sourceRoutineId, {String? newName}) async {
    final dynamic res = await client.rpc<dynamic>(
      'fork_routine_v1',
      params: {
        'p_source_routine_id': sourceRoutineId,
        if (newName != null && newName.trim().isNotEmpty)
          'p_new_name': newName.trim(),
      },
    );
    if (res is String) return res;
    throw StateError('fork_routine_v1: unexpected response shape: $res');
  }

  Future<RoutineDayModel> saveRoutineDay(RoutineDayModel day) async {
    final payload = {'name': day.name, 'day_of_week': day.dayOfWeek};
    final isNew = _isNewId(day.id);
    final query = isNew
        ? client.from('routine_days').insert({
            ...payload,
            'routine_id': day.routineId,
          })
        : client.from('routine_days').update(payload).eq('id', day.id);

    final result = await query.select(_routineDaySelect).single();
    return RoutineDayModel(
      id: result['id'] as String,
      routineId: (result['routine_id'] as String?) ?? day.routineId,
      dayOfWeek: (result['day_of_week'] as int?) ?? day.dayOfWeek,
      name: (result['name'] as String?) ?? day.name,
      exercises: isNew ? const [] : day.exercises,
      targetSetsCount: isNew ? 0 : day.targetSetsCount,
      status: day.status,
    );
  }

  Future<void> deleteRoutineDay(String dayId) async {
    await client.from('routine_days').delete().eq('id', dayId);
  }

  Future<int> _nextOrder(String dayId) async {
    final last = await client
        .from('routine_exercises')
        .select('order')
        .eq('routine_day_id', dayId)
        .order('order', ascending: false)
        .limit(1)
        .maybeSingle();
    return (last?['order'] as int? ?? -1) + 1;
  }

  Future<void> addExerciseToDay(
    String dayId,
    String exerciseId, {
    required int targetSets,
    required int targetReps,
    required double targetWeight,
    int restSeconds = 90,
  }) async {
    // upsert con ignoreDuplicates evita romper si el ejercicio ya está en el
    // día (race entre catálogo y reload, doble-tap, etc.). El constraint
    // `routine_exercises_day_exercise_uniq` sigue siendo la red de seguridad.
    await client.from('routine_exercises').upsert(
      {
        'routine_day_id': dayId,
        'exercise_id': exerciseId,
        'order': await _nextOrder(dayId),
        'target_sets': targetSets,
        'target_reps': targetReps,
        'target_weight': targetWeight,
        'rest_timer_seconds': restSeconds,
      },
      onConflict: 'routine_day_id,exercise_id',
      ignoreDuplicates: true,
    );
  }

  Future<void> addExercisesToDay(
    String dayId,
    List<AddExerciseToDayItem> items,
  ) async {
    if (items.isEmpty) return;
    var nextOrder = await _nextOrder(dayId);
    final payload = items.map((item) {
      final row = {
        'routine_day_id': dayId,
        'exercise_id': item.exerciseId,
        'order': nextOrder,
        'target_sets': item.targetSets,
        'target_reps': item.targetReps,
        'target_weight': item.targetWeight,
        'rest_timer_seconds': item.restSeconds,
      };
      nextOrder++;
      return row;
    }).toList();
    await client.from('routine_exercises').upsert(
      payload,
      onConflict: 'routine_day_id,exercise_id',
      ignoreDuplicates: true,
    );
  }

  Future<void> removeExerciseFromDay(String dayId, String exerciseId) async {
    await client
        .from('routine_exercises')
        .delete()
        .eq('routine_day_id', dayId)
        .eq('exercise_id', exerciseId);
  }

  /// UPDATEs en paralelo: para una rutina de 8 ejercicios evita N round-trips
  /// secuenciales (~8x latencia).
  Future<void> reorderExercisesInDay(
    String dayId,
    List<String> exerciseIds,
  ) async {
    await Future.wait([
      for (var i = 0; i < exerciseIds.length; i++)
        client
            .from('routine_exercises')
            .update({'order': i})
            .eq('routine_day_id', dayId)
            .eq('exercise_id', exerciseIds[i]),
    ]);
  }

  Future<void> updateExerciseTarget(
    String routineDayId,
    String exerciseId,
    double targetWeight,
    int targetReps, {
    int? targetSets,
    int? restSeconds,
  }) async {
    final payload = <String, dynamic>{
      'target_weight': targetWeight,
      'target_reps': targetReps,
    };
    if (targetSets != null) payload['target_sets'] = targetSets;
    if (restSeconds != null) payload['rest_timer_seconds'] = restSeconds;

    await client.from('routine_exercises').update(payload).match({
      'routine_day_id': routineDayId,
      'exercise_id': exerciseId,
    });
  }

  Future<List<RoutineModel>> getAllRoutines({
    int limit = _kDefaultRoutineListLimit,
    int offset = 0,
  }) async {
    final userId = client.auth.currentUser?.id;
    final response = await client
        .from('routines_view')
        .select(_routineViewSelect)
        .or('is_public.eq.true${userId != null ? ",creator_id.eq.$userId" : ""}')
        .order('name', ascending: true)
        .range(offset, offset + limit - 1);
    return response.map((json) => RoutineModel.fromJson(json)).toList();
  }
}
