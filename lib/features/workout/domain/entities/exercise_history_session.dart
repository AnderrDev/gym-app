import 'package:equatable/equatable.dart';
import 'set_log.dart';

class ExerciseHistorySession extends Equatable {
  final DateTime sessionDate;
  final List<SetLog> logs;

  const ExerciseHistorySession({
    required this.sessionDate,
    required this.logs,
  });

  @override
  List<Object?> get props => [sessionDate, logs];

  double get maxWeight => logs.fold(0.0, (max, l) => l.actualWeight > max ? l.actualWeight : max);
  double get totalVolume => logs.fold(0.0, (s, l) => s + (l.actualWeight * l.actualReps));
  double get estimated1RM {
    if (logs.isEmpty) return 0.0;
    var bestSet = logs.first;
    var bestScore = bestSet.actualWeight * (1 + bestSet.actualReps / 30.0);

    for (final log in logs.skip(1)) {
      final score = log.actualWeight * (1 + log.actualReps / 30.0);
      if (score > bestScore) {
        bestSet = log;
        bestScore = score;
      }
    }

    return bestSet.actualWeight * (1 + bestSet.actualReps / 30.0);
  }
}
