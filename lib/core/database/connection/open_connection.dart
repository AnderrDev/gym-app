import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

/// Devuelve el [QueryExecutor] que `LocalDatabase` debe usar en runtime.
///
/// En plataformas nativas (Android, iOS, desktop) delega en
/// `drift_flutter`'s [`driftDatabase`], que abre `gym_local.sqlite` en
/// `getApplicationDocumentsDirectory()` mediante `sqlite3_flutter_libs`.
///
/// En web la persistencia local todavía no está soportada (Phase W activará
/// el setup OPFS/IndexedDB con el worker WASM). Hasta entonces, llamar a esta
/// función en web lanza [`UnsupportedError`] para que el bootstrap lo capture
/// y omita el registro del singleton en DI.
QueryExecutor openConnection() {
  if (kIsWeb) {
    throw UnsupportedError(
      'LocalDatabase no está soportada en web todavía '
      '(pendiente de Phase W: configurar sqlite3 WASM + drift worker).',
    );
  }
  return driftDatabase(name: 'gym_local');
}
