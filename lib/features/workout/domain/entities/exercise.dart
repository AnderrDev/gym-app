import 'package:equatable/equatable.dart';

class Exercise extends Equatable {
  final String id;
  final String routineDayId;
  final String name;
  final String targetMuscle;
  final double targetWeight;
  final int targetReps;
  final int targetSets;
  final int restTimerSeconds;

  const Exercise({
    required this.id,
    required this.routineDayId,
    required this.name,
    required this.targetMuscle,
    required this.targetWeight,
    required this.targetReps,
    this.targetSets = 3,
    this.restTimerSeconds = 90,
  });

  Exercise copyWith({
    String? id,
    String? routineDayId,
    String? name,
    String? targetMuscle,
    double? targetWeight,
    int? targetReps,
    int? targetSets,
    int? restTimerSeconds,
  }) {
    return Exercise(
      id: id ?? this.id,
      routineDayId: routineDayId ?? this.routineDayId,
      name: name ?? this.name,
      targetMuscle: targetMuscle ?? this.targetMuscle,
      targetWeight: targetWeight ?? this.targetWeight,
      targetReps: targetReps ?? this.targetReps,
      targetSets: targetSets ?? this.targetSets,
      restTimerSeconds: restTimerSeconds ?? this.restTimerSeconds,
    );
  }

  @override
  List<Object?> get props => [
    id, 
    routineDayId, 
    name, 
    targetMuscle,
    targetWeight, 
    targetReps, 
    targetSets,
    restTimerSeconds,
  ];
}
