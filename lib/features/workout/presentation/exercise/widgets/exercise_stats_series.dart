import 'package:gym_flutter/features/workout/domain/entities/exercise_history_session.dart';

/// Helpers compartidos para que el bottom sheet pueda computar stat
/// stripes sin duplicar la lógica de PR / delta.
class ExerciseStatsSeries {
  ExerciseStatsSeries._({
    required this.values,
    required this.actual,
    required this.record,
    required this.delta,
  });

  factory ExerciseStatsSeries.from(
    List<ExerciseHistorySession> history,
    double Function(ExerciseHistorySession) extractor,
  ) {
    // history viene en orden descendente (más reciente primero). Trabajamos
    // con la cronología real → la reversa.
    final chronological = history.reversed.toList();
    final values = chronological.map(extractor).toList();
    final actual = values.isEmpty ? 0.0 : values.last;
    final record = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a > b ? a : b);
    final delta = values.length < 2 ? null : actual - values[values.length - 2];
    return ExerciseStatsSeries._(
      values: values,
      actual: actual,
      record: record,
      delta: delta,
    );
  }

  final List<double> values;
  final double actual;
  final double record;
  final double? delta;

  bool get actualIsRecord => values.isNotEmpty && actual >= record;
}
