import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_flutter/features/workout/domain/repositories/workout_repository.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/exercise_stats/exercise_stats_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/exercise_stats/exercise_stats_state.dart';

class ExerciseStatsBloc extends Bloc<ExerciseStatsEvent, ExerciseStatsState> {
  final WorkoutRepository repository;

  ExerciseStatsBloc({required this.repository})
    : super(ExerciseStatsInitial()) {
    on<LoadExerciseStats>(_onLoadExerciseStats);
  }

  Future<void> _onLoadExerciseStats(
    LoadExerciseStats event,
    Emitter<ExerciseStatsState> emit,
  ) async {
    if (state is! ExerciseStatsLoading) {
      emit(ExerciseStatsLoading());
    }
    try {
      final result = await repository.getExerciseLogsHistory(
        event.userId,
        event.exerciseId,
      );

      result.fold(
        (failure) => emit(ExerciseStatsError(message: failure.message)),
        (history) => emit(ExerciseStatsLoaded(history: history)),
      );
    } catch (e) {
      emit(ExerciseStatsError(message: 'Error al cargar estadisticas: $e'));
    }
  }
}
