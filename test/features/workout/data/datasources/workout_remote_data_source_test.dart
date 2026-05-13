// ignore_for_file: must_be_immutable
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/workout/data/datasources/workout_remote_data_source.dart';
import 'package:gym_flutter/features/workout/data/models/routine_model.dart';
import 'package:gym_flutter/features/workout/data/models/set_log_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {
  @override
  GoTrueClient get auth => _auth;
  late GoTrueClient _auth;
  void setAuth(GoTrueClient auth) => _auth = auth;

  @override
  SupabaseQueryBuilder from(String table) => _from(table);
  late SupabaseQueryBuilder Function(String) _from;
  void setFrom(SupabaseQueryBuilder Function(String) from) => _from = from;

  @override
  FunctionsClient get functions => _functions;
  late FunctionsClient _functions;
  void setFunctions(FunctionsClient functions) => _functions = functions;
}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockSession extends Mock implements Session {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  @override
  PostgrestFilterBuilder<PostgrestList> select([String? columns]) =>
      _select(columns);
  late PostgrestFilterBuilder<PostgrestList> Function(String?) _select;

  @override
  PostgrestFilterBuilder<dynamic> insert(
    Object values, {
    String? onConflict,
    bool ignoreDuplicates = false,
    bool defaultToNull = false,
  }) => _insert(values);
  late PostgrestFilterBuilder<dynamic> Function(Object) _insert;

  @override
  PostgrestFilterBuilder<dynamic> upsert(
    Object values, {
    String? onConflict,
    bool ignoreDuplicates = false,
    bool defaultToNull = false,
  }) => _upsert(values);
  late PostgrestFilterBuilder<dynamic> Function(Object) _upsert;

  @override
  PostgrestFilterBuilder<dynamic> update(Object values) => _update(values);
  late PostgrestFilterBuilder<dynamic> Function(Object) _update;

  @override
  PostgrestFilterBuilder<dynamic> delete() => _delete();
  late PostgrestFilterBuilder<dynamic> Function() _delete;
}

class FakePostgrestListFilterBuilder extends Fake
    implements PostgrestFilterBuilder<PostgrestList> {
  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) => this;
  @override
  PostgrestFilterBuilder<PostgrestList> filter(
    String column,
    String operator,
    Object? value,
  ) => this;
  @override
  PostgrestFilterBuilder<PostgrestList> order(
    String column, {
    bool ascending = true,
    bool nullsFirst = false,
    String? referencedTable,
  }) => this;
  @override
  PostgrestFilterBuilder<PostgrestList> limit(
    int count, {
    String? referencedTable,
  }) => this;
  @override
  PostgrestFilterBuilder<PostgrestList> lt(String column, Object value) => this;
  @override
  PostgrestFilterBuilder<PostgrestList> not(
    String column,
    String operator,
    Object? value,
  ) => this;

  @override
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() => _maybeSingle();
  late PostgrestTransformBuilder<PostgrestMap?> Function() _maybeSingle;

  @override
  PostgrestTransformBuilder<PostgrestMap> single() => _single();
  late PostgrestTransformBuilder<PostgrestMap> Function() _single;

  @override
  Future<U> then<U>(
    FutureOr<U> Function(PostgrestList) onValue, {
    Function? onError,
  }) => Future.value(_data).then(onValue);

  late PostgrestList _data;
  void setData(PostgrestList data) => _data = data;
}

class FakePostgrestDynamicFilterBuilder extends Fake
    implements PostgrestFilterBuilder<dynamic> {
  @override
  PostgrestFilterBuilder<dynamic> eq(String column, Object value) => this;
  @override
  PostgrestFilterBuilder<dynamic> match(Map<dynamic, dynamic> query) => this;

  @override
  PostgrestFilterBuilder<PostgrestList> select([String? columns]) {
    if (_selectMap != null) {
      return _selectMap!(columns);
    }
    return _select(columns);
  }

  late PostgrestFilterBuilder<PostgrestList> Function(String?) _select;
  PostgrestFilterBuilder<PostgrestList> Function(String?)? _selectMap;
  void setSelectMap(
    PostgrestFilterBuilder<PostgrestList> Function(String?) fn,
  ) => _selectMap = fn;

  @override
  Future<U> then<U>(
    FutureOr<U> Function(dynamic) onValue, {
    Function? onError,
  }) => Future.value(_data).then(onValue);

  late dynamic _data;
  void setData(dynamic data) => _data = data;
}

class FakePostgrestMapTransformBuilder extends Fake
    implements PostgrestTransformBuilder<PostgrestMap> {
  @override
  Future<U> then<U>(
    FutureOr<U> Function(PostgrestMap) onValue, {
    Function? onError,
  }) => Future.value(_data).then(onValue);
  late PostgrestMap _data;
  void setData(PostgrestMap data) => _data = data;
}

class FakePostgrestNullableMapTransformBuilder extends Fake
    implements PostgrestTransformBuilder<PostgrestMap?> {
  @override
  Future<U> then<U>(
    FutureOr<U> Function(PostgrestMap?) onValue, {
    Function? onError,
  }) => Future.value(_data).then(onValue);
  late PostgrestMap? _data;
  void setData(PostgrestMap? data) => _data = data;
}

void main() {
  late WorkoutRemoteDataSourceImpl dataSource;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late MockUser mockUser;
  late MockSession mockSession;
  late MockFunctionsClient mockFunctionsClient;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    mockUser = MockUser();
    mockSession = MockSession();
    mockFunctionsClient = MockFunctionsClient();

    mockSupabaseClient.setAuth(mockGoTrueClient);
    mockSupabaseClient.setFunctions(mockFunctionsClient);

    when(() => mockGoTrueClient.currentUser).thenReturn(mockUser);
    when(() => mockGoTrueClient.currentSession).thenReturn(mockSession);
    when(() => mockSession.accessToken).thenReturn('token');
    when(() => mockUser.id).thenReturn('u1');

    dataSource = WorkoutRemoteDataSourceImpl(client: mockSupabaseClient);
  });

  const tUserId = 'u1';
  const tRoutineDayId = 'rd1';
  final tDate = DateTime(2026, 4, 5);

  group('startWorkoutForDay', () {
    test('debería retornar la sesión activa si ya existe una', () async {
      final fakeQueryBuilder = FakeSupabaseQueryBuilder();
      final fakeFilterBuilder = FakePostgrestListFilterBuilder();
      final fakeTransformBuilder = FakePostgrestNullableMapTransformBuilder();

      final tActiveSession = {
        'id': 's_active',
        'user_id': tUserId,
        'routine_day_id': 'other_day',
        'session_date': '2026-04-05',
        'completed_at': null,
      };

      mockSupabaseClient.setFrom((_) => fakeQueryBuilder);
      fakeQueryBuilder._select = (cols) => fakeFilterBuilder;
      fakeFilterBuilder._maybeSingle = () => fakeTransformBuilder;
      fakeTransformBuilder.setData(tActiveSession);

      final result = await dataSource.startWorkoutForDay(
        tUserId,
        tRoutineDayId,
        tDate,
      );
      expect(result.id, 's_active');
    });
  });

  group('saveSetLog', () {
    test('debería llamar a upsert con los datos correctos sin el id', () async {
      final fakeQueryBuilder = FakeSupabaseQueryBuilder();
      final fakeFilterBuilder = FakePostgrestDynamicFilterBuilder();

      mockSupabaseClient.setFrom((_) => fakeQueryBuilder);
      fakeQueryBuilder._upsert = (vals) {
        final payload = vals as Map<String, dynamic>;
        expect(payload.containsKey('id'), isFalse);
        fakeFilterBuilder.setData([]);
        return fakeFilterBuilder;
      };

      final tSetLog = SetLogModel(
        id: 'temp_id',
        sessionId: 's1',
        exerciseId: 'e1',
        setIndex: 1,
        actualWeight: 10.0,
        actualReps: 10,
        createdAt: DateTime.now(),
      );

      await dataSource.saveSetLog(tSetLog);
    });
  });

  group('finishWorkoutSession', () {
    test('debería llamar a la edge function con éxito', () async {
      final response = FunctionResponse(data: {'success': true}, status: 200);
      when(
        () => mockFunctionsClient.invoke(
          any(),
          body: any(named: 'body'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => response);

      await dataSource.finishWorkoutSession('s1');

      verify(
        () => mockFunctionsClient.invoke(
          'finalize_workout_session_v1',
          body: {'session_id': 's1'},
          headers: {'Authorization': 'Bearer token'},
        ),
      ).called(1);
    });
  });

  group('getWeeklyInsights', () {
    test('debería retornar WeeklyInsights con éxito', () async {
      final tInsightsJson = {
        'success': true,
        'data': {
          'week_start': '2026-04-05',
          'week_end': '2026-04-11',
          'planned_days': 5,
          'completed_days': 3,
          'completed_sessions': 3,
          'adherence_rate': 0.6,
          'total_volume': 1500.0,
          'previous_week_volume': 1400.0,
          'volume_trend_percent': 7.1,
          'personal_records': 2,
        },
      };

      final response = FunctionResponse(data: tInsightsJson, status: 200);
      when(
        () => mockFunctionsClient.invoke(
          'get_weekly_insights_v1',
          body: any(named: 'body'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => response);

      final result = await dataSource.getWeeklyInsights(
        routineId: 'r1',
        weekStart: tDate,
      );
      expect(result.plannedDays, 5);
      expect(result.totalVolume, 1500.0);
    });
  });

  group('getExerciseLogsHistory', () {
    test('debería retornar lista de logs históricos', () async {
      final fakeQueryBuilder = FakeSupabaseQueryBuilder();
      final fakeFilterBuilder = FakePostgrestListFilterBuilder();

      final tLogs = [
        {
          'id': 'l1',
          'session_id': 's1',
          'exercise_id': 'e1',
          'actual_weight': 20.0,
          'actual_reps': 12,
          'set_index': 0,
          'created_at': DateTime.now().toIso8601String(),
          'workout_sessions': {'session_date': '2026-04-01'},
        },
      ];

      mockSupabaseClient.setFrom((_) => fakeQueryBuilder);
      fakeQueryBuilder._select = (cols) => fakeFilterBuilder;
      fakeFilterBuilder.setData(tLogs);

      final result = await dataSource.getExerciseLogsHistory('u1', 'e1');
      expect(result.length, 1);
    });
  });

  group('saveRoutine', () {
    test('debería insertar una nueva rutina y devolverla con id real',
        () async {
      final fakeQueryBuilder = FakeSupabaseQueryBuilder();
      final fakeFilterBuilder = FakePostgrestDynamicFilterBuilder();
      final fakeListFilterBuilder = FakePostgrestListFilterBuilder();
      final fakeMapTransform = FakePostgrestMapTransformBuilder();
      fakeMapTransform.setData({
        'id': 'r_new',
        'name': 'N',
        'is_public': false,
        'creator_id': 'u1',
      });

      mockSupabaseClient.setFrom((_) => fakeQueryBuilder);
      fakeQueryBuilder._insert = (vals) => fakeFilterBuilder;
      fakeFilterBuilder.setSelectMap((_) => fakeListFilterBuilder);
      fakeListFilterBuilder._single = () => fakeMapTransform;

      final saved = await dataSource.saveRoutine(
        const RoutineModel(id: 'new_1', name: 'N', exerciseCount: 0),
      );
      expect(saved.id, 'r_new');
      expect(saved.name, 'N');
    });

    test('debería actualizar una rutina existente y devolverla', () async {
      final fakeQueryBuilder = FakeSupabaseQueryBuilder();
      final fakeFilterBuilder = FakePostgrestDynamicFilterBuilder();
      final fakeListFilterBuilder = FakePostgrestListFilterBuilder();
      final fakeMapTransform = FakePostgrestMapTransformBuilder();
      fakeMapTransform.setData({
        'id': 'r1',
        'name': 'E',
        'is_public': true,
        'creator_id': 'u1',
      });

      mockSupabaseClient.setFrom((_) => fakeQueryBuilder);
      fakeQueryBuilder._update = (vals) => fakeFilterBuilder;
      fakeFilterBuilder.setSelectMap((_) => fakeListFilterBuilder);
      fakeListFilterBuilder._single = () => fakeMapTransform;

      final saved = await dataSource.saveRoutine(
        const RoutineModel(id: 'r1', name: 'E', exerciseCount: 0),
      );
      expect(saved.id, 'r1');
      expect(saved.isPublic, isTrue);
    });
  });

  group('removeExerciseFromDay', () {
    test('debería llamar a delete con dayId y exerciseId', () async {
      final fakeQueryBuilder = FakeSupabaseQueryBuilder();
      final fakeFilterBuilder = FakePostgrestDynamicFilterBuilder();

      mockSupabaseClient.setFrom((_) => fakeQueryBuilder);
      fakeQueryBuilder._delete = () {
        fakeFilterBuilder.setData([]);
        return fakeFilterBuilder;
      };

      await dataSource.removeExerciseFromDay('rd1', 'e1');
    });
  });

  group('deleteRoutine', () {
    test('debería llamar a delete para la rutina', () async {
      final fakeQueryBuilder = FakeSupabaseQueryBuilder();
      final fakeFilterBuilder = FakePostgrestDynamicFilterBuilder();

      mockSupabaseClient.setFrom((_) => fakeQueryBuilder);
      fakeQueryBuilder._delete = () {
        fakeFilterBuilder.setData([]);
        return fakeFilterBuilder;
      };

      await dataSource.deleteRoutine('r1');
    });
  });

}
