import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

import 'package:gym_flutter/core/observability/app_logger.dart';

/// Impl web: drift sobre `sqlite3` compilado a WASM, corriendo en un
/// SharedWorker (`drift_worker.dart.js`). Persistencia: OPFS cuando el
/// browser la soporta (Chrome/Edge/Safari 16.4+, Firefox 111+); fallback
/// a IndexedDB en el resto.
///
/// Los assets `sqlite3.wasm` y `drift_worker.dart.js` viven en `web/` y
/// se sirven desde la root del hosting. El `LazyDatabase` difiere la
/// apertura hasta el primer query.
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final db = await WasmDatabase.open(
      databaseName: 'gym_local',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.dart.js'),
    );
    AppLogger.instance.info(
      'WasmDatabase abierta: storage=${db.chosenImplementation.name} '
      'missingFeatures=${db.missingFeatures.map((f) => f.name).join(",")}',
    );
    return db.resolvedExecutor;
  });
}
