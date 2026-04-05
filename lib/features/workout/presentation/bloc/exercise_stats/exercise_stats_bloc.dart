import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/workout_repository.dart';
import 'exercise_stats_event.dart';
import 'exercise_stats_state.dart';

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
