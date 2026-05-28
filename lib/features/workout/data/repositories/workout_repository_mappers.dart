import 'package:gym_flutter/features/workout/data/models/set_log_model.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise_history_session.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_history_session.dart';

/// Mappers de **agregación** que convierten filas crudas (joins de varias
/// tablas) en entidades de historial. La conversión 1:1 model↔entity vive
/// como `fromEntity`/`toEntity` en cada `XModel`.

/// Agrupa filas de `set_logs` (con join a `workout_sessions.session_date`) por
/// fecha y devuelve `ExerciseHistorySession`s ordenadas descendentes.
List<ExerciseHistorySession> mapExerciseLogsToHistory(
  List<Map<String, dynamic>> rawData,
) {
  final grouped = <String, List<SetLogModel>>{};

  for (final row in rawData) {
    final sessionData = row['workout_sessions'] as Map<String, dynamic>?;
    final sessionDateStr = sessionData?['session_date'] as String?;
    if (sessionDateStr == null) continue;
    final parsedDate = DateTime.tryParse(sessionDateStr);
    if (parsedDate == null) continue;

    final dateKey =
        '${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-'
        '${parsedDate.day.toString().padLeft(2, '0')}';

    grouped.putIfAbsent(dateKey, () => []).add(SetLogModel.fromJson(row));
  }

  return grouped.entries
      .map(
        (entry) => ExerciseHistorySession(
          sessionDate: DateTime.parse(entry.key),
          logs: entry.value.map((m) => m.toEntity()).toList(),
        ),
      )
      .toList()
    ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
}

/// Convierte filas crudas de `workout_sessions` + join a `routine_days` +
/// `set_logs` en entidades de historial agregado por sesión.
List<RoutineHistorySession> mapRoutineSessionRows(
  List<Map<String, dynamic>> rawData,
) {
  return rawData
      .map((row) {
        final sessionDateStr = row['session_date'] as String?;
        if (sessionDateStr == null) return null;
        final date = DateTime.tryParse(sessionDateStr);
        if (date == null) return null;
        final routineDayData = row['routine_days'] as Map<String, dynamic>?;
        final logs =
            (row['set_logs'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        double totalVolume = 0;
        int totalReps = 0;
        for (final log in logs) {
          final w = (log['actual_weight'] as num?)?.toDouble() ?? 0.0;
          final r = (log['actual_reps'] as num?)?.toInt() ?? 0;
          totalVolume += w * r;
          totalReps += r;
        }

        return RoutineHistorySession(
          sessionDate: date,
          routineDayId: row['routine_day_id']?.toString() ?? '',
          routineDayName:
              routineDayData?['name']?.toString() ?? 'Día eliminado',
          totalVolume: totalVolume,
          totalReps: totalReps,
          exerciseCount: logs.length,
        );
      })
      .whereType<RoutineHistorySession>()
      .toList();
}
