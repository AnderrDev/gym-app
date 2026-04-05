import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/workout/data/datasources/workout_remote_data_source.dart';
import 'package:gym_flutter/features/workout/data/models/routine_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {
  @override
  SupabaseQueryBuilder from(String table) => _from(table);
  late SupabaseQueryBuilder Function(String) _from;
  void setFrom(SupabaseQueryBuilder Function(String) from) => _from = from;
}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  @override
  PostgrestFilterBuilder<PostgrestList> select([String? columns]) =>
      _select(columns);
  late PostgrestFilterBuilder<PostgrestList> Function(String?) _select;
}

class FakePostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) => this;

  @override
  PostgrestFilterBuilder<PostgrestList> order(
    String column, {
    bool ascending = true,
    bool nullsFirst = false,
    String? referencedTable,
  }) => this;

  @override
  PostgrestFilterBuilder<PostgrestList> gte(String column, Object value) =>
      this;

  @override
  PostgrestFilterBuilder<PostgrestList> lte(String column, Object value) =>
      this;

  @override
  Future<U> then<U>(
    FutureOr<U> Function(PostgrestList) onValue, {
    Function? onError,
  }) => Future.value(_data).then(onValue);

  late PostgrestList _data;
  void setData(PostgrestList data) => _data = data;
}

void main() {
  late WorkoutRemoteDataSourceImpl dataSource;
  late MockSupabaseClient mockSupabaseClient;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    dataSource = WorkoutRemoteDataSourceImpl(client: mockSupabaseClient);
  });

  const tUserId = 'u1';

  group('getAssignedRoutines', () {
    test(
      'debería retornar lista de RoutineModel al consultar asignaciones',
      () async {
        final fakeQueryBuilder = FakeSupabaseQueryBuilder();
        final fakeFilterBuilder = FakePostgrestFilterBuilder();

        final tResponse = [
          {
            'routine_id': 'r1',
            'routines': {
              'id': 'r1',
              'name': 'Rutina Test',
              'is_public': true,
              'creator_id': 'c1',
            },
          },
        ];

        mockSupabaseClient.setFrom((_) => fakeQueryBuilder);
        fakeQueryBuilder._select = (_) => fakeFilterBuilder;
        fakeFilterBuilder.setData(tResponse);

        final result = await dataSource.getAssignedRoutines(tUserId);

        expect(result, isA<List<RoutineModel>>());
        expect(result.first.id, 'r1');
        expect(result.first.name, 'Rutina Test');
      },
    );

    test(
      'debería manejar respuesta con routines null usando el routine_id',
      () async {
        final fakeQueryBuilder = FakeSupabaseQueryBuilder();
        final fakeFilterBuilder = FakePostgrestFilterBuilder();

        final tResponse = [
          {'routine_id': 'r2', 'routines': null},
        ];

        mockSupabaseClient.setFrom((_) => fakeQueryBuilder);
        fakeQueryBuilder._select = (_) => fakeFilterBuilder;
        fakeFilterBuilder.setData(tResponse);

        final result = await dataSource.getAssignedRoutines(tUserId);

        expect(result.first.id, 'r2');
        expect(result.first.name, 'Rutina');
      },
    );
  });

  group('getRoutineDays', () {
    test('debería retornar lista de RoutineDayModel ordenados', () async {
      final fakeQueryBuilder = FakeSupabaseQueryBuilder();
      final fakeFilterBuilder = FakePostgrestFilterBuilder();

      final tResponse = [
        {'id': 'rd1', 'routine_id': 'r1', 'day_of_week': 1, 'name': 'Lunes'},
        {'id': 'rd2', 'routine_id': 'r1', 'day_of_week': 2, 'name': 'Martes'},
      ];

      mockSupabaseClient.setFrom((_) => fakeQueryBuilder);
      fakeQueryBuilder._select = (_) => fakeFilterBuilder;
      fakeFilterBuilder.setData(tResponse);

      final result = await dataSource.getRoutineDays('r1');

      expect(result.length, 2);
      expect(result[0].name, 'Lunes');
    });
  });

  group('getExercisesForDay', () {
    test(
      'debería retornar lista de ExerciseModel mapeando la relación exercises',
      () async {
        final fakeQueryBuilder = FakeSupabaseQueryBuilder();
        final fakeFilterBuilder = FakePostgrestFilterBuilder();

        final tResponse = [
          {
            'id': 're1',
            'target_reps': 10,
            'target_weight': 50.0,
            'target_sets': 3,
            'rest_timer_seconds': 60,
            'exercises': {
              'id': 'e1',
              'name': 'Press Banca',
              'muscle_group': 'Pecho',
            },
          },
        ];

        mockSupabaseClient.setFrom((_) => fakeQueryBuilder);
        fakeQueryBuilder._select = (_) => fakeFilterBuilder;
        fakeFilterBuilder.setData(tResponse);

        final result = await dataSource.getExercisesForDay('rd1');

        expect(result.length, 1);
        expect(result[0].name, 'Press Banca');
      },
    );
  });

  group('getWeekSessions', () {
    test(
      'debería retornar sesiones del usuario en el rango de fechas',
      () async {
        final fakeQueryBuilder = FakeSupabaseQueryBuilder();
        final fakeFilterBuilder = FakePostgrestFilterBuilder();

        final tResponse = [
          {
            'id': 's1',
            'user_id': 'u1',
            'routine_day_id': 'rd1',
            'session_date': '2026-04-01',
            'completed_at': null,
            'total_target_sets': 10,
            'total_completed_sets': 5,
          },
        ];

        mockSupabaseClient.setFrom((_) => fakeQueryBuilder);
        fakeQueryBuilder._select = (_) => fakeFilterBuilder;
        fakeFilterBuilder.setData(tResponse);

        final result = await dataSource.getWeekSessions(
          'u1',
          DateTime(2026, 4, 1),
          DateTime(2026, 4, 7),
        );

        expect(result.length, 1);
        expect(result[0].id, 's1');
      },
    );
  });
}
