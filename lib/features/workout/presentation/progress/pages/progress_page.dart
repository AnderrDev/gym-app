import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/routes/args/routing_args.dart';
import 'package:gym_flutter/core/routes/router_helpers.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/feedback/barbell_loader.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/progress/progress_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/progress/progress_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/progress/progress_state.dart';

/// Hub `/progress` (pestaña PROGRESO del shell).
///
/// Dos secciones: (1) métricas de la semana en curso, (2) lista de rutinas
/// asignadas que enlazan a `/routine-stats`. Sin gráficos por ahora —
/// el desglose por sesión/ejercicio vive una pantalla más abajo.
class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) return;
      context.read<ProgressBloc>().add(LoadProgress(authState.user.id));
    });
  }

  String? _currentUserId() {
    final authState = context.read<AuthBloc>().state;
    return authState is Authenticated ? authState.user.id : null;
  }

  void _retry() {
    final userId = _currentUserId();
    if (userId == null) return;
    context.read<ProgressBloc>().add(LoadProgress(userId));
  }

  Future<void> _onRefresh() async {
    final userId = _currentUserId();
    if (userId == null) return;
    final bloc = context.read<ProgressBloc>();
    final completer = Completer<void>();
    // Escuchamos hasta el próximo estado terminal (Ready o Failure) y ahí
    // resolvemos el future del RefreshIndicator. Limitado a 10s por las
    // dudas — el indicador se queda colgado eternamente si el bloc nunca
    // emite (no debería pasar pero defensive).
    late final StreamSubscription<ProgressState> sub;
    sub = bloc.stream.listen((state) {
      if (state is ProgressReady || state is ProgressFailure) {
        if (!completer.isCompleted) completer.complete();
        sub.cancel();
      }
    });
    bloc.add(RefreshProgress(userId));
    await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => sub.cancel(),
    );
  }

  void _openRoutineStats(Routine routine) {
    final userId = _currentUserId();
    if (userId == null) return;
    pushRoutineStats(
      context,
      RoutineStatsArgs(
        userId: userId,
        routineId: routine.id,
        routineName: routine.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'PROGRESO',
          style: AppTextStyles.heading2.copyWith(letterSpacing: 2),
        ),
      ),
      body: BlocBuilder<ProgressBloc, ProgressState>(
        builder: (context, state) {
          return switch (state) {
            ProgressInitial() || ProgressLoading() => const Center(
              child: BarbellLoader.medium(),
            ),
            ProgressFailure(:final message) => _ProgressErrorView(
              message: message,
              onRetry: _retry,
            ),
            ProgressReady() => RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.primary,
              child: _ProgressReadyView(
                state: state,
                onOpenRoutine: _openRoutineStats,
                onGoToRoutines: () => goToRoutines(context),
              ),
            ),
          };
        },
      ),
    );
  }
}

// ── Failure view ───────────────────────────────────────────────────────────

class _ProgressErrorView extends StatelessWidget {
  const _ProgressErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: Spacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: Spacing.lg),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(
                'REINTENTAR',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.onPrimary,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ready view ─────────────────────────────────────────────────────────────

class _ProgressReadyView extends StatelessWidget {
  const _ProgressReadyView({
    required this.state,
    required this.onOpenRoutine,
    required this.onGoToRoutines,
  });

  final ProgressReady state;
  final ValueChanged<Routine> onOpenRoutine;
  final VoidCallback onGoToRoutines;

  @override
  Widget build(BuildContext context) {
    // `AlwaysScrollableScrollPhysics` es necesario para que el
    // `RefreshIndicator` funcione cuando el contenido no llena la pantalla
    // (empty state, error de insights, etc).
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.lg,
        Spacing.xl,
        Spacing.xxl + 80,
      ),
      children: [
        _WeekRangeLabel(weekStart: state.weekStart, weekEnd: state.weekEnd),
        const SizedBox(height: Spacing.xs),
        const _SectionTitle(text: 'ESTA SEMANA'),
        const SizedBox(height: Spacing.sm),
        _WeeklyInsightsCard(
          insights: state.insights,
          error: state.insightsError,
        ),
        const SizedBox(height: Spacing.xxl),
        const _SectionTitle(text: 'TUS RUTINAS'),
        const SizedBox(height: Spacing.sm),
        if (state.routines.isEmpty)
          _EmptyRoutines(onGoToRoutines: onGoToRoutines)
        else
          ...state.routines.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: _RoutineTile(
                routine: r,
                onTap: () => onOpenRoutine(r),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Pieces ────────────────────────────────────────────────────────────────

class _WeekRangeLabel extends StatelessWidget {
  const _WeekRangeLabel({required this.weekStart, required this.weekEnd});

  final DateTime weekStart;
  final DateTime weekEnd;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM', 'es');
    final text = '${fmt.format(weekStart)} – ${fmt.format(weekEnd)}';
    return Text(
      text,
      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.label.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _WeeklyInsightsCard extends StatelessWidget {
  const _WeeklyInsightsCard({required this.insights, required this.error});

  final WeeklyInsights? insights;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(Radii.md),
      border: Border.all(color: AppColors.divider),
    );

    if (error != null) {
      return Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: decoration,
        child: Row(
          children: [
            const Icon(
              Icons.info_outline,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                'No pudimos cargar los insights de esta semana.',
                style: AppTextStyles.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    final i = insights;
    if (i == null) {
      return Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: decoration,
        child: Row(
          children: [
            const Icon(
              Icons.bar_chart_outlined,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                'Sin datos esta semana',
                style: AppTextStyles.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: decoration,
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: Spacing.md,
        mainAxisSpacing: Spacing.md,
        childAspectRatio: 2.1,
        children: [
          _MetricCell(
            icon: Icons.fitness_center,
            label: 'VOLUMEN',
            value: '${i.totalVolume.toStringAsFixed(0)} kg',
            valueColor: AppColors.textPrimary,
          ),
          _MetricCell(
            icon: Icons.event_available,
            label: 'SESIONES',
            value: '${i.completedSessions}/${i.plannedDays}',
            valueColor: AppColors.primary,
          ),
          _MetricCell(
            icon: Icons.flag_circle,
            label: 'ADHERENCIA',
            value: '${i.adherenceRate.toStringAsFixed(0)}%',
            valueColor: AppColors.success,
          ),
          _MetricCell(
            icon: i.volumeTrendPercent >= 0
                ? Icons.trending_up
                : Icons.trending_down,
            label: 'TENDENCIA',
            value: '${i.volumeTrendPercent >= 0 ? '+' : ''}'
                '${i.volumeTrendPercent.toStringAsFixed(1)}%',
            valueColor: i.volumeTrendPercent >= 0
                ? AppColors.success
                : AppColors.error,
          ),
        ],
      ),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: Spacing.xs),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          value,
          style: AppTextStyles.heading2.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _RoutineTile extends StatelessWidget {
  const _RoutineTile({required this.routine, required this.onTap});

  final Routine routine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(Radii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.show_chart_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      routine.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ver progreso',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRoutines extends StatelessWidget {
  const _EmptyRoutines({required this.onGoToRoutines});

  final VoidCallback onGoToRoutines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.fitness_center_outlined,
            size: 40,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'Sin rutinas asignadas',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Explorá el catálogo desde la pestaña Rutinas.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.lg),
          OutlinedButton(
            onPressed: onGoToRoutines,
            child: Text(
              'IR A RUTINAS',
              style: AppTextStyles.label.copyWith(
                color: AppColors.primary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
