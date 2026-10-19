/// Payload simple para inserts masivos de ejercicios en un día.
class AddExerciseToDayItem {
  const AddExerciseToDayItem({
    required this.exerciseId,
    required this.targetSets,
    required this.targetReps,
    required this.targetWeight,
    this.restSeconds = 90,
  });

  final String exerciseId;
  final int targetSets;
  final int targetReps;
  final double targetWeight;
  final int restSeconds;
}
