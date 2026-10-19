# tool/

Scripts y fuentes auxiliares que NO se bundlean con la app.

## `drift_worker.dart`

Fuente Dart del SharedWorker que corre `sqlite3` WASM para drift en web.
**No vive en `web/`** porque `flutter build web` copia todo lo de ahí al
bundle final — el `.dart` (source), `.deps` y `.map` agregarían ~600 KB
innecesarios. Solo el compilado `.js` debe estar en `web/`.

### Regenerar `web/drift_worker.dart.js`

Cuando se actualiza `drift` o `sqlite3` (paquetes), recompilar:

```bash
dart compile js tool/drift_worker.dart -o web/drift_worker.dart.js
```

El archivo de salida (~1.1 MB) se commitea — no se regenera en CI por
ahora.
