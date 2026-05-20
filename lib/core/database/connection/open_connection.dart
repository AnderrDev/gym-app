/// Entrypoint con conditional import:
///   - mobile/desktop  → `open_connection_io.dart` (sqlite3 nativo).
///   - web             → `open_connection_web.dart` (sqlite3 WASM + worker).
///
/// El consumidor (`LocalDatabase.open`) importa solo desde acá; nunca
/// referencia las dos impls directamente.
library;
export 'open_connection_io.dart'
    if (dart.library.js_interop) 'open_connection_web.dart';
