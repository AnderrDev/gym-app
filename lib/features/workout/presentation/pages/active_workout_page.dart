import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/routine.dart';
import 'package:go_router/go_router.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_event.dart';
import '../bloc/workout_state.dart';
import '../widgets/exercise_card.dart';

class ActiveWorkoutPage extends StatelessWidget {
  final Routine routine;
  final String userId;

  const ActiveWorkoutPage({
    super.key,
    required this.routine,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<WorkoutBloc>()..add(StartWorkoutEvent(userId, routine.id)),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: Text(routine.name, style: AppTextStyles.heading2),
          actions: [
            Builder(
              builder: (ctx) {
                return BlocBuilder<WorkoutBloc, WorkoutState>(
                  builder: (context, state) {
                    final sessionId = state is WorkoutSessionStarted
                        ? state.session.id
                        : '';
                    return TextButton(
                      onPressed: sessionId.isEmpty
                          ? null
                          : () {
                              ctx.read<WorkoutBloc>().add(
                                FinishSessionEvent(sessionId, 0.0),
                              ); // Total volume calc would happen here or in BLoC
                              context.pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Workout Finished! Volume saved.',
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                  backgroundColor: AppColors.accent,
                                ),
                              );
                            },
                      child: Text(
                        'FINISH',
                        style: AppTextStyles.label.copyWith(
                          color: sessionId.isEmpty
                              ? AppColors.surfaceHighlight
                              : AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<WorkoutBloc, WorkoutState>(
          builder: (context, state) {
            print('ActiveWorkoutPage evaluating state: ${state.runtimeType}');
            if (state is WorkoutLoading || state is WorkoutInitial) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            } else if (state is WorkoutError) {
              return Center(
                child: Text(
                  'Error loading session: ${state.message}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              );
            } else if (state is WorkoutSessionStarted) {
              final sessionId = state.session.id;
              final exercises = state.exercises;
              if (exercises.isEmpty) {
                return Center(
                  child: Text(
                    'No exercises configured for this routine.',
                    style: AppTextStyles.bodyMedium,
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  return ExerciseCard(
                    exercise: exercises[index],
                    sessionId: sessionId,
                  );
                },
              );
            }
            print('ActiveWorkoutPage: unhandled state ${state.runtimeType}');
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
