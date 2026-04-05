import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/presentation/widgets/glass_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/routine.dart';
import '../../domain/entities/routine_day.dart';
import '../../domain/entities/weekly_insights.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_event.dart';
import '../bloc/workout_state.dart';

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
      '/routine-day',
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
            onPressed: () => context.push('/routine-list'),
          ),
          IconButton(
            icon: const Icon(Icons.storage, color: AppColors.primary),
            onPressed: () => context.push('/db-inspector'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.primary),
            onPressed: () => context.read<AuthBloc>().add(SignOutRequested()),
          ),
        ],
      ),
      body: BlocConsumer<WorkoutBloc, WorkoutState>(
        listener: (context, state) {
          // Sesión activa detectada al abrir app: redirigir automáticamente una sola vez
          if (state is ActiveSessionDetected) {
            setState(() => _activeSession = state);
            if (!_autoResumeHandled) {
              _autoResumeHandled = true;
              _resumeActiveSession(state);
            }
          }

          // Entrenamiento finalizado: limpiar banner de sesión activa
          if (state is WorkoutFinishedSuccess) {
            setState(() => _activeSession = null);
          }

          if (state is ManagementSuccess || state is WorkoutFinishedSuccess) {
            // Mostrar mensaje de éxito si lo hay
            final msg = (state is ManagementSuccess)
                ? state.message
                : '¡Entrenamiento completado!';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
              ),
            );

            // Importante: Si venimos de activar/crear rutina, forzar carga de rutinas asignadas
            final authState = context.read<AuthBloc>().state;
            if (authState is Authenticated) {
              context.read<WorkoutBloc>().add(
                FetchAssignedRoutines(authState.user.id),
              );
            }
            setState(() => _selectedRoutine = null);
          }

          // Al recibir las rutinas asignadas, si solo hay una, disparar carga del plan semanal
          if (state is RoutinesLoaded) {
            if (state.routines.length == 1) {
              _loadWeeklyPlan(state.routines.first);
            }
          }

          // Al recibir respuesta de activación exitosa (obsolescente por el bloque de arriba pero mantenemos por seguridad)
          if (state is ManagementSuccess) {
            setState(() => _selectedRoutine = null);
          }

          // Al volver de RoutineDayPage (ResetWorkout → WorkoutInitial): recargar datos.
          if (state is WorkoutInitial) {
            final authState = context.read<AuthBloc>().state;
            if (authState is Authenticated) {
              context.read<WorkoutBloc>().add(
                FetchAssignedRoutines(authState.user.id),
              );
            }
          }
        },
        builder: (context, state) {
          final content = switch (state) {
            WorkoutInitial() ||
            WorkoutLoading() ||
            SavingSetLog() => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            ActiveSessionDetected() => Center(
              child: Text(
                'Sesión activa detectada, cargando tablero...',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            DayInfoLoaded() || DayWorkoutStarted() => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            WorkoutError(message: final msg) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      msg,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        final authState = context.read<AuthBloc>().state;
                        if (authState is Authenticated) {
                          context.read<WorkoutBloc>().add(
                            FetchAssignedRoutines(authState.user.id),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ManagementSuccess() ||
            WorkoutFinishedSuccess() ||
            SetLogSuccess() => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 48,
                  ),
                  SizedBox(height: 16),
                  CircularProgressIndicator(color: AppColors.primary),
                ],
              ),
            ),
            AllRoutinesLoaded() => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Sincronizando tus rutinas...',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            RoutinesLoaded(routines: final routines) =>
              routines.isEmpty
                  ? _buildEmptyState()
                  : routines.length == 1
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Cargando tu rutina...',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : _buildRoutineSelector(routines),
            WeeklyPlanLoaded(
              days: final days,
              weekStart: final weekStart,
              insights: final insights,
              insightsError: final insightsError,
            ) =>
              _buildWeeklyView(days, weekStart, insights, insightsError),
            // Cualquier otro estado (DayInfoLoaded, DayWorkoutStarted, etc)
            // Si estamos en el Dashboard pero el bloc tiene estado de una sesión,
            // probablemente acabamos de volver. Mostramos un spinner breve mientras recarga.
            _ => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          };

          return Column(
            children: [
              if (_activeSession != null)
                Material(
                  color: AppColors.background,
                  child: InkWell(
                    onTap: () => _resumeActiveSession(_activeSession!),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.timelapse_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Sesion en curso: ${_activeSession!.routineDayName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Text(
                            'Retomar',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoutineSelector(List<Routine> routines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Mis Rutinas', style: AppTextStyles.heading2),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: routines.length,
            itemBuilder: (context, index) {
              final routine = routines[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassContainer(
                  opacity: 0.1,
                  borderRadius: BorderRadius.circular(12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(routine.name, style: AppTextStyles.bodyLarge),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.analytics_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          onPressed: () {
                            final authState = context.read<AuthBloc>().state;
                            if (authState is Authenticated) {
                              context.push(
                                '/routine-stats',
                                extra: {
                                  'userId': authState.user.id,
                                  'routineId': routine.id,
                                  'routineName': routine.name,
                                },
                              );
                            }
                          },
                        ),
                        const Icon(
                          Icons.calendar_month,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    onTap: () => _loadWeeklyPlan(routine),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyView(
    List<RoutineDay> days,
    DateTime weekStart,
    WeeklyInsights? insights,
    String? insightsError,
  ) {
    final isCurrentWeek = _isSameWeek(weekStart, DateTime.now());
    final weekEnd = weekStart.add(const Duration(days: 6));

    // Construir mapa de días con ejercicios: dayOfWeek → RoutineDay
    final dayMap = <int, RoutineDay>{};
    for (final day in days) {
      dayMap[day.dayOfWeek] = day;
    }

    return Column(
      children: [
        // ── Header semanal ─────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.surfaceHighlight),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppColors.primary),
                onPressed: () => _changeWeek(-1),
              ),
              Expanded(
                child: Column(
                  children: [
                    if (_selectedRoutine != null)
                      InkWell(
                        onTap: () {
                          final authState = context.read<AuthBloc>().state;
                          if (authState is Authenticated) {
                            context.push(
                              '/routine-stats',
                              extra: {
                                'userId': authState.user.id,
                                'routineId': _selectedRoutine!.id,
                                'routineName': _selectedRoutine!.name,
                              },
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedRoutine!.name,
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.analytics_outlined,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    Text(
                      '${_formatDate(weekStart)} – ${_formatDate(weekEnd)}',
                      style: AppTextStyles.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (isCurrentWeek)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Esta semana',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppColors.primary),
                onPressed: () => _changeWeek(1),
              ),
            ],
          ),
        ),

        // ── Lista de días ─────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 7 + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildWeeklyInsightsCard(insights, insightsError);
              }

              final dayIndex = index - 1;
              final normalizedDayOfWeek = dayIndex + 1;
              final date = weekStart.add(Duration(days: dayIndex));
              final routineDay = dayMap[normalizedDayOfWeek];
              final isToday = _isToday(date);

              return _buildDayCard(
                dayOfWeek: normalizedDayOfWeek,
                date: date,
                routineDay: routineDay,
                isToday: isToday,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyInsightsCard(
    WeeklyInsights? insights,
    String? insightsError,
  ) {
    if (insightsError != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceHighlight),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No se pudieron cargar insights esta semana. El plan sigue disponible.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (insights == null) {
      return const SizedBox.shrink();
    }

    final trendColor = insights.volumeTrendPercent >= 0
        ? AppColors.success
        : AppColors.error;
    final trendLabel = insights.volumeTrendPercent >= 0
        ? '+${insights.volumeTrendPercent.toStringAsFixed(1)}%'
        : '${insights.volumeTrendPercent.toStringAsFixed(1)}%';

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: BorderRadius.circular(12),
      opacity: 0.08,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.insights, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text('Insights semanales', style: AppTextStyles.bodyLarge),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _metricChip(
                  'Adherencia',
                  '${insights.adherenceRate.toStringAsFixed(0)}%',
                ),
                _metricChip('Sesiones', '${insights.completedSessions}'),
                _metricChip(
                  'Volumen',
                  '${insights.totalVolume.toStringAsFixed(0)} kg',
                ),
                _metricChip('Tendencia', trendLabel, valueColor: trendColor),
                _metricChip('PRs', '${insights.personalRecords}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricChip(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard({
    required int dayOfWeek,
    required DateTime date,
    required RoutineDay? routineDay,
    required bool isToday,
  }) {
    final hasWorkout = routineDay != null;
    final status = routineDay?.status ?? WorkoutDayStatus.rest;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (status) {
      case WorkoutDayStatus.completed:
        statusColor = const Color(0xFF4CAF50);
        statusIcon = Icons.check_circle;
        statusLabel = 'Completado';
        break;
      case WorkoutDayStatus.completedPartial:
        statusColor = const Color(0xFFFF9800);
        statusIcon = Icons.check_circle_outline;
        statusLabel = 'Completado parcial';
        break;
      case WorkoutDayStatus.inProgress:
        statusColor = AppColors.primary;
        statusIcon = Icons.play_circle;
        statusLabel = 'En progreso';
        break;
      case WorkoutDayStatus.pending:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.radio_button_unchecked;
        statusLabel = 'Pendiente';
        break;
      case WorkoutDayStatus.rest:
        statusColor = AppColors.surfaceHighlight;
        statusIcon = Icons.hotel;
        statusLabel = 'Descanso';
        break;
    }

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 10),
      borderRadius: BorderRadius.circular(12),
      opacity: isToday ? 0.2 : 0.05,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday ? AppColors.primary : Colors.transparent,
            width: isToday ? 1.5 : 0,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _dayShortName(dayOfWeek),
                style: AppTextStyles.label.copyWith(
                  color: isToday ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${date.day}',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isToday ? AppColors.primary : AppColors.textPrimary,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          title: hasWorkout
              ? Text(routineDay.name, style: AppTextStyles.bodyLarge)
              : Text(
                  'Descanso',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
          subtitle: hasWorkout && routineDay.exercises.isNotEmpty
              ? Text(
                  '${routineDay.exercises.length} ejercicios',
                  style: AppTextStyles.label,
                )
              : null,
          trailing: hasWorkout
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 24),
                    const SizedBox(height: 2),
                    Text(
                      statusLabel,
                      style: AppTextStyles.label.copyWith(
                        color: statusColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                )
              : null,
          onTap: hasWorkout
              ? () {
                  final authState = context.read<AuthBloc>().state;
                  if (authState is Authenticated) {
                    context.push(
                      '/routine-day',
                      extra: {
                        'routineDay': routineDay,
                        'userId': authState.user.id,
                        'sessionDate': date,
                      },
                    );
                  }
                }
              : null,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.explore_off_rounded,
            size: 64,
            color: AppColors.surfaceHighlight,
          ),
          const SizedBox(height: 16),
          Text('Sin Rutina Activa', style: AppTextStyles.heading2),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Para empezar a entrenar, elige una rutina del catálogo o crea la tuya propia.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.push('/routine-list'),
            icon: const Icon(Icons.explore_rounded, color: Colors.black),
            label: const Text(
              'EXPLORAR CATÁLOGO',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.push('/routine-editor'),
            child: Text(
              'CREAR RUTINA MANUALMENTE',
              style: AppTextStyles.label.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────
  static bool _isSameWeek(DateTime a, DateTime b) {
    final startA = _getWeekStart(a);
    final startB = _getWeekStart(b);
    return startA.year == startB.year &&
        startA.month == startB.month &&
        startA.day == startB.day;
  }

  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static String _formatDate(DateTime date) {
    const months = [
      '',
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${date.day} ${months[date.month]}';
  }

  static String _dayShortName(int dayOfWeek) {
    const days = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[dayOfWeek];
  }
}
