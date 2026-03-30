import 'package:equatable/equatable.dart';

class SetLog extends Equatable {
  final String? id; // Nullable because we create it before sending to DB
  final String sessionId;
  final String exerciseId;
  final double actualWeight;
  final int actualReps;
  final int setIndex;
  final DateTime? createdAt;

  const SetLog({
    this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.actualWeight,
    required this.actualReps,
    required this.setIndex,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    sessionId,
    exerciseId,
    actualWeight,
    actualReps,
    setIndex,
    createdAt,
  ];
}
