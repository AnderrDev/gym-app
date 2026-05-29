import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_flutter/core/settings/user_preferences_service.dart';

void main() {
  group('UserPreferencesService', () {
    late SharedPreferences prefs;
    late UserPreferencesService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = UserPreferencesService(prefs);
    });

    test('getThemeMode → ThemeMode.system cuando no hay preferencia', () {
      expect(service.getThemeMode(), ThemeMode.system);
    });

    test('roundtrip light', () async {
      await service.setThemeMode(ThemeMode.light);
      expect(service.getThemeMode(), ThemeMode.light);
    });

    test('roundtrip dark', () async {
      await service.setThemeMode(ThemeMode.dark);
      expect(service.getThemeMode(), ThemeMode.dark);
    });

    test('roundtrip system', () async {
      await service.setThemeMode(ThemeMode.dark);
      await service.setThemeMode(ThemeMode.system);
      expect(service.getThemeMode(), ThemeMode.system);
    });

    test('valor desconocido decae a system', () async {
      // simula data legacy/corrupta en la key
      await prefs.setString('app.theme_mode', 'sepia');
      expect(service.getThemeMode(), ThemeMode.system);
    });
  });
}
