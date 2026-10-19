import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/settings/user_preferences_service.dart';

// ── Events ──────────────────────────────────────────────────────────────────

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => const [];
}

/// Hidrata el estado desde `UserPreferencesService` al arrancar la app.
class SettingsLoaded extends SettingsEvent {
  const SettingsLoaded();
}

/// El usuario eligió un `ThemeMode` distinto desde la UI.
class SettingsThemeModeChanged extends SettingsEvent {
  const SettingsThemeModeChanged(this.mode);
  final ThemeMode mode;

  @override
  List<Object?> get props => [mode];
}

// ── State ───────────────────────────────────────────────────────────────────

class SettingsState extends Equatable {
  const SettingsState({this.themeMode = ThemeMode.system});

  final ThemeMode themeMode;

  SettingsState copyWith({ThemeMode? themeMode}) =>
      SettingsState(themeMode: themeMode ?? this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

// ── Bloc ────────────────────────────────────────────────────────────────────

/// Estado global de preferencias de UI. `MaterialApp.router` lo escucha vía
/// `BlocBuilder` para resolver `themeMode`. Lifetime-bound a la app (lazy
/// singleton en DI) — la elección sobrevive al swap de pantallas.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({required UserPreferencesService preferences})
    : _preferences = preferences,
      super(SettingsState(themeMode: preferences.getThemeMode())) {
    on<SettingsLoaded>(_onLoaded);
    on<SettingsThemeModeChanged>(_onThemeModeChanged);
  }

  final UserPreferencesService _preferences;

  void _onLoaded(SettingsLoaded event, Emitter<SettingsState> emit) {
    emit(state.copyWith(themeMode: _preferences.getThemeMode()));
  }

  Future<void> _onThemeModeChanged(
    SettingsThemeModeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (event.mode == state.themeMode) return;
    emit(state.copyWith(themeMode: event.mode));
    await _preferences.setThemeMode(event.mode);
  }
}
