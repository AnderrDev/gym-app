import 'package:equatable/equatable.dart';

import 'package:gym_flutter/features/workout/domain/entities/exercise_detail.dart';

enum ExerciseDetailStatus { initial, loading, ready, failure }

class ExerciseDetailState extends Equatable {
  const ExerciseDetailState({
    this.status = ExerciseDetailStatus.initial,
    this.detail,
    this.errorMessage,
  });

  final ExerciseDetailStatus status;
  final ExerciseDetail? detail;
  final String? errorMessage;

  bool get isLoading => status == ExerciseDetailStatus.loading;

  ExerciseDetailState copyWith({
    ExerciseDetailStatus? status,
    ExerciseDetail? detail,
    bool clearDetail = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ExerciseDetailState(
      status: status ?? this.status,
      detail: clearDetail ? null : (detail ?? this.detail),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, detail, errorMessage];
}
