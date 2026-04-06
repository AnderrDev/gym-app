import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/routine.dart';
import '../../domain/entities/routine_day.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_event.dart';
import '../bloc/workout_state.dart';
import '../widgets/dashboard_active_session_banner.dart';
import '../widgets/dashboard_state_content.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime _currentWeekStart = _getWeekStart(DateTime.now());
  Routine? _selectedRoutine;
  ActiveSessionDetected? _activeSession;
  bool _autoResumeHandled = false;
  WorkoutState? _lastDashboardState;
  bool _autoPlanRequested = false;
  WeeklyPlanLoaded? _cachedWeeklyPlan;

  static DateTime _getWeekStart(DateTime date) {
    // Lunes de la semana actual
    return date.subtract(Duration(days: date.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final workoutBloc = context.read<WorkoutBloc>();
      // Verificar sesión activa
      workoutBloc.add(CheckActiveSession(authState.user.id));

      final currentState = workoutBloc.state;
      if (currentState is RoutinesLoaded && currentState.routines.length == 1) {
        // Optimización: Si ya tenemos una única rutina, cargar el plan sin esperar re-fetch
        _selectedRoutine = currentState.routines.first;
        _loadWeeklyPlan(_selectedRoutine!);
      } else if (currentState is! WeeklyPlanLoaded) {
        // Sólo cargar rutinas si no tenemos ya el plan semanal cargado
        workoutBloc.add(FetchAssignedRoutines(authState.user.id));
      }
    }
  }

  void _resumeActiveSession(ActiveSessionDetected session) {
    context.read<WorkoutBloc>().add(
      LoadDayInfo(
        userId: session.userId,
        routineDayId: session.routineDayId,
        sessionDate: session.sessionDate,
      ),
    );

    final routineDay = RoutineDay(
      id: session.routineDayId,
      routineId: '',
      name: session.routineDayName,
      dayOfWeek: session.sessionDate.weekday,
      exercises: const [],
    );
    context.push(
      AppRoutes.routineDay,
      extra: {
        'routineDay': routineDay,
        'userId': session.userId,
        'sessionDate': session.sessionDate,
      },
    );
  }

  void _loadWeeklyPlan(Routine routine) {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _autoPlanRequested = true;
      setState(() => _selectedRoutine = routine);
      context.read<WorkoutBloc>().add(
        FetchWeeklyPlan(
          userId: authState.user.id,
          routineId: routine.id,
          weekStart: _currentWeekStart,
        ),
      );
    }
  }

  void _changeWeek(int delta) {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: 7 * delta));
    });
    if (_selectedRoutine != null) {
      _loadWeeklyPlan(_selectedRoutine!);
    }
  }

  Future<void> _openRoutineListAndRefresh() async {
    final authState = context.read<AuthBloc>().state;
    final workoutBloc = context.read<WorkoutBloc>();
    final userId = authState is Authenticated ? authState.user.id : null;
    final didChange = await context.push<bool>(AppRoutes.routineList);
    if (!mounted || didChange != true || userId == null) return;
    workoutBloc.add(FetchAssignedRoutines(userId));
  }

  Future<void> _openRoutineEditorAndRefresh() async {
    final authState = context.read<AuthBloc>().state;
    final workoutBloc = context.read<WorkoutBloc>();
    final userId = authState is Authenticated ? authState.user.id : null;
    final routine = _selectedRoutine;
    final didChange = await context.push<bool>(AppRoutes.routineEditor);
    if (!mounted || didChange != true || userId == null) return;
    if (routine != null) {
      workoutBloc.add(
        FetchWeeklyPlan(
          userId: userId,
          routineId: routine.id,
          weekStart: _currentWeekStart,
        ),
      );
    }
  }

  void _openRoutineStats(Routine routine) {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.push(
        AppRoutes.routineStats,
        extra: {
          'userId': authState.user.id,
          'routineId': routine.id,
          'routineName': routine.name,
        },
      );
    }
  }

  void _openSelectedRoutineStats() {
    final routine = _selectedRoutine;
    if (routine != null) {
      _openRoutineStats(routine);
    }
  }

  void _openRoutineDay(RoutineDay routineDay, DateTime date) {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.push(
        AppRoutes.routineDay,
        extra: {
          'routineDay': routineDay,
          'userId': authState.user.id,
          'sessionDate': date,
        },
      );
    }
  }

  bool _isDashboardState(WorkoutState state) {
    return state is WorkoutInitial ||
        state is WorkoutLoading ||
        state is WorkoutError ||
        state is RoutinesLoaded ||
        state is WeeklyPlanLoaded ||
        state is ActiveSessionDetected;
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
            icon: const Icon(Icons.storage, color: AppColors.primary),
            onPressed: () => context.push(AppRoutes.dbInspector),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.primary),
            onPressed: () => context.read<AuthBloc>().add(SignOutRequested()),
          ),
        ],
      ),
      body: BlocConsumer<WorkoutBloc, WorkoutState>(
        listenWhen: (previous, current) =>
            current is ActiveSessionDetected ||
            current is WorkoutFinishedSuccess ||
            current is RoutinesLoaded ||
            current is WeeklyPlanLoaded,
        listener: (context, state) {
          // Sesión activa detectada al abrir app: redirigir automáticamente una sola vez
          if (state is ActiveSessionDetected) {
            if (!mounted) return;
            setState(() => _activeSession = state);
            if (!_autoResumeHandled) {
              _autoResumeHandled = true;
              _resumeActiveSession(state);
            }
          }

          // Entrenamiento finalizado: limpiar banner de sesión activa
          if (state is WorkoutFinishedSuccess) {
            if (!mounted) return;
            setState(() => _activeSession = null);
          }

          if (state is WorkoutFinishedSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Entrenamiento completado!'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 2),
              ),
            );
          }

          // Al recibir las rutinas asignadas, si solo hay una, disparar carga del plan semanal
          if (state is RoutinesLoaded) {
            if (state.routines.length == 1) {
              final routine = state.routines.first;
              final cachedMatches =
                  _cachedWeeklyPlan?.routine?.id == routine.id;
              if (_selectedRoutine?.id != routine.id) {
                if (!mounted) return;
                setState(() => _selectedRoutine = routine);
              }
              if (!cachedMatches) {
                _autoPlanRequested = false;
              }
              if (!_autoPlanRequested || !cachedMatches) {
                _loadWeeklyPlan(routine);
              }
            } else {
              if (!mounted) return;
              _autoPlanRequested = false;
              setState(() => _selectedRoutine = null);
            }
          }

          if (state is WeeklyPlanLoaded) {
            _cachedWeeklyPlan = state;
            if (_selectedRoutine?.id != state.routine?.id) {
              if (!mounted) return;
              setState(() => _selectedRoutine = state.routine);
            }
          }

          if (state is WeeklyPlanLoaded) {
            _cachedWeeklyPlan = state;
          }
        },
        builder: (context, state) {
          final shouldUseCached =
              (state is WorkoutLoading || state is WorkoutInitial) &&
              _lastDashboardState != null;
          final effectiveState = shouldUseCached
              ? _lastDashboardState!
              : (_isDashboardState(state)
                    ? state
                    : (_lastDashboardState ?? state));
          if (_isDashboardState(effectiveState) &&
              effectiveState is! WorkoutLoading &&
              effectiveState is! WorkoutInitial) {
            _lastDashboardState = effectiveState;
          }

          final content = DashboardStateContent(
            effectiveState: effectiveState,
            selectedRoutine: _selectedRoutine,
            cachedWeeklyPlan: _cachedWeeklyPlan,
            onRetryFetchAssignedRoutines: () {
              final authState = context.read<AuthBloc>().state;
              if (authState is Authenticated) {
                context.read<WorkoutBloc>().add(
                  FetchAssignedRoutines(authState.user.id),
                );
              }
            },
            onExploreCatalog: _openRoutineListAndRefresh,
            onCreateRoutine: _openRoutineEditorAndRefresh,
            onSelectRoutine: _loadWeeklyPlan,
            onOpenRoutineStats: _openRoutineStats,
            onPreviousWeek: () => _changeWeek(-1),
            onNextWeek: () => _changeWeek(1),
            onOpenSelectedRoutineStats: _openSelectedRoutineStats,
            onOpenDay: _openRoutineDay,
          );

          return Column(
            children: [
              if (_activeSession != null)
                DashboardActiveSessionBanner(
                  session: _activeSession!,
                  onTap: () => _resumeActiveSession(_activeSession!),
                ),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}
