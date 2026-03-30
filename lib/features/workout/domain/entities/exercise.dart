import 'package:equatable/equatable.dart';

class Exercise extends Equatable {
  final String id;
  final String routineId;
  final String name;
  final double targetWeight;
  final int targetReps;

  const Exercise({
    required this.id,
    required this.routineId,
    required this.name,
    required this.targetWeight,
    required this.targetReps,
  });

  @override
  List<Object?> get props => [id, routineId, name, targetWeight, targetReps];
}
