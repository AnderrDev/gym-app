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

  double get maxWeight => logs.isEmpty ? 0 : logs.map((l) => l.actualWeight).reduce((a, b) => a > b ? a : b);
  double get totalVolume => logs.fold(0.0, (s, l) => s + (l.actualWeight * l.actualReps));
  double get estimated1RM {
    if (logs.isEmpty) return 0.0;
    final bestSet = logs.reduce((a, b) => (a.actualWeight * (1 + a.actualReps / 30)) > (b.actualWeight * (1 + b.actualReps / 30)) ? a : b);
    return bestSet.actualWeight * (1 + bestSet.actualReps / 30.0);
  }
}
