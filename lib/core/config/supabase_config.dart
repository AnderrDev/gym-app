import 'package:flutter_dotenv/flutter_dotenv.dart';
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

    await Supabase.initialize(url: url, anonKey: anonKey);
  }
}
