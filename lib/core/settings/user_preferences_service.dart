import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia de preferencias del usuario que viven en el dispositivo
/// (theme mode, próximamente: idioma, unidades). Cross-device sync vendría
/// en un follow-up sobre la tabla `profiles.preferences` (jsonb).
class UserPreferencesService {
  UserPreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static const _kThemeMode = 'app.theme_mode';

  /// Lee el `ThemeMode` persistido. Default `ThemeMode.system` cuando no hay
  /// preferencia almacenada (primera vez, o tras logout limpio).
  ThemeMode getThemeMode() {
    final raw = _prefs.getString(_kThemeMode);
    return _decodeThemeMode(raw);
  }

  /// Persiste el `ThemeMode`. No falla — si SharedPreferences está bloqueado
  /// (Safari privado en web, por ejemplo) el bootstrap ya habría fallado más
  /// arriba.
  Future<void> setThemeMode(ThemeMode mode) =>
      _prefs.setString(_kThemeMode, _encodeThemeMode(mode));

  static String _encodeThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
    }
  }

  static ThemeMode _decodeThemeMode(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
