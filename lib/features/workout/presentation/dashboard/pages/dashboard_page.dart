import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/routes/args/routing_args.dart';
import 'package:gym_flutter/core/routes/router_helpers.dart';
import 'package:gym_flutter/core/ui/feedback/app_snack_bar.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_session_watcher/active_session_watcher_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_session_watcher/active_session_watcher_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/dashboard/dashboard_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/dashboard/dashboard_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/dashboard/dashboard_state.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_state_content.dart';
import 'package:gym_flutter/injection_container.dart';
import 'package:gym_flutter/core/services/routine_assignment_bus.dart';

/// Página de Dashboard ("HOY") — primer branch del shell con NavigationBar.
///
/// El banner de "sesión activa" y la AppBar action de cerrar sesión vivían
/// acá originalmente; ahora viven en el shell / en la pestaña PERFIL. Esto
/// permite que cualquier branch muestre el banner y elimina los 2
/// `IconButton` de la AppBar (lista + logout) que ya no tienen lugar con
/// la NavigationBar inferior.
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

  late final RoutineAssignmentBus _assignmentBus;

  /// True una vez que disparamos `LoadAssignedRoutines` por primera vez.
  /// En web reload el `AuthBloc` empieza en `AuthInitial` mientras Supabase
  /// restaura la sesión desde `localStorage` (1-2 frames). El `initState`
  /// corre antes y la lectura síncrona de `AuthBloc.state` salía sin
  /// disparar nada. El `BlocListener` del build cubre ese race; el flag
  /// evita duplicar el load cuando auth ya estaba listo al montar.
  bool _initialLoadDispatched = false;

  @override
  void initState() {
    super.initState();
    _assignmentBus = sl<RoutineAssignmentBus>()..addListener(_onAssignmentBump);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) return;
      _initialLoadDispatched = true;
      context.read<DashboardBloc>().add(
        LoadAssignedRoutines(authState.user.id),
      );
    });
  }

  @override
  void dispose() {
    _assignmentBus.removeListener(_onAssignmentBump);
    super.dispose();
  }

  /// Re-dispara `LoadAssignedRoutines` cuando otro bloc (típicamente el de
  /// gestión de rutinas en otra branch del shell) avisa que hubo un cambio
  /// en `user_routines`. Bus singleton porque cada GoRoute crea su propia
  /// instancia de `RoutineManagementBloc` y un BlocListener directo no las
  /// alcanza cross-route.
  void _onAssignmentBump() {
    if (!mounted) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;
    context.read<DashboardBloc>().add(LoadAssignedRoutines(authState.user.id));
  }

  void _handleWorkoutFinished(String userId) {
    // El watcher vive en el shell, así que lo buscamos arriba en el árbol
    // (sigue siendo accesible vía `BlocProvider` ancestral).
    context.read<ActiveSessionWatcherBloc>().add(const ClearActiveSession());
    final dashboardState = context.read<DashboardBloc>().state;
    final routine = dashboardState.selectedRoutine;
    final weekStart = dashboardState.weekStart;
    if (routine != null && weekStart != null) {
      context.read<DashboardBloc>().add(
        LoadWeeklyPlan(userId: userId, routine: routine, weekStart: weekStart),
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
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          !_initialLoadDispatched && curr is Authenticated,
      listener: (context, authState) {
        if (!mounted || authState is! Authenticated) return;
        _initialLoadDispatched = true;
        context.read<DashboardBloc>().add(
          LoadAssignedRoutines(authState.user.id),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text('Smart Gym Tracker', style: context.text.headlineMedium),
        ),
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, dashState) {
            return DashboardStateContent(
              state: dashState,
              onRetry: _retryLoadRoutines,
              // El catálogo de rutinas ahora vive en la pestaña RUTINAS — el
              // CTA del empty state cambia de tab en vez de pushar una ruta.
              onExploreCatalog: () => goToRoutines(context),
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
    );
  }
}
