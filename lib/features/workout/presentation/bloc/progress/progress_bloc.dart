import 'package:flutter_bloc/flutter_bloc.dart';

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
    final weekEnd = normalizedStart.add(const Duration(days: 6));

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

    // 2) Fetch insights de la primera rutina si existe. Si falla, NO tumba
    // el hub — guardamos el error para mostrar microalerta inline.
    WeeklyInsights? insights;
    String? insightsError;
    if (routines.isNotEmpty) {
      final insightsResult = await repository.getWeeklyInsights(
        routineId: routines.first.id,
        weekStart: normalizedStart,
      );
      insights = insightsResult.fold((_) => null, (i) => i);
      insightsError = insightsResult.fold((f) => f.message, (_) => null);
    }

    emit(
      ProgressReady(
        weekStart: normalizedStart,
        weekEnd: weekEnd,
        routines: routines,
        insights: insights,
        insightsError: insightsError,
      ),
    );
  }

  /// Normaliza una fecha al lunes 00:00 local de su semana. Igual que el
  /// helper privado de `DashboardBloc` — duplicado a propósito para no
  /// crear acoplamiento entre dos blocs distintos.
  static DateTime _normalizeWeekStart(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - 1));
  }
}
