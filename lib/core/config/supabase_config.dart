import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._privateConstructor();

  static final SupabaseConfig _instance = SupabaseConfig._privateConstructor();

  static SupabaseConfig get instance => _instance;

  // TODO: Replace with your actual Supabase Project URL and Anon Key
  static const String _supabaseUrl = 'https://benadgxgowycjxypyunc.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJlbmFkZ3hnb3d5Y2p4eXB5dW5jIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkwOTA0NjIsImV4cCI6MjA4NDY2NjQ2Mn0.V48BMkMPtYrtTymMMLYn4P0VEGOLhaCftBSg0283rWI';

  SupabaseClient get client => Supabase.instance.client;

  Future<void> init() async {
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  }
}
