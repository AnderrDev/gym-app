import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gym_flutter/core/observability/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [LocalStorage] de `supabase_flutter` que guarda la sesión (access +
/// refresh token) en el Keychain (iOS) / Keystore (Android) en lugar de
/// `SharedPreferences` (NSUserDefaults en iOS: texto plano y dentro de los
/// backups). Solo se usa en plataformas nativas — en web sigue el storage
/// por defecto (ver `Capabilities.supportsSecureSessionStorage`).
///
/// Al inicializar hace, en este orden:
/// 1. **Reinstalación (iOS):** el Keychain sobrevive a la desinstalación,
///    `SharedPreferences` no. Si falta el flag [installedFlagKey] en
///    `SharedPreferences` es la primera ejecución de esta instalación, así
///    que se borra cualquier sesión que haya quedado en el Keychain.
/// 2. **Migración única:** si el Keychain no tiene sesión pero
///    `SharedPreferences` sí (misma [persistSessionKey] que usa
///    `SharedPreferencesLocalStorage`), se copia al Keychain y se borra de
///    `SharedPreferences`. Así un usuario que actualiza no pierde la sesión.
/// 3. Se escribe el flag de instalación.
///
/// **Si el Keychain falla** durante `initialize()` (p. ej. dispositivo aún
/// bloqueado tras reiniciar, o un error del plugin) se cae al
/// comportamiento anterior durante este proceso: todas las operaciones van
/// a `SharedPreferences`. Elegimos esto frente a "sin sesión" para no
/// desloguear al usuario por un fallo transitorio; el flag no se escribe y
/// la migración se reintenta en el siguiente arranque. Ninguna operación
/// lanza excepciones: los errores se loguean con [AppLogger].
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({
    required this.persistSessionKey,
    FlutterSecureStorage? secureStorage,
    Future<SharedPreferences> Function()? preferences,
  }) : _secure = secureStorage ?? defaultSecureStorage,
       _loadPreferences = preferences ?? SharedPreferences.getInstance;

  /// Clave de la sesión, idéntica a la del storage por defecto de
  /// `supabase_flutter` (`sb-<ref>-auth-token`) para poder migrarla.
  final String persistSessionKey;

  /// Flag en `SharedPreferences` que marca que esta instalación ya
  /// arrancó al menos una vez con el storage seguro.
  static const String installedFlagKey = 'secure_session_storage.installed';

  /// Keychain accesible tras el primer desbloqueo (permite refrescar el
  /// token en segundo plano) y no migrable a otro dispositivo ni a iCloud.
  /// En Android se usan las opciones por defecto de v10 (cifrado AES-GCM
  /// con clave en el Keystore); `encryptedSharedPreferences` está
  /// deprecado en esta versión.
  static const FlutterSecureStorage defaultSecureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    aOptions: AndroidOptions(),
  );

  final FlutterSecureStorage _secure;
  final Future<SharedPreferences> Function() _loadPreferences;

  SharedPreferences? _prefs;

  /// `true` si el Keychain falló al inicializar y se usa `SharedPreferences`.
  bool _useFallback = false;

  /// Expuesto para tests y diagnóstico.
  bool get isUsingFallback => _useFallback;

  @override
  Future<void> initialize() async {
    try {
      _prefs = await _loadPreferences();
    } catch (e, st) {
      AppLogger.instance.error(
        'secure_session_storage.prefs_unavailable',
        e,
        st,
      );
    }
    final prefs = _prefs;

    try {
      if (prefs != null && prefs.getBool(installedFlagKey) != true) {
        // Primera ejecución de esta instalación: descartar una sesión que
        // haya sobrevivido en el Keychain a una desinstalación previa.
        await _secure.delete(key: persistSessionKey);
      }

      final hasSecure = await _secure.containsKey(key: persistSessionKey);
      final legacy = prefs?.getString(persistSessionKey);
      if (!hasSecure && legacy != null) {
        await _secure.write(key: persistSessionKey, value: legacy);
        await prefs!.remove(persistSessionKey);
        AppLogger.instance.info('secure_session_storage.migrated');
      } else if (hasSecure && legacy != null) {
        // Restos de una migración interrumpida: manda el Keychain.
        await prefs!.remove(persistSessionKey);
      }

      await prefs?.setBool(installedFlagKey, true);
    } catch (e, st) {
      _useFallback = true;
      AppLogger.instance.error(
        'secure_session_storage.keychain_unavailable — usando SharedPreferences',
        e,
        st,
      );
    }
  }

  @override
  Future<bool> hasAccessToken() async {
    if (_useFallback) {
      return _prefs?.containsKey(persistSessionKey) ?? false;
    }
    try {
      return await _secure.containsKey(key: persistSessionKey);
    } catch (e, st) {
      AppLogger.instance.error('secure_session_storage.has_failed', e, st);
      return false;
    }
  }

  @override
  Future<String?> accessToken() async {
    if (_useFallback) return _prefs?.getString(persistSessionKey);
    try {
      return await _secure.read(key: persistSessionKey);
    } catch (e, st) {
      AppLogger.instance.error('secure_session_storage.read_failed', e, st);
      return null;
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    if (_useFallback) {
      await _safePrefs(
        'persist',
        (p) => p.setString(persistSessionKey, persistSessionString),
      );
      return;
    }
    try {
      await _secure.write(key: persistSessionKey, value: persistSessionString);
    } catch (e, st) {
      AppLogger.instance.error('secure_session_storage.write_failed', e, st);
    }
  }

  @override
  Future<void> removePersistedSession() async {
    // Se borra en ambos stores: en logout no debe quedar copia en ninguno.
    if (!_useFallback) {
      try {
        await _secure.delete(key: persistSessionKey);
      } catch (e, st) {
        AppLogger.instance.error('secure_session_storage.delete_failed', e, st);
      }
    }
    await _safePrefs('remove', (p) => p.remove(persistSessionKey));
  }

  Future<void> _safePrefs(
    String op,
    Future<bool> Function(SharedPreferences prefs) body,
  ) async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await body(prefs);
    } catch (e, st) {
      AppLogger.instance.error('secure_session_storage.prefs_$op', e, st);
    }
  }
}
