import 'package:equatable/equatable.dart';
import 'set_log.dart';

class ExerciseHistorySession extends Equatable {
  final DateTime sessionDate;
  final List<SetLog> logs;

  const ExerciseHistorySession({required this.sessionDate, required this.logs});

  @override
  List<Object?> get props => [sessionDate, logs];

  double get maxWeight =>
      logs.fold(0.0, (max, l) => l.actualWeight > max ? l.actualWeight : max);
  double get totalVolume =>
      logs.fold(0.0, (s, l) => s + (l.actualWeight * l.actualReps));

  /// 1RM estimado: la mejor serie según Epley. Con 1 rep el 1RM es el peso
  /// (Epley daba 103,3 para 100×1), y por encima de 12 reps la fórmula
  /// infla mucho: esas series no cuentan si hay alguna de ≤12.
  double get estimated1RM {
    final valid = logs.where((l) => l.actualReps > 0).toList();
    if (valid.isEmpty) return 0.0;
    final reliable = valid.where((l) => l.actualReps <= 12).toList();
    final source = reliable.isEmpty ? valid : reliable;
    return source.map(epley1RM).reduce((a, b) => a > b ? a : b);
  }

  static double epley1RM(SetLog log) => log.actualReps <= 1
      ? log.actualWeight
      : log.actualWeight * (1 + log.actualReps / 30.0);
}
