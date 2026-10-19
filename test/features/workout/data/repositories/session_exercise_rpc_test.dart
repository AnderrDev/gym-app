import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gym_flutter/features/workout/data/datasources/workout_remote_data_source.dart';
import 'package:gym_flutter/features/workout/data/repositories/workout_repository_impl.dart';
import 'package:gym_flutter/core/error/failures.dart';

void main() {
  test(
    'un ejercicio duplicado muestra un error recuperable en español',
    () async {
      final client = SupabaseClient(
        'https://gym.example',
        'public-test-key',
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'code': '23505',
              'message': 'exercise already in session',
            }),
            409,
            request: request,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );
      final repository = WorkoutRepositoryImpl(
        remoteDataSource: WorkoutRemoteDataSourceImpl(client: client),
      );
      final result = await repository.getSessionExercises('s1');
      final failure = result.swap().getOrElse(
        (_) => throw StateError('Expected failure'),
      );
      expect(failure, isA<ConflictFailure>());
      expect(failure.message, 'Ese ejercicio ya está en esta sesión.');
      await client.dispose();
    },
  );
  test(
    'RPC de sesión devuelve entidades reales y envía objetivos solo a la sesión',
    () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://gym.example',
        'public-test-key',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode([
              {
                'id': 'e2',
                'routine_day_id': 'd1',
                'name': 'Press máquina',
                'muscle_group': 'Pecho',
                'target_sets': 2,
                'target_reps': 12,
                'target_weight': 25.5,
                'replaces_exercise_name': 'Press banca',
                'is_extra': false,
              },
            ]),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final remote = WorkoutRemoteDataSourceImpl(client: client);
      final repository = WorkoutRepositoryImpl(remoteDataSource: remote);
      final plan = (await repository.getSessionExercises(
        's1',
      )).getOrElse((failure) => throw failure);
      expect(plan.single.name, 'Press máquina');
      expect(plan.single.replacesExerciseName, 'Press banca');
      final adapted = await repository.adaptSessionExercise(
        's1',
        'e2',
        targetSets: 2,
        targetReps: 12,
        targetWeight: 25.5,
        replaceExerciseId: 'e1',
      );
      expect(adapted.isRight(), true);
      expect(requests.map((request) => request.url.path), [
        '/rest/v1/rpc/get_session_exercises_v1',
        '/rest/v1/rpc/adapt_session_exercise_v1',
      ]);
      expect(jsonDecode(requests.last.body), {
        'p_session_id': 's1',
        'p_exercise_id': 'e2',
        'p_target_sets': 2,
        'p_target_reps': 12,
        'p_target_weight': 25.5,
        'p_replace_exercise_id': 'e1',
      });
      await client.dispose();
    },
  );
}
