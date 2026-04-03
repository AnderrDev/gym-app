import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime _currentWeekStart = _getWeekStart(DateTime.now());
  Routine? _selectedRoutine;

  static DateTime _getWeekStart(DateTime date) {
    // Lunes de la semana actual
    return date.subtract(Duration(days: date.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<WorkoutBloc>().add(FetchAssignedRoutines(authState.user.id));
    }
  }

  void _loadWeeklyPlan(Routine routine) {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      setState(() => _selectedRoutine = routine);
      context.read<WorkoutBloc>().add(FetchWeeklyPlan(
        userId: authState.user.id,
        routineId: routine.id,
        weekStart: _currentWeekStart,
      ));
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
          // Al volver de RoutineDayPage, ResetWorkout emite WorkoutInitial.
          // El listener recarga el plan sin tocar el build.
          if (state is WorkoutInitial && _selectedRoutine != null) {
            _loadWeeklyPlan(_selectedRoutine!);
          }
        },
        builder: (context, state) {
          return switch (state) {
            WorkoutInitial() || WorkoutLoading() => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            WorkoutError(message: final msg) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text(msg, textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          final authState = context.read<AuthBloc>().state;
                          if (authState is Authenticated) {
                            context.read<WorkoutBloc>().add(FetchAssignedRoutines(authState.user.id));
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            RoutinesLoaded(routines: final routines) => routines.isEmpty
                ? _buildEmptyState()
                : _buildRoutineSelector(routines),
            WeeklyPlanLoaded(days: final days, weekStart: final weekStart) =>
              _buildWeeklyView(days, weekStart),
            // Cualquier otro estado: mostrar spinner
            // El listener de arriba se encarga de disparar el reload si hay rutina
            _ => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
          };
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
              return Card(
                color: AppColors.surface,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.fitness_center, color: AppColors.primary),
                  ),
                  title: Text(routine.name, style: AppTextStyles.bodyLarge),
                  trailing: const Icon(Icons.calendar_month, color: AppColors.primary),
                  onTap: () => _loadWeeklyPlan(routine),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyView(List<RoutineDay> days, DateTime weekStart) {
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
            border: Border(bottom: BorderSide(color: AppColors.surfaceHighlight)),
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
                      Text(_selectedRoutine!.name,
                          style: AppTextStyles.label.copyWith(color: AppColors.primary)),
                    Text(
                      '${_formatDate(weekStart)} – ${_formatDate(weekEnd)}',
                      style: AppTextStyles.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    if (isCurrentWeek)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Esta semana',
                            style: AppTextStyles.label.copyWith(color: AppColors.primary)),
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
            itemCount: 7,
            itemBuilder: (context, index) {
              final dayOfWeek = index + 1; // 1=Lun, 7=Dom
              final date = weekStart.add(Duration(days: index));
              final routineDay = dayMap[dayOfWeek];
              final isToday = _isToday(date);

              return _buildDayCard(
                dayOfWeek: dayOfWeek,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isToday
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday ? AppColors.primary : AppColors.surfaceHighlight,
          width: isToday ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            : Text('Descanso',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        subtitle: hasWorkout && routineDay.exercises.isNotEmpty
            ? Text('${routineDay.exercises.length} ejercicios',
                style: AppTextStyles.label)
            : null,
        trailing: hasWorkout
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(statusIcon, color: statusColor, size: 24),
                  const SizedBox(height: 2),
                  Text(statusLabel,
                      style: AppTextStyles.label.copyWith(color: statusColor, fontSize: 10)),
                ],
              )
            : null,
        onTap: hasWorkout
            ? () {
                final authState = context.read<AuthBloc>().state;
                if (authState is Authenticated) {
                  context.push('/routine-day', extra: {
                    'routineDay': routineDay,
                    'userId': authState.user.id,
                    'sessionDate': date,
                  });
                }
              }
            : null,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fitness_center, size: 64, color: AppColors.surfaceHighlight),
          const SizedBox(height: 16),
          Text('Aún no tienes rutinas', style: AppTextStyles.heading2),
          const SizedBox(height: 8),
          Text('Crea una nueva rutina para empezar a entrenar.',
              style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/routine-list'),
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text('Ir a Mis Rutinas', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  static String _formatDate(DateTime date) {
    const months = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${date.day} ${months[date.month]}';
  }

  static String _dayShortName(int dayOfWeek) {
    const days = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[dayOfWeek];
  }
}
