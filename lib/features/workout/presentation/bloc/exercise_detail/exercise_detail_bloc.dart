import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/features/workout/domain/usecases/get_exercise_detail.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/exercise_detail/exercise_detail_event.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/exercise_detail/exercise_detail_state.dart';

class ExerciseDetailBloc
    extends Bloc<ExerciseDetailEvent, ExerciseDetailState> {
  ExerciseDetailBloc({required this.getExerciseDetail})
    : super(const ExerciseDetailState()) {
    on<LoadExerciseDetail>(_onLoad);
  }

  final GetExerciseDetail getExerciseDetail;

  Future<void> _onLoad(
    LoadExerciseDetail event,
    Emitter<ExerciseDetailState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ExerciseDetailStatus.loading,
        clearErrorMessage: true,
      ),
    );
    final result = await getExerciseDetail(event.exerciseId);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ExerciseDetailStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (detail) => emit(
        state.copyWith(status: ExerciseDetailStatus.ready, detail: detail),
      ),
    );
  }
}
