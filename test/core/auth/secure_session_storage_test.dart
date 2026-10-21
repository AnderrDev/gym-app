import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/auth/secure_session_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ThrowingSecureStorage extends Mock implements FlutterSecureStorage {}

const _key = 'sb-abc-auth-token';
const _session = '{"access_token":"a","refresh_token":"r"}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> keychain;

  SecureSessionStorage build({FlutterSecureStorage? secure}) =>
      SecureSessionStorage(
        persistSessionKey: _key,
        secureStorage: secure ?? const FlutterSecureStorage(),
      );

  setUp(() {
    keychain = <String, String>{};
    FlutterSecureStorage.setMockInitialValues(keychain);
  });

  group('migración desde SharedPreferences', () {
    test(
      'usuario existente: copia la sesión al Keychain y la borra de prefs',
      () async {
        SharedPreferences.setMockInitialValues({_key: _session});
        final storage = build();

        await storage.initialize();

        expect(keychain[_key], _session);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey(_key), isFalse);
        expect(prefs.getBool(SecureSessionStorage.installedFlagKey), isTrue);
        expect(await storage.hasAccessToken(), isTrue);
        expect(await storage.accessToken(), _session);
        expect(storage.isUsingFallback, isFalse);
      },
    );

    test('sin sesión previa: no escribe nada en el Keychain', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = build();

      await storage.initialize();

      expect(keychain, isEmpty);
      expect(await storage.hasAccessToken(), isFalse);
      expect(await storage.accessToken(), isNull);
    });

    test(
      'Keychain ya poblado: manda el Keychain y limpia restos en prefs',
      () async {
        SharedPreferences.setMockInitialValues({
          SecureSessionStorage.installedFlagKey: true,
          _key: 'vieja',
        });
        keychain[_key] = _session;
        final storage = build();

        await storage.initialize();

        expect(keychain[_key], _session);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey(_key), isFalse);
      },
    );
  });

  group('reinstalación', () {
    test(
      'sin flag de instalación borra la sesión que sobrevivió en Keychain',
      () async {
        SharedPreferences.setMockInitialValues({});
        keychain[_key] = _session;
        final storage = build();

        await storage.initialize();

        expect(keychain.containsKey(_key), isFalse);
        expect(await storage.hasAccessToken(), isFalse);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool(SecureSessionStorage.installedFlagKey), isTrue);
      },
    );

    test('con flag de instalación conserva la sesión del Keychain', () async {
      SharedPreferences.setMockInitialValues({
        SecureSessionStorage.installedFlagKey: true,
      });
      keychain[_key] = _session;
      final storage = build();

      await storage.initialize();

      expect(await storage.accessToken(), _session);
    });
  });

  group('persist / remove', () {
    test('persistSession escribe en Keychain y no en prefs', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = build();
      await storage.initialize();

      await storage.persistSession(_session);

      expect(keychain[_key], _session);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(_key), isFalse);
    });

    test('removePersistedSession borra del Keychain', () async {
      SharedPreferences.setMockInitialValues({
        SecureSessionStorage.installedFlagKey: true,
      });
      keychain[_key] = _session;
      final storage = build();
      await storage.initialize();

      await storage.removePersistedSession();

      expect(keychain.containsKey(_key), isFalse);
      expect(await storage.hasAccessToken(), isFalse);
    });
  });

  group('error del Keychain', () {
    late _ThrowingSecureStorage secure;

    setUp(() {
      secure = _ThrowingSecureStorage();
      final error = PlatformException(code: 'keychain', message: 'boom');
      when(() => secure.delete(key: any(named: 'key'))).thenThrow(error);
      when(() => secure.containsKey(key: any(named: 'key'))).thenThrow(error);
      when(() => secure.read(key: any(named: 'key'))).thenThrow(error);
      when(
        () => secure.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenThrow(error);
    });

    test(
      'initialize no lanza y cae a SharedPreferences sin perder la sesión',
      () async {
        SharedPreferences.setMockInitialValues({_key: _session});
        final storage = build(secure: secure);

        await storage.initialize();

        expect(storage.isUsingFallback, isTrue);
        expect(await storage.hasAccessToken(), isTrue);
        expect(await storage.accessToken(), _session);
        final prefs = await SharedPreferences.getInstance();
        // El flag no se escribe: la migración se reintenta en el próximo
        // arranque.
        expect(
          prefs.containsKey(SecureSessionStorage.installedFlagKey),
          isFalse,
        );
      },
    );

    test(
      'en modo fallback persist/remove operan sobre SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({});
        final storage = build(secure: secure);
        await storage.initialize();

        await storage.persistSession(_session);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(_key), _session);

        await storage.removePersistedSession();
        expect(prefs.containsKey(_key), isFalse);
      },
    );

    test('un fallo tras initialize se loguea y no lanza', () async {
      SharedPreferences.setMockInitialValues({
        SecureSessionStorage.installedFlagKey: true,
      });
      final flaky = _ThrowingSecureStorage();
      when(
        () => flaky.containsKey(key: any(named: 'key')),
      ).thenAnswer((_) async => false);
      final storage = build(secure: flaky);
      await storage.initialize();
      expect(storage.isUsingFallback, isFalse);

      final error = PlatformException(code: 'keychain');
      when(() => flaky.containsKey(key: any(named: 'key'))).thenThrow(error);
      when(() => flaky.read(key: any(named: 'key'))).thenThrow(error);
      when(() => flaky.delete(key: any(named: 'key'))).thenThrow(error);
      when(
        () => flaky.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenThrow(error);

      expect(await storage.hasAccessToken(), isFalse);
      expect(await storage.accessToken(), isNull);
      await storage.persistSession(_session);
      await storage.removePersistedSession();
    });
  });
}
