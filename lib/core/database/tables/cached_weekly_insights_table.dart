import 'package:drift/drift.dart';

/// Caché local de los `WeeklyInsights` por (usuario, rutina, semana).
///
/// Phase 4 (SWR polish) — el repositorio escribe aquí el snapshot devuelto
/// por la Edge Function `get_weekly_insights_v1` para que la dashboard pueda
/// repintar sin red. El payload se guarda como JSON (`payloadJson`) y la
/// deserialización vuelve por `WeeklyInsights.fromJson` en el datasource.
///
/// PK compuesta `(userId, routineId, weekStart)`. `weekStart` es ISO
/// `yyyy-MM-dd` (truncado al día UTC para evitar colisiones por timezone).
@DataClassName('CachedWeeklyInsightRow')
class CachedWeeklyInsights extends Table {
  TextColumn get userId => text()();
  TextColumn get routineId => text()();

  /// ISO `yyyy-MM-dd`.
  TextColumn get weekStart => text()();

  TextColumn get payloadJson => text()();

  /// Epoch ms (UTC) del último write desde remote.
  IntColumn get fetchedAt => integer()();

  @override
  Set<Column> get primaryKey => {userId, routineId, weekStart};
}
