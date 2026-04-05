import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._privateConstructor();

  static final SupabaseConfig _instance = SupabaseConfig._privateConstructor();

  static SupabaseConfig get instance => _instance;

  static const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  SupabaseClient get client => Supabase.instance.client;

  Future<void> init() async {
    if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
      throw StateError(
        'Missing SUPABASE_URL or SUPABASE_ANON_KEY. '
        'Run with --dart-define SUPABASE_URL=... --dart-define SUPABASE_ANON_KEY=...',
      );
    }
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  }
}
