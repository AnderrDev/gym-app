import 'package:fpdart/fpdart.dart' hide State;
import '../../../../core/error/failures.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/set_log.dart';
import '../../domain/usecases/get_last_exercise_performance.dart';
import 'set_logger_row.dart';

class ExerciseCard extends StatefulWidget {
  final Exercise exercise;
  final String sessionId;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.sessionId,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  // Store the number of sets added in this session locally
  int currentSetIndex = 1;

  late Future<Either<Failure, SetLog?>> _lastPerformanceFuture;

  @override
  void initState() {
    super.initState();
    // Dispatch event locally via DI instead of poisoning global state
    _lastPerformanceFuture = sl<GetLastExercisePerformance>().call(
      widget.exercise.id,
    );
  }

  void _incrementSetIndex() {
    setState(() {
      currentSetIndex++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.exercise.name, style: AppTextStyles.heading2),
                Text(
                  'Target: ${widget.exercise.targetWeight} lbs x ${widget.exercise.targetReps}',
                  style: AppTextStyles.label.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Previous Performance View
            FutureBuilder<Either<Failure, SetLog?>>(
              future: _lastPerformanceFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 12.0),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.surfaceHighlight,
                      ),
                    ),
                  );
                }

                if (snapshot.hasData) {
                  return snapshot.data!.fold(
                    (failure) => const SizedBox(),
                    (lastSetLog) {
                      if (lastSetLog == null) return const SizedBox();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.surfaceHighlight),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.history,
                              color: AppColors.textDisabled,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Last Session: ${lastSetLog.actualWeight} lbs x ${lastSetLog.actualReps} reps',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textDisabled,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
                return const SizedBox();
              },
            ),

            // Today's Sets
            Text('Track Sets', style: AppTextStyles.bodyLarge),
            const SizedBox(height: 8),
            SetLoggerRow(
              sessionId: widget.sessionId,
              exerciseId: widget.exercise.id,
              setIndex: currentSetIndex,
              onSetSaved: _incrementSetIndex,
            ),
          ],
        ),
      ),
    );
  }
}
