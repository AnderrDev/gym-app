import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/workout_state.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_prestart_components.dart';

class RoutineDayPreStartView extends StatelessWidget {
  final DayInfoLoaded state;
  final VoidCallback onStartWorkout;
  final void Function(
    WorkoutSession session,
    List<SetLog> logs,
    List<Exercise> exercises,
  )
  onOpenLastSession;

  const RoutineDayPreStartView({
    super.key,
    required this.state,
    required this.onStartWorkout,
    required this.onOpenLastSession,
  });

  @override
  Widget build(BuildContext context) {
    final lastSession = state.recentSessions.firstOrNull;
    final lastLogs = lastSession != null
        ? (state.recentSessionsLogs[lastSession.id] ?? <SetLog>[])
        : <SetLog>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lastSession != null) ...[
            GestureDetector(
              onTap: () =>
                  onOpenLastSession(lastSession, lastLogs, state.exercises),
              child: RoutineDayPreviousSessionCard(
                session: lastSession,
                logs: lastLogs,
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text('EJERCICIOS DEL DÍA', style: AppTextStyles.heading2),
          const SizedBox(height: 12),
          ...state.exercises.map((ex) {
            final lastRecord = lastLogs
                .where((l) => l.exerciseId == ex.id)
                .sorted((a, b) => b.actualWeight.compareTo(a.actualWeight))
                .firstOrNull;

            final exHist = <SetLog>[];
            for (final s in state.recentSessions) {
              exHist.addAll(
                (state.recentSessionsLogs[s.id] ?? const <SetLog>[]).where(
                  (l) => l.exerciseId == ex.id,
                ),
              );
            }
            final prevAvgWeight = exHist.isNotEmpty
                ? exHist.map((l) => l.actualWeight).reduce((a, b) => a + b) /
                      exHist.length
                : null;
            final prevAvgReps = exHist.isNotEmpty
                ? exHist.map((l) => l.actualReps).reduce((a, b) => a + b) /
                      exHist.length
                : null;

            return RoutineDayExercisePreviewCard(
              exercise: ex,
              lastRecord: lastRecord,
              prevAvgWeight: prevAvgWeight,
              prevAvgReps: prevAvgReps,
            );
          }),
          if (lastSession?.coachingAnalysis?.isNotEmpty ?? false) ...[
            const SizedBox(height: 20),
            RoutineDayPreviousCoachingCard(
              coaching: lastSession!.coachingAnalysis!,
            ),
          ],
          if (state.hasAnotherActiveSession) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFFF9800),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ya tienes un entrenamiento en curso${state.anotherActiveSessionDayName != null ? ' (${state.anotherActiveSessionDayName})' : ''}. Debes finalizarlo o retomarlo antes de iniciar otro.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFFFF9800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: state.hasAnotherActiveSession ? null : onStartWorkout,
              icon: Icon(
                state.hasAnotherActiveSession
                    ? Icons.lock_outline_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.black,
                size: 24,
              ),
              label: Text(
                state.hasAnotherActiveSession
                    ? 'TIENES UNA SESION EN CURSO'
                    : 'INICIAR ENTRENAMIENTO',
                style: AppTextStyles.label.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
