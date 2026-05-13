import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/routes/args/routing_args.dart';
import 'package:gym_flutter/core/routes/router_helpers.dart';
import 'package:gym_flutter/core/ui/feedback/app_snack_bar.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_session_watcher/active_session_watcher_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_session_watcher/active_session_watcher_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_session_watcher/active_session_watcher_state.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/dashboard/dashboard_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/dashboard/dashboard_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/dashboard/dashboard_state.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_active_session_banner.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_state_content.dart';

/// Página de Dashboard.
///
/// Consume `DashboardBloc` para listas/plan y `ActiveSessionWatcherBloc` para
/// el banner de "reanudar". El final de una sesión se sabe vía el resultado
/// del `context.push(AppRoutes.routineDay)` (la página de routine_day pop-ea
/// con `true` cuando finaliza).
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static DateTime _weekStartOf(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) return;
      context.read<DashboardBloc>().add(
        LoadAssignedRoutines(authState.user.id),
      );
      context.read<ActiveSessionWatcherBloc>().add(
        CheckActiveSession(authState.user.id),
      );
    });
  }

  Future<void> _resumeActiveSession(ActiveSessionInfo info) async {
    final routineDay = RoutineDay(
      id: info.routineDayId,
      routineId: '',
      name: info.routineDayName,
      dayOfWeek: info.sessionDate.weekday,
      exercises: const [],
    );
    final didFinish = await pushRoutineDay(
      context,
      RoutineDayArgs(
        routineDay: routineDay,
        userId: info.userId,
        sessionDate: info.sessionDate,
      ),
    );
    if (!mounted) return;
    if (didFinish == true) {
      _handleWorkoutFinished(info.userId);
    }
  }

  void _handleWorkoutFinished(String userId) {
    context.read<ActiveSessionWatcherBloc>().add(const ClearActiveSession());
    final dashboardState = context.read<DashboardBloc>().state;
    final routine = dashboardState.selectedRoutine;
    final weekStart = dashboardState.weekStart;
    if (routine != null && weekStart != null) {
      context.read<DashboardBloc>().add(
        LoadWeeklyPlan(
          userId: userId,
          routine: routine,
          weekStart: weekStart,
        ),
      );
    }
    AppSnackBar.success(context, '¡Entrenamiento completado!');
  }

  void _onSelectRoutine(Routine routine) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;
    final dashState = context.read<DashboardBloc>().state;
    final weekStart = dashState.weekStart ?? _weekStartOf(DateTime.now());
    context.read<DashboardBloc>().add(
      SelectRoutine(
        userId: authState.user.id,
        routine: routine,
        weekStart: weekStart,
      ),
    );
  }

  void _changeWeek(int delta) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;
    final dashState = context.read<DashboardBloc>().state;
    final base = dashState.weekStart ?? _weekStartOf(DateTime.now());
    context.read<DashboardBloc>().add(
      ChangeWeek(
        userId: authState.user.id,
        weekStart: base.add(Duration(days: 7 * delta)),
      ),
    );
  }

  Future<void> _openRoutineListAndRefresh() async {
    final authState = context.read<AuthBloc>().state;
    final dashboardBloc = context.read<DashboardBloc>();
    final userId = authState is Authenticated ? authState.user.id : null;
    final didChange = await pushRoutineList(context);
    if (!mounted || didChange != true || userId == null) return;
    dashboardBloc.add(LoadAssignedRoutines(userId));
  }

  Future<void> _openRoutineEditorAndRefresh() async {
    final authState = context.read<AuthBloc>().state;
    final dashboardBloc = context.read<DashboardBloc>();
    final userId = authState is Authenticated ? authState.user.id : null;
    final didChange = await pushRoutineEditor(context);
    if (!mounted || didChange != true || userId == null) return;
    final selected = dashboardBloc.state.selectedRoutine;
    if (selected != null) {
      dashboardBloc.add(
        LoadWeeklyPlan(
          userId: userId,
          routine: selected,
          weekStart:
              dashboardBloc.state.weekStart ?? _weekStartOf(DateTime.now()),
        ),
      );
    } else {
      dashboardBloc.add(LoadAssignedRoutines(userId));
    }
  }

  void _openRoutineStats(Routine routine) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;
    pushRoutineStats(
      context,
      RoutineStatsArgs(
        userId: authState.user.id,
        routineId: routine.id,
        routineName: routine.name,
      ),
    );
  }

  void _openSelectedRoutineStats() {
    final routine = context.read<DashboardBloc>().state.selectedRoutine;
    if (routine != null) _openRoutineStats(routine);
  }

  Future<void> _openRoutineDay(RoutineDay routineDay, DateTime date) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;
    final didFinish = await pushRoutineDay(
      context,
      RoutineDayArgs(
        routineDay: routineDay,
        userId: authState.user.id,
        sessionDate: date,
      ),
    );
    if (!mounted) return;
    if (didFinish == true) {
      _handleWorkoutFinished(authState.user.id);
    }
  }

  void _retryLoadRoutines() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;
    context.read<DashboardBloc>().add(LoadAssignedRoutines(authState.user.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Smart Gym Tracker', style: AppTextStyles.heading2),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt, color: AppColors.primary),
            onPressed: _openRoutineListAndRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.primary),
            onPressed: () => context.read<AuthBloc>().add(SignOutRequested()),
          ),
        ],
      ),
      // Antes había un auto-resume aquí que disparaba `_resumeActiveSession`
      // apenas el watcher detectaba una sesión activa. Esto creaba un loop
      // si la vista activa crasheaba: cada relaunch te metía de vuelta a la
      // pantalla rota sin oportunidad de salir. Ahora el usuario tiene que
      // tap-ear el banner para volver al workout.
      body: Column(
          children: [
            // El banner solo se rebuildea cuando cambia la sesión activa —
            // ningún cambio del DashboardBloc lo dispara.
            BlocSelector<
              ActiveSessionWatcherBloc,
              ActiveSessionWatcherState,
              ActiveSessionInfo?
            >(
              selector: (state) =>
                  state.hasActiveSession ? state.session : null,
              builder: (context, session) {
                if (session == null) return const SizedBox.shrink();
                return DashboardActiveSessionBanner(
                  session: session,
                  onTap: () => _resumeActiveSession(session),
                );
              },
            ),
            Expanded(
              child: BlocBuilder<DashboardBloc, DashboardState>(
                builder: (context, dashState) {
                  return DashboardStateContent(
                    state: dashState,
                    onRetry: _retryLoadRoutines,
                    onExploreCatalog: _openRoutineListAndRefresh,
                    onCreateRoutine: _openRoutineEditorAndRefresh,
                    onSelectRoutine: _onSelectRoutine,
                    onOpenRoutineStats: _openRoutineStats,
                    onPreviousWeek: () => _changeWeek(-1),
                    onNextWeek: () => _changeWeek(1),
                    onOpenSelectedRoutineStats: _openSelectedRoutineStats,
                    onOpenDay: _openRoutineDay,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
