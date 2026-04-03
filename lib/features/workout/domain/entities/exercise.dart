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

  @override
  List<Object?> get props => [
    id, 
    routineDayId, 
    name, 
    targetWeight, 
    targetReps, 
    targetSets,
    restTimerSeconds,
  ];
}
