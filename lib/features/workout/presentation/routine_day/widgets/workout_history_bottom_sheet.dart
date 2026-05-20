import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/i18n/app_strings.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/molecules/bottom_sheet_handle.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/workout_history_entry_card.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/workout_history_header.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/workout_performance_analyzer.dart';
import 'package:gym_flutter/features/workout/presentation/shared/widgets/workout_metric_grid.dart';

/// Sheet de detalle de una sesión pasada. Muestra:
/// - Hero compacto con fecha formateada en español.
/// - Grilla de 3 métricas (Carga, Series, Ejercicios).
/// - Lista de ejercicios con resumen + serie más pesada destacada.
/// - Coaching cuando hay recomendación accionable.
class WorkoutHistoryBottomSheet extends StatelessWidget {
  final WorkoutSession session;
  final List<SetLog> logs;
  final List<Exercise> exercises;

  const WorkoutHistoryBottomSheet({
    super.key,
    required this.session,
    required this.logs,
    required this.exercises,
  });

  @override
  Widget build(BuildContext context) {
    final groupedLogs = WorkoutPerformanceAnalyzer.groupByExerciseName(
      logs,
      exercises,
    );
    final totalVolume = logs.fold<double>(
      0,
      (s, l) => s + (l.actualWeight * l.actualReps),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: context.colors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const BottomSheetHandle(
              topPadding: Spacing.sm,
              bottomPadding: Spacing.sm,
            ),
            WorkoutHistoryHeader(
              date: session.sessionDate,
              onClose: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  0,
                  Spacing.lg,
                  Spacing.xxxl,
                ),
                children: [
                  WorkoutMetricGrid(
                    metrics: [
                      WorkoutMetric(
                        label: 'CARGA',
                        value: totalVolume.toStringAsFixed(0),
                        secondary: AppStrings.kgReps,
                        accent: context.colors.textPrimary,
                        icon: Icons.local_fire_department_rounded,
                        valueFontSize: 20,
                      ),
                      WorkoutMetric(
                        label: 'SERIES',
                        value: '${logs.length}',
                        accent: context.colors.primary,
                        icon: Icons.task_alt_rounded,
                        valueFontSize: 20,
                      ),
                      WorkoutMetric(
                        label: 'EJERCICIOS',
                        value: '${groupedLogs.length}',
                        accent: context.colors.info,
                        icon: Icons.format_list_numbered_rounded,
                        valueFontSize: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  ...groupedLogs.entries.map((entry) {
                    final coaching = session.coachingAnalysis?.firstWhereOrNull(
                      (a) =>
                          a.exerciseName == entry.key ||
                          a.exerciseId ==
                              exercises
                                  .firstWhereOrNull(
                                    (ex) => ex.name == entry.key,
                                  )
                                  ?.id,
                    );
                    return WorkoutHistoryEntryCard(
                      exerciseName: entry.key,
                      logs: entry.value,
                      coaching: coaching,
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
