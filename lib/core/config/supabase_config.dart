import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gym_flutter/core/auth/secure_session_storage.dart';
import 'package:gym_flutter/core/platform/capabilities.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Bootstrap de Supabase. Credenciales en orden de prioridad:
/// 1. `--dart-define=SUPABASE_URL/SUPABASE_ANON_KEY` (CI/release).
/// 2. `.env` cargado por `flutter_dotenv` en `main()` (dev local).
/// No hay fallback hardcoded — si faltan ambas fuentes, `init()` tira `StateError`.
class SupabaseConfig {
  SupabaseConfig._privateConstructor();

  static final SupabaseConfig _instance = SupabaseConfig._privateConstructor();

  static SupabaseConfig get instance => _instance;

  static const String _defineUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _defineAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// `true` si las credenciales llegaron por `--dart-define`; en ese caso
  /// `main()` no necesita cargar `.env`.
  static bool get hasDartDefines =>
      _defineUrl.isNotEmpty && _defineAnonKey.isNotEmpty;

  SupabaseClient get client => Supabase.instance.client;

  String _resolve(String key, String fromDefine) {
    if (fromDefine.isNotEmpty) return fromDefine;
    return dotenv.maybeGet(key, fallback: '') ?? '';
  }

  Future<void> init() async {
    final url = _resolve('SUPABASE_URL', _defineUrl);
    final anonKey = _resolve('SUPABASE_ANON_KEY', _defineAnonKey);

    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError(
        'Faltan credenciales de Supabase. Definí SUPABASE_URL y '
        'SUPABASE_ANON_KEY en `.env` (dev) o pasalas con '
        '--dart-define / --dart-define-from-file=.env (CI).',
      );
    }

    // En iOS/Android la sesión vive en el Keychain/Keystore. La clave es la
    // misma que usa el storage por defecto (`sb-<ref>-auth-token`) para
    // migrar la sesión ya guardada en SharedPreferences. El code verifier
    // PKCE (`pkceAsyncStorage`) sigue en SharedPreferences: es de un solo
    // uso y de vida corta (reset de contraseña).
    final authOptions = Capabilities.supportsSecureSessionStorage
        ? FlutterAuthClientOptions(
            localStorage: SecureSessionStorage(
              persistSessionKey: sessionStorageKey(url),
            ),
          )
        : const FlutterAuthClientOptions();

    await Supabase.initialize(
      url: url,
      // `anonKey` está deprecado desde supabase_flutter 2.13: el mismo valor
      // (anon key legacy o publishable key `sb_publishable_…`) va en
      // `publishableKey`. El nombre de la variable de entorno no cambia.
      publishableKey: anonKey,
      authOptions: authOptions,
    );
  }

  /// Clave con la que `supabase_flutter` persiste la sesión por defecto
  /// (ver `Supabase.initialize`): `sb-<subdominio del host>-auth-token`.
  static String sessionStorageKey(String url) =>
      'sb-${Uri.parse(url).host.split('.').first}-auth-token';
}
