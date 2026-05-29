import 'package:drift/drift.dart';

/// Cache local de `workout_sessions`. Phase 2 introduce el write-path
/// local-first: el repositorio escribe primero aquí (sync_status='pending')
/// y la cola outbox se encarga de empujar al backend.
///
/// El campo `coachingAnalysisJson` guarda el coaching aplicado tras
/// finalizar la sesión (serializado como JSON). Se setea solo cuando la
/// respuesta remota lo trae; nunca lo escribe la UI directamente.
@DataClassName('CachedWorkoutSessionRow')
class CachedWorkoutSessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get routineDayId => text()();

  /// ISO `yyyy-MM-dd`.
  TextColumn get sessionDate => text()();

  /// Epoch ms (UTC) del momento en que se inició la sesión localmente.
  IntColumn get startedAt => integer()();

  /// Epoch ms (UTC). `null` mientras la sesión esté abierta.
  IntColumn get completedAt => integer().nullable()();

  IntColumn get totalTargetSets =>
      integer().withDefault(const Constant(0))();
  IntColumn get completedSetsCount =>
      integer().withDefault(const Constant(0))();

  /// JSON serializado de `List<CoachingAnalysis>` cuando el remote ya
  /// devolvió el coaching final. Null si aún no se ha generado.
  TextColumn get coachingAnalysisJson => text().nullable()();

  /// Estado de sincronización: `pending`, `syncing`, `synced`, `error`.
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();

  /// Epoch ms (UTC) del último write local (insert o update).
  IntColumn get fetchedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
