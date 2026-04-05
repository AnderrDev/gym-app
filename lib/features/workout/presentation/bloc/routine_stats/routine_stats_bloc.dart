import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/workout_repository.dart';
import 'routine_stats_event.dart';
import 'routine_stats_state.dart';

class RoutineStatsBloc extends Bloc<RoutineStatsEvent, RoutineStatsState> {
  final WorkoutRepository repository;

  RoutineStatsBloc({required this.repository}) : super(RoutineStatsInitial()) {
    on<FetchRoutineStats>(_onFetchRoutineStats);
  }

  Future<void> _onFetchRoutineStats(
    FetchRoutineStats event,
    Emitter<RoutineStatsState> emit,
  ) async {
    if (state is! RoutineStatsLoading) {
      emit(RoutineStatsLoading());
    }
    try {
      final result = await repository.getRoutineStats(
        event.userId,
        event.routineId,
      );

      result.fold(
        (failure) => emit(RoutineStatsError(failure.message)),
        (stats) => emit(RoutineStatsLoaded(stats)),
      );
    } catch (e) {
      emit(RoutineStatsError('Error al cargar estadisticas: $e'));
    }
  }
}
