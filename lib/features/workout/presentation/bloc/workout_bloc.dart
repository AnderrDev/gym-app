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
      print(
        'WorkoutBloc: FetchAssignedRoutines triggered for userId: ${event.userId}',
      );
      emit(WorkoutLoading());
      try {
        final routines = await getAssignedRoutines(event.userId);
        print(
          'WorkoutBloc: FetchAssignedRoutines succeeded with ${routines.length} routines',
        );
        emit(RoutinesLoaded(routines));
      } catch (e, st) {
        print('WorkoutBloc: FetchAssignedRoutines Failed: $e\n$st');
        emit(WorkoutError(e.toString()));
      }
    });

    on<FetchLastExercisePerformance>((event, emit) async {
      emit(WorkoutLoading());
      try {
        final lastSet = await getLastExercisePerformance(event.exerciseId);
        emit(ExercisePerformanceLoaded(lastSet));
      } catch (e) {
        emit(WorkoutError(e.toString()));
      }
    });

    on<AddSetLogEvent>((event, emit) async {
      emit(SavingSetLog());
      try {
        await saveSetLog(event.setLog);
        emit(SetLogSuccess());
      } catch (e) {
        emit(WorkoutError(e.toString()));
      }
    });

    on<FinishSessionEvent>((event, emit) async {
      emit(WorkoutLoading());
      try {
        await finishWorkoutSession(event.sessionId, event.totalVolume);
        emit(WorkoutFinishedSuccess());
      } catch (e) {
        emit(WorkoutError(e.toString()));
      }
    });

    on<StartWorkoutEvent>((event, emit) async {
      print(
        'WorkoutBloc: StartWorkoutEvent triggered. routineId: ${event.routineId}',
      );
      emit(WorkoutLoading());
      try {
        // Start the session and fetch the exercises in parallel
        final results = await Future.wait([
          startWorkoutSession(event.userId, event.routineId),
          getRoutineExercises(event.routineId),
        ]);

        print('WorkoutBloc: StartWorkoutEvent succeeded.');

        // emit state
        emit(
          WorkoutSessionStarted(results[0] as dynamic, results[1] as dynamic),
        );
      } catch (e, stack) {
        print('WorkoutBloc: StartWorkoutEvent Failed: $e\n$stack');
        emit(WorkoutError(e.toString()));
      }
    });
  }
}
