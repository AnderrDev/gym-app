import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise.freezed.dart';

@freezed
abstract class Exercise with _$Exercise {
  const factory Exercise({
    required String id,
    required String routineDayId,
    required String name,
    required String targetMuscle,
    required double targetWeight,
    required int targetReps,
    @Default(3) int targetSets,
    @Default(90) int restTimerSeconds,
  }) = _Exercise;
}
