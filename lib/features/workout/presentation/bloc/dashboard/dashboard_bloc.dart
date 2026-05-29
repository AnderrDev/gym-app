import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import 'package:gym_flutter/core/error/failures.dart';
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
  }) : super(const DashboardState()) {
    on<LoadAssignedRoutines>(_onLoadAssignedRoutines);
    on<LoadWeeklyPlan>(_onLoadWeeklyPlan);
    on<SelectRoutine>(_onSelectRoutine);
    on<ChangeWeek>(_onChangeWeek);
  }

  final GetAssignedRoutines getAssignedRoutines;
  final GetWeeklyPlan getWeeklyPlan;
  final WorkoutRepository repository;

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
        emit(state.copyWith(status: DashboardStatus.ready, routines: routines));

        // Auto-load: si el usuario tiene exactamente una rutina, prefetch su
        // plan semanal para evitar mostrar un selector innecesario.
        if (routines.length == 1) {
          final only = routines.first;
          final weekStart =
              state.weekStart ?? _normalizeWeekStart(DateTime.now());
          add(
            LoadWeeklyPlan(
              userId: event.userId,
              routine: only,
              weekStart: weekStart,
            ),
          );
        }
      },
    );
  }

  Future<void> _onLoadWeeklyPlan(
    LoadWeeklyPlan event,
    Emitter<DashboardState> emit,
  ) async {
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
    ]);

    final daysResult = results[0] as Either<Failure, List<RoutineDay>>;
    final insightsResult = results[1] as Either<Failure, WeeklyInsights>;

    if (daysResult.isLeft()) {
      emit(
        state.copyWith(
          status: DashboardStatus.failure,
          errorMessage: daysResult.fold((f) => f.message, (_) => 'Error'),
        ),
      );
      return;
    }

    final days = daysResult.getOrElse((_) => const []);
    final insights = insightsResult.fold((_) => null, (i) => i);
    final insightsError = insightsResult.fold((f) => f.message, (_) => null);

    emit(
      state.copyWith(
        status: DashboardStatus.ready,
        weeklyDays: days,
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
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - 1));
  }
}
