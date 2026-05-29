import 'package:flutter_web_plugins/url_strategy.dart';

/// Activa rutas tipo `/dashboard` en lugar del default `/#/dashboard`.
/// Hosting (Firebase) ya redirige todas las rutas a `index.html` (ver
/// `firebase.json`), así que el refresh y el deep-link siguen funcionando.
void configureWebUrlStrategy() => usePathUrlStrategy();
