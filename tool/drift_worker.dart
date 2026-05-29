// Worker JS de drift para web. Compilado a `web/drift_worker.dart.js`
// mediante `dart compile js web/drift_worker.dart -o web/drift_worker.dart.js`.
//
// El bundle no se regenera automáticamente: si subimos `drift`/`sqlite3`
// hay que volver a correr el compile manual. Documentado en CLAUDE.md.
import 'package:drift/wasm.dart';

void main() {
  WasmDatabase.workerMainForOpen();
}
