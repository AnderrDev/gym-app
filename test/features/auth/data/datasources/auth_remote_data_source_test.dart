// ignore_for_file: must_be_immutable
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/config/deep_links.dart';
import 'package:gym_flutter/features/auth/data/datasources/auth_remote_data_source.dart';
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
}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  @override
  PostgrestFilterBuilder<PostgrestList> upsert(
    Object values, {
    String? onConflict,
    bool ignoreDuplicates = false,
    bool defaultToNull = false,
  }) {
    return _upsert(values);
  }

  late PostgrestFilterBuilder<PostgrestList> Function(Object) _upsert;

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
  PostgrestTransformBuilder<PostgrestMap?> maybeSingle() => _maybeSingle();
  late PostgrestTransformBuilder<PostgrestMap?> Function() _maybeSingle;

  @override
  Future<U> then<U>(
    FutureOr<U> Function(PostgrestList) onValue, {
    Function? onError,
  }) => Future.value(<Map<String, dynamic>>[]).then(onValue);
}

class FakePostgrestTransformBuilder extends Fake
    implements PostgrestTransformBuilder<PostgrestMap?> {
  late Map<String, dynamic>? _data;
  void setData(Map<String, dynamic>? data) => _data = data;

  @override
  Future<U> then<U>(
    FutureOr<U> Function(PostgrestMap?) onValue, {
    Function? onError,
  }) => Future.value(_data).then(onValue);
}

class MockAuthResponse extends Mock implements AuthResponse {}

class MockUser extends Mock implements User {}

void main() {
  late AuthRemoteDataSourceImpl dataSource;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late StreamController<AuthState> authEvents;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    mockSupabaseClient.setAuth(mockGoTrueClient);
    authEvents = StreamController<AuthState>.broadcast();
    when(
      () => mockGoTrueClient.onAuthStateChange,
    ).thenAnswer((_) => authEvents.stream);
    dataSource = AuthRemoteDataSourceImpl(client: mockSupabaseClient);
  });

  tearDown(() => authEvents.close());

  Session session() =>
      Session(accessToken: 'token', tokenType: 'bearer', user: MockUser());

  const tEmail = 'test@example.com';
  const tPassword = 'password';
  const tId = '123';
  const tFullName = 'Test User';

  group('signInWithEmail', () {
    test('debería realizar login exitoso y retornar UserModel', () async {
      final mockAuthResponse = MockAuthResponse();
      final mockUser = MockUser();

      when(() => mockUser.id).thenReturn(tId);
      when(() => mockUser.email).thenReturn(tEmail);
      when(() => mockUser.userMetadata).thenReturn({'full_name': tFullName});
      when(() => mockAuthResponse.user).thenReturn(mockUser);

      when(
        () => mockGoTrueClient.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => mockAuthResponse);

      final fakeQueryBuilder = FakeSupabaseQueryBuilder();
      final fakeFilterBuilder = FakePostgrestFilterBuilder();
      final fakeTransformBuilder = FakePostgrestTransformBuilder();
      fakeTransformBuilder.setData({'full_name': tFullName});

      mockSupabaseClient.setFrom((_) => fakeQueryBuilder);
      fakeQueryBuilder._upsert = (_) => fakeFilterBuilder;
      fakeQueryBuilder._select = (_) => fakeFilterBuilder;
      fakeFilterBuilder._maybeSingle = () => fakeTransformBuilder;

      final result = await dataSource.signInWithEmail(tEmail, tPassword);

      expect(result.id, tId);
      expect(result.fullName, tFullName);
    });
  });

  group('getCurrentUser', () {
    test('debería retornar null si no hay usuario autenticado', () async {
      when(() => mockGoTrueClient.currentUser).thenReturn(null);
      when(() => mockGoTrueClient.currentSession).thenReturn(null);

      final result = await dataSource.getCurrentUser();
      expect(result, isNull);
    });
  });

  group('sendPasswordResetEmail', () {
    test('en móvil usa el deep link propio como redirectTo', () async {
      when(
        () => mockGoTrueClient.resetPasswordForEmail(
          any(),
          redirectTo: any(named: 'redirectTo'),
        ),
      ).thenAnswer((_) async {});

      await dataSource.sendPasswordResetEmail(tEmail);

      verify(
        () => mockGoTrueClient.resetPasswordForEmail(
          tEmail,
          redirectTo: DeepLinks.resetPassword,
        ),
      ).called(1);
      expect(
        DeepLinks.resetPassword,
        'com.gymtracker.gymflutter://reset-password',
      );
    });
  });

  group('authStateChanges', () {
    test('passwordRecovery con sesión cuenta como autenticado', () async {
      final emitted = <bool>[];
      final sub = dataSource.authStateChanges.listen(emitted.add);

      authEvents.add(const AuthState(AuthChangeEvent.initialSession, null));
      authEvents.add(AuthState(AuthChangeEvent.passwordRecovery, session()));
      await pumpEventQueue();

      expect(emitted, [false, true]);
      await sub.cancel();
    });
  });

  group('passwordRecoveryEvents', () {
    test('entrega el recovery emitido antes de que nadie escuche aunque '
        'después llegue otro evento', () async {
      // Arranque en frío: Supabase canjea el code y emite `passwordRecovery`
      // antes de que exista `AppRouter`; luego `recoverSession()` refresca el
      // token. El BehaviorSubject del SDK solo repetiría `tokenRefreshed`.
      authEvents.add(AuthState(AuthChangeEvent.passwordRecovery, session()));
      authEvents.add(AuthState(AuthChangeEvent.tokenRefreshed, session()));
      await pumpEventQueue();

      var count = 0;
      final sub = dataSource.passwordRecoveryEvents.listen((_) => count++);
      await pumpEventQueue();

      expect(count, 1);
      await sub.cancel();
    });

    test(
      'con la app abierta emite en caliente e ignora otros eventos',
      () async {
        var count = 0;
        final sub = dataSource.passwordRecoveryEvents.listen((_) => count++);
        await pumpEventQueue();

        authEvents.add(AuthState(AuthChangeEvent.signedIn, session()));
        authEvents.add(AuthState(AuthChangeEvent.passwordRecovery, session()));
        await pumpEventQueue();

        expect(count, 1);
        await sub.cancel();
      },
    );
  });
}
