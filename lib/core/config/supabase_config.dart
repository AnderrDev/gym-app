import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._privateConstructor();

  static final SupabaseConfig _instance = SupabaseConfig._privateConstructor();

  static SupabaseConfig get instance => _instance;

  static const String _supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://benadgxgowycjxypyunc.supabase.co');
  static const String _supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'sb_publishable_keJTLk2DKwhbWxvwx-mm6w_yd-qH-DX');

  SupabaseClient get client => Supabase.instance.client;

  Future<void> init() async {
    if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
      throw StateError(
        'Missing Supabase config. Run with --dart-define=SUPABASE_URL=... and --dart-define=SUPABASE_ANON_KEY=...',
      );
    }

    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  }
}
