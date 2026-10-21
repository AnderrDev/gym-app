import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/config/supabase_config.dart';

void main() {
  test(
    'sessionStorageKey coincide con la clave por defecto de supabase_flutter',
    () {
      expect(
        SupabaseConfig.sessionStorageKey('https://abcdefgh.supabase.co'),
        'sb-abcdefgh-auth-token',
      );
    },
  );
}
