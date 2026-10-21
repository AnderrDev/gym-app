import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import 'package:gym_flutter/core/settings/user_preferences_service.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/core/utils/calendar_dates.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_assigned_routines.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_weekly_plan.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/dashboard/dashboard_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/dashboard/dashboard_state.dart';

/// Bloc del subdominio Dashboard: lista de rutinas y plan semanal.
///
/// Reemplaza la responsabilidad equivalente de `WorkoutBloc` (que sigue vivo
/// para los demás subdominios durante el split de Fase 3).
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required this.getAssignedRoutines,
    required this.getWeeklyPlan,
    required this.repository,
    this.preferences,
  }) : super(const DashboardState()) {
    on<LoadAssignedRoutines>(_onLoadAssignedRoutines);
    on<LoadWeeklyPlan>(_onLoadWeeklyPlan);
    on<SelectRoutine>(_onSelectRoutine);
    on<ChangeWeek>(_onChangeWeek);
    on<ClearSelectedRoutine>(
      (_, emit) => emit(
        state.copyWith(clearSelectedRoutine: true, clearErrorMessage: true),
      ),
    );
  }

  final GetAssignedRoutines getAssignedRoutines;
  final GetWeeklyPlan getWeeklyPlan;
  final WorkoutRepository repository;

  /// Recuerda la rutina elegida cuando hay varias. Opcional: sin él el
  /// selector aparece en cada carga.
  final UserPreferencesService? preferences;

  Future<void> _onLoadAssignedRoutines(
    LoadAssignedRoutines event,
    Emitter<DashboardState> emit,
  ) async {
    emit(
      state.copyWith(
        status: DashboardStatus.loadingRoutines,
        clearErrorMessage: true,
      ),
    );
    final result = await getAssignedRoutines(event.userId);
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: DashboardStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
      (routines) async {
        // Si la rutina elegida ya no está asignada (se quitó desde RUTINAS),
        // no se sigue mostrando su plan.
        final selected = state.selectedRoutine;
        final stillAssigned =
            selected != null && routines.any((r) => r.id == selected.id);
        // Auto-load: con una sola rutina, o con varias y una elegida antes
        // en este dispositivo, se carga su plan sin pasar por el selector.
        final keepSelected = selected != null && stillAssigned;
        final lastId = preferences?.getLastRoutineId(event.userId);
        final remembered = routines.length > 1 && !keepSelected
            ? routines.where((r) => r.id == lastId).firstOrNull
            : null;
        final autoRoutine = routines.length == 1 ? routines.first : remembered;
        emit(
          state.copyWith(
            // Con la rutina recordada se pasa directo a "cargando plan": si
            // no, el selector parpadeaba un frame antes del plan.
            status: remembered != null
                ? DashboardStatus.loadingWeeklyPlan
                : DashboardStatus.ready,
            routines: routines,
            clearSelectedRoutine: selected != null && !stillAssigned,
          ),
        );

        if (autoRoutine != null) {
          final weekStart =
              state.weekStart ?? _normalizeWeekStart(DateTime.now());
          add(
            LoadWeeklyPlan(
              userId: event.userId,
              routine: autoRoutine,
              weekStart: weekStart,
            ),
          );
        }
      },
    );
  }

  /// Id de la última carga del plan. Los eventos se procesan en paralelo:
  /// al cambiar de semana rápido, una respuesta lenta llegaba la última y
  /// pisaba los días de la semana que sí se estaba viendo.
  int _planRequest = 0;

  Future<void> _onLoadWeeklyPlan(
    LoadWeeklyPlan event,
    Emitter<DashboardState> emit,
  ) async {
    final request = ++_planRequest;
    final normalized = _normalizeWeekStart(event.weekStart);
    emit(
      state.copyWith(
        status: DashboardStatus.loadingWeeklyPlan,
        selectedRoutine: event.routine,
        weekStart: normalized,
        clearErrorMessage: true,
      ),
    );

    final results = await Future.wait([
      getWeeklyPlan(
        userId: event.userId,
        routineId: event.routine.id,
        weekStart: normalized,
      ),
      repository.getWeeklyInsights(
        routineId: event.routine.id,
        weekStart: normalized,
      ),
      repository.getWeekSessions(
        event.userId,
        normalized,
        AppCalendar.addDays(normalized, 6),
      ),
    ]);

    if (request != _planRequest) return;

    final daysResult = results[0] as Either<Failure, List<RoutineDay>>;
    final insightsResult = results[1] as Either<Failure, WeeklyInsights>;

    if (daysResult.isLeft()) {
      emit(
        state.copyWith(
          status: DashboardStatus.failure,
          errorMessage: daysResult.fold((f) => f.message, (_) => 'Error'),
          // `weekStart` ya apunta a la semana pedida: no se pintan los días
          // de otra semana bajo su rango.
          weeklyDays: const [],
          weekSessions: const [],
        ),
      );
      return;
    }

    final days = daysResult.getOrElse((_) => const []);
    // Best-effort: sólo alimenta el historial; si falla, el historial cae a
    // la última sesión por día.
    final weekSessions = (results[2] as Either<Failure, List<WorkoutSession>>)
        .getOrElse((_) => const []);
    final insights = insightsResult.fold((_) => null, (i) => i);
    final insightsError = insightsResult.fold((f) => f.message, (_) => null);

    emit(
      state.copyWith(
        status: DashboardStatus.ready,
        weeklyDays: days,
        weekSessions: weekSessions,
        insights: insights,
        insightsError: insightsError,
        clearInsights: insights == null,
        clearInsightsError: insightsError == null,
      ),
    );
  }

  Future<void> _onSelectRoutine(
    SelectRoutine event,
    Emitter<DashboardState> emit,
  ) async {
    await preferences?.setLastRoutineId(event.userId, event.routine.id);
    add(
      LoadWeeklyPlan(
        userId: event.userId,
        routine: event.routine,
        weekStart: event.weekStart,
      ),
    );
  }

  Future<void> _onChangeWeek(
    ChangeWeek event,
    Emitter<DashboardState> emit,
  ) async {
    final routine = state.selectedRoutine;
    if (routine == null) {
      emit(state.copyWith(weekStart: _normalizeWeekStart(event.weekStart)));
      return;
    }
    add(
      LoadWeeklyPlan(
        userId: event.userId,
        routine: routine,
        weekStart: event.weekStart,
      ),
    );
  }

  static DateTime _normalizeWeekStart(DateTime date) {
    return AppCalendar.startOfWeek(date);
  }
}
