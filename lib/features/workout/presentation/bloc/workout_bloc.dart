import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/finish_workout_session.dart';
import '../../domain/usecases/get_assigned_routines.dart';
import '../../domain/usecases/get_last_exercise_performance.dart';
import '../../domain/usecases/save_set_log.dart';
import '../../domain/usecases/start_workout_session.dart';
import '../../domain/usecases/get_routine_exercises.dart';
import 'workout_event.dart';
import 'workout_state.dart';

class WorkoutBloc extends Bloc<WorkoutEvent, WorkoutState> {
  final GetAssignedRoutines getAssignedRoutines;
  final GetLastExercisePerformance getLastExercisePerformance;
  final SaveSetLog saveSetLog;
  final FinishWorkoutSession finishWorkoutSession;
  final StartWorkoutSession startWorkoutSession;
  final GetRoutineExercises getRoutineExercises;

  WorkoutBloc({
    required this.getAssignedRoutines,
    required this.getLastExercisePerformance,
    required this.saveSetLog,
    required this.finishWorkoutSession,
    required this.startWorkoutSession,
    required this.getRoutineExercises,
  }) : super(WorkoutInitial()) {
    on<FetchAssignedRoutines>((event, emit) async {
      emit(WorkoutLoading());
      final result = await getAssignedRoutines(event.userId);
      result.fold(
        (failure) => emit(WorkoutError(failure.message)),
        (routines) => emit(RoutinesLoaded(routines)),
      );
    });

    on<FetchLastExercisePerformance>((event, emit) async {
      emit(WorkoutLoading());
      final result = await getLastExercisePerformance(event.exerciseId);
      result.fold(
        (failure) => emit(WorkoutError(failure.message)),
        (lastSet) => emit(ExercisePerformanceLoaded(lastSet)),
      );
    });

    on<AddSetLogEvent>((event, emit) async {
      emit(SavingSetLog());
      final result = await saveSetLog(event.setLog);
      result.fold(
        (failure) => emit(WorkoutError(failure.message)),
        (_) => emit(SetLogSuccess()),
      );
    });

    on<FinishSessionEvent>((event, emit) async {
      emit(WorkoutLoading());
      final result = await finishWorkoutSession(event.sessionId, event.totalVolume);
      result.fold(
        (failure) => emit(WorkoutError(failure.message)),
        (_) => emit(WorkoutFinishedSuccess()),
      );
    });

    on<StartWorkoutEvent>((event, emit) async {
      emit(WorkoutLoading());
      
      final sessionResult = await startWorkoutSession(event.userId, event.routineId);
      
      await sessionResult.fold(
        (failure) async => emit(WorkoutError(failure.message)),
        (session) async {
          final exercisesResult = await getRoutineExercises(event.routineId);
          exercisesResult.fold(
            (failure) => emit(WorkoutError(failure.message)),
            (exercises) => emit(WorkoutSessionStarted(session, exercises)),
          );
        },
      );
    });
  }
}
