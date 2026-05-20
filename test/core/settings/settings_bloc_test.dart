import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_flutter/core/settings/presentation/settings_bloc.dart';
import 'package:gym_flutter/core/settings/user_preferences_service.dart';

void main() {
  group('SettingsBloc', () {
    late UserPreferencesService prefs;

    Future<UserPreferencesService> makePrefs([
      Map<String, Object> initial = const {},
    ]) async {
      SharedPreferences.setMockInitialValues(initial);
      final sp = await SharedPreferences.getInstance();
      return UserPreferencesService(sp);
    }

    test('estado inicial respeta la preferencia persistida', () async {
      prefs = await makePrefs({'app.theme_mode': 'dark'});
      final bloc = SettingsBloc(preferences: prefs);
      expect(bloc.state.themeMode, ThemeMode.dark);
      await bloc.close();
    });

    test('estado inicial = system cuando no hay preferencia', () async {
      prefs = await makePrefs();
      final bloc = SettingsBloc(preferences: prefs);
      expect(bloc.state.themeMode, ThemeMode.system);
      await bloc.close();
    });

    test('SettingsThemeModeChanged actualiza estado y persistencia', () async {
      prefs = await makePrefs();
      final bloc = SettingsBloc(preferences: prefs);

      final emitted = <ThemeMode>[];
      final sub = bloc.stream.listen((s) => emitted.add(s.themeMode));

      bloc.add(const SettingsThemeModeChanged(ThemeMode.dark));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const SettingsThemeModeChanged(ThemeMode.light));
      await Future<void>.delayed(Duration.zero);

      expect(emitted, [ThemeMode.dark, ThemeMode.light]);
      expect(prefs.getThemeMode(), ThemeMode.light);

      await sub.cancel();
      await bloc.close();
    });

    test('no emite cuando el modo es el mismo', () async {
      prefs = await makePrefs({'app.theme_mode': 'dark'});
      final bloc = SettingsBloc(preferences: prefs);

      final emitted = <ThemeMode>[];
      final sub = bloc.stream.listen((s) => emitted.add(s.themeMode));

      bloc.add(const SettingsThemeModeChanged(ThemeMode.dark));
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      await sub.cancel();
      await bloc.close();
    });

    test('SettingsLoaded re-hidrata desde la storage', () async {
      prefs = await makePrefs();
      final bloc = SettingsBloc(preferences: prefs);
      expect(bloc.state.themeMode, ThemeMode.system);

      // Simula un cambio externo a la storage (otro proceso, otra tab web).
      await prefs.setThemeMode(ThemeMode.dark);
      bloc.add(const SettingsLoaded());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.themeMode, ThemeMode.dark);
      await bloc.close();
    });
  });
}
