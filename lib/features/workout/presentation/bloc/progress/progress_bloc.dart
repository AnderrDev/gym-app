import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/utils/calendar_dates.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_assigned_routines.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/progress/progress_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/progress/progress_state.dart';

/// Bloc del hub `/progress` (pestaña PROGRESO).
///
/// Orquesta dos fetches en paralelo:
///  1. Rutinas asignadas → vía `GetAssignedRoutines` use case (consistente
///     con `DashboardBloc`).
///  2. Insights semanales → vía repo directo (`getWeeklyInsights`), igual que
///     `DashboardBloc` que tampoco tiene use case dedicado para esto.
///
/// `getWeeklyInsights` requiere `routineId`, no `userId`. Decisión: usar la
/// primera rutina asignada del usuario como proxy del "weekly snapshot".
/// Si el usuario tiene 0 rutinas no hay insights que mostrar.
class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  ProgressBloc({required this.getAssignedRoutines, required this.repository})
    : super(const ProgressInitial()) {
    on<LoadProgress>(_onLoad);
    on<RefreshProgress>(_onRefresh);
  }

  final GetAssignedRoutines getAssignedRoutines;
  final WorkoutRepository repository;

  Future<void> _onLoad(LoadProgress event, Emitter<ProgressState> emit) async {
    emit(const ProgressLoading());
    await _fetchAndEmit(
      userId: event.userId,
      weekStart: event.weekStart,
      emit: emit,
    );
  }

  Future<void> _onRefresh(
    RefreshProgress event,
    Emitter<ProgressState> emit,
  ) async {
    // NO emit Loading — refresh silencioso (la UI sigue mostrando el último
    // Ready hasta que llegue el siguiente Ready/Failure).
    await _fetchAndEmit(
      userId: event.userId,
      weekStart: event.weekStart,
      emit: emit,
    );
  }

  Future<void> _fetchAndEmit({
    required String userId,
    required DateTime? weekStart,
    required Emitter<ProgressState> emit,
  }) async {
    final normalizedStart = _normalizeWeekStart(weekStart ?? DateTime.now());
    final weekEnd = AppCalendar.addDays(normalizedStart, 6);

    // 1) Fetch rutinas asignadas. Si esto falla, no podemos pintar nada
    // (el hub depende de saber qué rutinas tiene el user incluso para
    // saber si pedir insights). → ProgressFailure.
    final routinesResult = await getAssignedRoutines(userId);
    if (routinesResult.isLeft()) {
      emit(
        ProgressFailure(
          routinesResult.fold((f) => f.message, (_) => 'Error desconocido'),
        ),
      );
      return;
    }
    final routines = routinesResult.getOrElse((_) => const <Routine>[]);

    // 2) Insights de TODAS las rutinas asignadas, sumados: "esta semana" es
    // todo lo entrenado, no sólo la primera rutina. Si alguna falla, NO tumba
    // el hub — se pinta lo que llegó y se guarda el error para la microalerta.
    WeeklyInsights? insights;
    String? insightsError;
    var exercises = const <Exercise>[];
    if (routines.isNotEmpty) {
      exercises = await _exercisesOf(routines);
      final results = await Future.wait(
        routines.map(
          (r) => repository.getWeeklyInsights(
            routineId: r.id,
            weekStart: normalizedStart,
          ),
        ),
      );
      final ok = [
        for (final r in results)
          ...r.fold((_) => <WeeklyInsights>[], (i) => [i]),
      ];
      insights = ok.isEmpty ? null : combineWeeklyInsights(ok);
      insightsError = results
          .map((r) => r.fold((f) => f.message, (_) => null))
          .nonNulls
          .firstOrNull;
    }

    emit(
      ProgressReady(
        weekStart: normalizedStart,
        weekEnd: weekEnd,
        routines: routines,
        insights: insights,
        insightsError: insightsError,
        exercises: exercises,
      ),
    );
  }

  /// Ejercicios únicos de las rutinas, ordenados por nombre. Un fallo no
  /// tumba el hub: esa rutina simplemente no aporta ejercicios.
  Future<List<Exercise>> _exercisesOf(List<Routine> routines) async {
    final results = await Future.wait(
      routines.map((r) => repository.getRoutineDays(r.id)),
    );
    final byId = <String, Exercise>{};
    for (final result in results) {
      for (final day in result.getOrElse((_) => const [])) {
        for (final ex in day.exercises) {
          byId.putIfAbsent(ex.id, () => ex);
        }
      }
    }
    return byId.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  /// Normaliza una fecha al lunes 00:00 local de su semana. Igual que el
  /// helper privado de `DashboardBloc` — duplicado a propósito para no
  /// crear acoplamiento entre dos blocs distintos.
  static DateTime _normalizeWeekStart(DateTime date) {
    return AppCalendar.startOfWeek(date);
  }
}

/// Suma los insights de varias rutinas de la misma semana. Los porcentajes se
/// recalculan sobre los totales (no se promedian) con la misma convención que
/// `compute_weekly_insights_v1`.
@visibleForTesting
WeeklyInsights combineWeeklyInsights(List<WeeklyInsights> all) {
  if (all.length == 1) return all.single;
  var planned = 0, completedDays = 0, sessions = 0, prs = 0;
  var volume = 0.0, previous = 0.0;
  for (final i in all) {
    planned += i.plannedDays;
    completedDays += i.completedDays;
    sessions += i.completedSessions;
    prs += i.personalRecords;
    volume += i.totalVolume;
    previous += i.previousWeekVolume;
  }
  final double trend = previous <= 0
      ? (volume > 0 ? 100 : 0)
      : (volume - previous) / previous * 100;
  return WeeklyInsights(
    weekStart: all.first.weekStart,
    weekEnd: all.first.weekEnd,
    plannedDays: planned,
    completedDays: completedDays,
    completedSessions: sessions,
    adherenceRate: planned == 0 ? 0 : completedDays / planned * 100,
    totalVolume: volume,
    previousWeekVolume: previous,
    volumeTrendPercent: trend,
    personalRecords: prs,
  );
}
