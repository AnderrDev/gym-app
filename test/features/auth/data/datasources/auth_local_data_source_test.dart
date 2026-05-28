import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:gym_flutter/features/auth/data/models/user_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late AuthLocalDataSourceImpl dataSource;
  late MockSharedPreferences mockSharedPreferences;

  setUp(() {
    mockSharedPreferences = MockSharedPreferences();
    dataSource = AuthLocalDataSourceImpl(
      sharedPreferences: mockSharedPreferences,
    );
  });

  const tUserModel = UserModel(
    id: 'u1',
    email: 'test@example.com',
    fullName: 'Test User',
  );

  group('cacheUser', () {
    test(
      'debería llamar a SharedPreferences para guardar el usuario',
      () async {
        final expectedJsonString = json.encode(tUserModel.toJson());
        when(
          () => mockSharedPreferences.setString(any(), any()),
        ).thenAnswer((_) async => true);

        await dataSource.cacheUser(tUserModel);

        verify(
          () => mockSharedPreferences.setString(
            cachedUserKey,
            expectedJsonString,
          ),
        ).called(1);
      },
    );
  });

  group('getLastCachedUser', () {
    test('debería retornar UserModel del cache cuando existe', () async {
      final jsonString = json.encode(tUserModel.toJson());
      when(() => mockSharedPreferences.getString(any())).thenReturn(jsonString);

      final result = await dataSource.getLastCachedUser();

      // UserModel ya no tiene `==` (no es Equatable); comparamos el JSON.
      expect(result?.toJson(), tUserModel.toJson());
      verify(() => mockSharedPreferences.getString(cachedUserKey)).called(1);
    });

    test('debería retornar null cuando no hay usuario en cache', () async {
      when(() => mockSharedPreferences.getString(any())).thenReturn(null);

      final result = await dataSource.getLastCachedUser();

      expect(result, isNull);
    });
  });

  group('clearCache', () {
    test('debería llamar a remove en SharedPreferences', () async {
      when(
        () => mockSharedPreferences.remove(any()),
      ).thenAnswer((_) async => true);

      await dataSource.clearCache();

      verify(() => mockSharedPreferences.remove(cachedUserKey)).called(1);
    });
  });
}
