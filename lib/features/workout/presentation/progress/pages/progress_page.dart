import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/routes/args/routing_args.dart';
import 'package:gym_flutter/core/routes/router_helpers.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/feedback/app_spinner.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/progress/progress_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/progress/progress_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/progress/progress_state.dart';
import 'package:gym_flutter/features/workout/presentation/progress/widgets/progress_routine_tile.dart';
import 'package:gym_flutter/features/workout/presentation/progress/widgets/weekly_insights_card.dart';

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
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'PROGRESO',
          style: context.text.headlineMedium?.copyWith(letterSpacing: 2),
        ),
      ),
      body: BlocBuilder<ProgressBloc, ProgressState>(
        builder: (context, state) {
          return switch (state) {
            ProgressInitial() || ProgressLoading() => const Center(
              child: AppSpinner.medium(),
            ),
            ProgressFailure(:final message) => _ProgressErrorView(
              message: message,
              onRetry: _retry,
            ),
            ProgressReady() => RefreshIndicator(
              onRefresh: _onRefresh,
              color: context.colors.primary,
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
            Icon(
              Icons.error_outline_rounded,
              color: context.colors.error,
              size: 48,
            ),
            const SizedBox(height: Spacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(color: context.colors.error),
            ),
            const SizedBox(height: Spacing.lg),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'REINTENTAR',
                style: context.text.labelMedium?.copyWith(
                  color: context.colors.onPrimary,
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
        WeeklyInsightsCard(
          insights: state.insights,
          error: state.insightsError,
        ),
        const SizedBox(height: Spacing.xxl),
        const _SectionTitle(text: 'TUS RUTINAS'),
        const SizedBox(height: Spacing.sm),
        if (state.routines.isEmpty)
          ProgressEmptyRoutines(onGoToRoutines: onGoToRoutines)
        else
          ...state.routines.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: ProgressRoutineTile(
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
      style: context.text.bodySmall?.copyWith(color: context.colors.textSecondary),
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
      style: context.text.labelMedium?.copyWith(
        color: context.colors.textSecondary,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

