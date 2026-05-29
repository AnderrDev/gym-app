import 'package:drift/drift.dart';

/// Caché local de `routine_exercises` (junction routine_day ↔ exercise +
/// targets). PK compuesta `(routineDayId, exerciseId)` espejo del backend.
@DataClassName('CachedRoutineExerciseRow')
class CachedRoutineExercises extends Table {
  TextColumn get routineDayId => text()();
  TextColumn get exerciseId => text()();
  IntColumn get position => integer()();
  IntColumn get targetSets => integer()();
  IntColumn get targetReps => integer()();
  RealColumn get targetWeight => real()();
  IntColumn get restTimerSeconds =>
      integer().withDefault(const Constant(90))();

  /// Epoch ms (UTC) del último write desde remote.
  IntColumn get fetchedAt => integer()();

  @override
  Set<Column> get primaryKey => {routineDayId, exerciseId};
}
