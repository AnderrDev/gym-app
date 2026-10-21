# Plan de mejoras iOS — 2026-10-21

Origen: revisión exhaustiva del proyecto para iOS (analyze limpio, `flutter build ios --release --no-codesign` OK en 34 s / 25 MB, 140 archivos de test). Cada paquete lo resuelve un subagente; el estado se actualiza aquí.

Reglas comunes para todos los paquetes:
- No hacer commits. No tocar el trabajo en curso de iconos (`assets/icon/`, `tool/generate_app_icon.py`, PNGs de iconos, `pubspec.yaml#flutter_launcher_icons`).
- Seguir `CLAUDE.md` y `docs/AGENT_CONTEXT.md`. Strings de UI y comentarios en español. Imports absolutos.
- Cerrar con `flutter analyze` limpio + tests impactados. Si se toca `ios/`, además `flutter build ios --release --no-codesign`.

## P1 — Alarma de fin de descanso en iOS (prioridad máxima) — ESTADO: hecho

Implementado (2026-10-21):
- `RestTimerController` programa SIEMPRE en iOS (`Capabilities.schedulesRestEndAlert`) la notificación local al iniciar/ajustar el descanso y la cancela al saltar/parar a mano; el fin natural no la cancela. Android sin cambios (avisa el `Timer` con `showRestEnded`). El controller ya no depende de `LiveActivitiesBridge`.
- La Live Activity ya no manda `alertConfig` (`LiveActivitiesBridge.update` sin `alertOnUpdate`, `ActiveWorkoutNotifier.onRestEnded()` sin `naturalEnd`): la notificación programada es la única fuente de sonido. En primer plano se mantienen háptico + snackbar y la notificación se presenta igualmente.
- Tono propio `ios/Runner/rest_alarm.caf` (5,1 s, pitidos sintetizados, IMA4) en Resources del target Runner, usado vía `DarwinNotificationDetails(sound: 'rest_alarm.caf')`; entitlement `com.apple.developer.usernotifications.time-sensitive` en `Runner.entitlements` (el perfil de aprovisionamiento debe incluirlo al firmar).
- iOS respeta el interruptor de silencio (sonará solo con vibración en modo silencio); romperlo requiere AlarmKit (P8).
- Probar en dispositivo: iniciar entrenamiento, registrar una serie, bloquear la pantalla o mandar la app a segundo plano → al llegar a cero debe sonar el tono y vibrar una sola vez (con y sin Live Activity); saltar el descanso antes de cero no debe sonar; `+15 s` debe retrasar la alarma.

Plan original:

Síntoma reproducido por el usuario: con la app en segundo plano el conteo de descanso sigue (la Live Activity cuenta nativamente) pero al llegar a cero **no suena ni vibra**.

Causa: `RestTimerController._usesScheduledAlert` solo programa la notificación local cuando NO hay Live Activity. Con Live Activity el aviso depende de `alertConfig` en un `updateActivity` que dispara el `Timer` de Dart, y Dart no corre con la app suspendida.

Objetivo: comportamiento de alarma en cualquier iOS soportado.
1. En iOS programar SIEMPRE la notificación local de fin de descanso (`zonedSchedule`) al iniciar/ajustar el descanso, haya o no Live Activity. Cancelarla al saltar/ajustar.
2. Sonido de alarma propio: añadir un archivo `.caf`/`.aiff` (≤ 30 s, p. ej. tono de alarma generado o libre de licencia) al bundle de Runner (Resources del target en `project.pbxproj`) y referenciarlo con `DarwinNotificationDetails(sound: ...)`. Nivel `timeSensitive` + entitlement `com.apple.developer.usernotifications.time-sensitive` en `Runner.entitlements`.
3. Evitar duplicados: en iOS la Live Activity ya no manda `alertConfig` (la notificación programada es la única fuente de sonido). Si el fin natural ocurre en primer plano, mantener háptico + snackbar; la notificación programada se presenta igualmente (presentSound/presentAlert ya están en true).
4. `requestPermission` pide `sound: true` (ya); documentar en el plan que iOS respeta el interruptor de silencio salvo con AlarmKit (P8).
5. Tests: ampliar `rest_timer_controller_test.dart` para cubrir "con Live Activity disponible también se programa la alerta en iOS" y cancelaciones.

## P2 — Live Activities robustas + limpieza de la extensión — ESTADO: hecho
- `LiveActivitiesBridge.init`: consultar `getAllActivitiesIds()`; cerrar activities huérfanas (o readoptar la primera) antes de crear una nueva. Hoy `removeWhenAppIsKilled: false` + `bootstrapFromPersistedSession` genera duplicados tras matar la app.
- `bootstrapFromPersistedSession` arranca con `0/0 series`: pasar el progreso real si `ActiveSessionService` lo expone; si no, omitir el contador hasta el primer `onProgress`.
- Borrar los archivos template no registrados: `SmartGymTrackerActivityExtension.swift` (widget "My Widget") y `SmartGymTrackerActivityExtensionControl.swift` (también sus referencias en `project.pbxproj`).
- `INFOPLIST_KEY_CFBundleDisplayName` de la extensión → "Smart Gym Tracker".
- Quitar `NSSupportsLiveActivitiesFrequentUpdates` de `Info.plist` (solo aplica a updates push).
- Añadir `PrivacyInfo.xcprivacy` al target de la extensión (categoría `NSPrivacyAccessedAPICategoryUserDefaults`, razón `1C8F.1`).

**Resumen (hecho):** `LiveActivitiesBridge.init` finaliza todas las activities huérfanas (`endAllActivities`) y el bootstrap recrea una sola; sin progreso persistido, el bootstrap usa `totalSets = 0` y la extensión (lock screen, expanded bottom, minimal) oculta el contador en ese caso. Borrados los dos templates Swift (grupo sincronizado, sin cambios de pbxproj), display name "Smart Gym Tracker", quitado `NSSupportsLiveActivitiesFrequentUpdates` y añadido `PrivacyInfo.xcprivacy` a la extensión. Tests en `test/core/notifications/`.

**Dynamic Island:** sin cronómetro de sesión hacia adelante; compactTrailing y expanded trailing muestran solo la cuenta atrás del descanso, y fuera del descanso el progreso `completed/total` (oculto si `totalSets == 0`). La lock screen conserva el cronómetro de sesión (`sessionStartedAt` sigue en el payload).

**Probar en dispositivo:** iniciar un entreno, completar series, matar la app desde el selector y relanzar: debe quedar una sola Live Activity (nombre del día + cronómetro, sin "0/0") que muestra el contador al registrar la siguiente serie.

## P3 — Info.plist y preparación App Store — ESTADO: hecho
**Resumen (hecho):** display name "Smart Gym Tracker", `CFBundleName` SmartGymTracker, `CFBundleDevelopmentRegion`/`CFBundleLocalizations` = es (y `developmentRegion = es` + `es` en `knownRegions` del pbxproj para ser coherente), `ITSAppUsesNonExemptEncryption` = false, iPhone solo Portrait, iPad Portrait/PortraitUpsideDown con `UIRequiresFullScreen`. Verificado con `plutil -p` sobre el `Runner.app` release.

- `CFBundleDisplayName` → "Smart Gym Tracker" (`CFBundleName` → SmartGymTracker).
- `CFBundleLocalizations` = [es]; `CFBundleDevelopmentRegion` = es.
- `ITSAppUsesNonExemptEncryption` = false.
- Orientaciones: `UISupportedInterfaceOrientations` solo Portrait (iPhone). iPad: `UIRequiresFullScreen = true` + Portrait/PortraitUpsideDown (decisión por defecto: se mantiene iPad en modo full screen; cambiar a iPhone-only requiere decisión del usuario).

## P4 — Podfile — ESTADO: hecho
**Resumen (hecho):** `platform :ios, '13.0'` explícito; `post_install` fija `GCC_PREPROCESSOR_DEFINITIONS` de `permission_handler_apple` con todas las macros `PERMISSION_*` a 0 salvo `PERMISSION_NOTIFICATIONS=1` (comprobado en `ios/Pods/Pods.xcodeproj/project.pbxproj`, 3 configs). `pod install` y `flutter build ios --release --no-codesign` OK.

- `platform :ios, '13.0'` explícito.
- En `post_install`, macros de `permission_handler_apple` (`GCC_PREPROCESSOR_DEFINITIONS`): todas a 0 salvo `PERMISSION_NOTIFICATIONS=1` (el plugin entra solo por `live_activities` y en iOS no se usa). Verificar build.

## P5 — Sesión de Supabase en Keychain — ESTADO: hecho
- `flutter_secure_storage` ^10.3.4. `SecureSessionStorage` (`lib/core/auth/secure_session_storage.dart`) implementa `LocalStorage` de `supabase_flutter` sobre Keychain (iOS, `first_unlock_this_device`, sin iCloud) / Keystore (Android, opciones por defecto de v10). Se pasa en `SupabaseConfig.init()` vía `FlutterAuthClientOptions(localStorage: ...)` solo si `Capabilities.supportsSecureSessionStorage` (iOS/Android); web sigue con el storage por defecto.
- Clave: la misma que usa el storage por defecto, `sb-<ref>-auth-token` (`SupabaseConfig.sessionStorageKey`; no `supabase.auth.token`).
- Migración única en `initialize()`: si el Keychain no tiene sesión y SharedPreferences sí, se copia y se borra de SharedPreferences.
- Reinstalación: el Keychain sobrevive a desinstalar en iOS. Sin el flag `secure_session_storage.installed` en SharedPreferences (se borra al desinstalar) se elimina la sesión del Keychain antes de migrar.
- Si el Keychain falla al inicializar: se usa SharedPreferences durante ese proceso (comportamiento anterior, no se desloguea) y no se escribe el flag, así que se reintenta en el próximo arranque. Ninguna operación lanza; todo se loguea con `AppLogger`.
- El code verifier PKCE (`pkceAsyncStorage`, reset de contraseña) sigue en SharedPreferences: es de un solo uso y dura poco.
- Tests: `test/core/auth/secure_session_storage_test.dart` (migración, reinstalación, persist/remove, errores del Keychain) y `test/core/config/supabase_config_test.dart` (clave).
- Probar en dispositivo:
  1. Instalación limpia: login → matar la app → reabrir: sigue logueado. Logout → reabrir: pide login.
  2. Usuario existente: instalar la versión anterior, loguearse, instalar esta encima (sin desinstalar) → abre logueado (log `secure_session_storage.migrated`).
  3. Reinstalación (iOS): loguearse, desinstalar, reinstalar → pide login.

## P6 — Arranque y rendimiento — ESTADO: hecho
Resumen: se quitó `initializeTimeZones()` (`tz.UTC` es constante del paquete; el plugin 18.0.1 no usa `tz.local`). En nativo `runApp` corre tras Supabase + DI y `NotificationService.init` → `LiveActivitiesBridge.init` → `bootstrapFromPersistedSession` se difieren a un post-frame callback (en web siguen antes de `runApp`). Carreras resueltas con init memoizado (`NotificationService.init` compartido y awaiteado por todos los métodos, incl. `scheduleRestEnded`; `LiveActivitiesBridge.ready`/`init` memoizado y awaiteado por start/update/end y por `ActiveWorkoutNotifier._post`); el bootstrap no pisa una sesión ya iniciada. Orientación e `initializeDateFormatting` corren en paralelo con dotenv/Supabase/DI. Talker `maxHistoryItems: 300`; `AppBlocObserver` solo registra errores en release. `MediaQuery.withClampedTextScaling(0.85–1.3)` en el `builder`.
- Quitar `tz_data.initializeTimeZones()` (solo se usa `tz.UTC`, que no necesita la base) o cargar `latest_10y`.
- En plataformas nativas: `runApp` tras Supabase + DI; `NotificationService.init`, `LiveActivitiesBridge.init` y `bootstrapFromPersistedSession` después del primer frame (`WidgetsBinding.addPostFrameCallback` o `unawaited` tras `runApp`). Mantener el orden en web.
- `initializeDateFormatting` y `SharedPreferences.getInstance()` en paralelo donde sea posible.
- Talker: `maxHistoryItems` acotado y `AppBlocObserver` sin transiciones completas en release.
- Dynamic Type: `MediaQuery` con `TextScaler` acotado (p. ej. 0.85–1.3) en el `builder` de `MaterialApp.router`.

## P7 — Dependencias — ESTADO: hecho

Implementado (2026-10-21) con Flutter 3.38.9 / Dart 3.10.8. `flutter analyze` limpio, `flutter test` (sin `test/_screens/`, goldens locales) 752/752, `pod install` OK, `flutter build ios --release --no-codesign` OK (25,2 MB) y `flutter build web --wasm` OK. iOS mínimo (13.0) y Android `minSdk` (`flutter.minSdkVersion` = 24) sin cambios.

| Paquete | Antes | Después | Notas |
|---|---|---|---|
| `supabase_flutter` | 2.12.2 | 2.18.3 | `gotrue` 2.19 → 2.27.3, `supabase` 2.10 → 2.16.5. La clave de sesión sigue siendo `sb-<ref>-auth-token` (verificado en `supabase.dart` del paquete nuevo), así que ni el Keychain ni la migración de `SecureSessionStorage` cambian. `anonKey:` está deprecado → `Supabase.initialize(publishableKey: …)` con el mismo valor. |
| `go_router` | 17.1.0 | 17.5.0 | 18.x es major: fuera. |
| `get_it` | 9.2.1 | 9.3.0 | |
| `fl_chart` | 1.2.0 | 1.3.0 | arrastra `equatable` 2.0.8 → 2.1.0. |
| `uuid` | 4.5.3 | 4.6.0 | |
| `path_provider` | 2.1.5 | 2.1.6 | |
| `mocktail` (dev) | 1.0.4 | 1.0.5 | |
| `flutter_local_notifications` | 18.0.1 | 22.3.2 | Parámetros con nombre en `initialize`/`show`/`zonedSchedule`/`cancel`; se quitó `uiLocalNotificationDateInterpretation` (eliminado en 19). Requisitos: iOS 13, Android API 24, `compileSdk` 36, desugaring 2.1.4 — todos ya cumplidos por el proyecto. El código Obj-C que arma el `UNCalendarNotificationTrigger` es idéntico al de 18.0.1. |
| `timezone` | 0.10.1 | 0.11.2 | `tz.UTC` ahora se llama `Etc/UTC` (antes `UTC`); el plugin manda ese nombre a `NSTimeZone timeZoneWithName:` / `ZoneId.of`, ambos lo aceptan (comprobado en Foundation). Sigue sin cargarse la base IANA. |
| `live_activities` | 2.4.7 | 2.4.7 | **Fuera**: ≥ 2.4.8 exige Dart 3.11 / Flutter 3.41; 2.5–2.6 exigen Dart 3.12 / Flutter 3.44. |
| `wakelock_plus` | 1.5.2 | 1.5.2 | **Fuera**: 1.6.0/1.7 exigen Dart 3.11, 1.8 Dart 3.12; 1.6.1 (Dart 3.10) necesita `win32` ^6 y choca con `talker_flutter` 4.x (`share_plus` 10/11 → `win32` 5). Subirlo obliga a migrar a `talker_flutter` 5 (major). |
| `connectivity_plus` | 6.1.5 | 6.1.5 | **Fuera**: 7.x exige en Android AGP ≥ 8.12.1, Gradle ≥ 8.13 y Kotlin 2.2.0; el proyecto usa AGP 8.11.1. El lado Dart sería trivial (`ConnectivityResult.satellite` ya se maneja), pero el salto de AGP no se puede verificar sin un build Android. |
| `drift`, `drift_flutter`, `sqlite3`, `sqlite3_flutter_libs`, `drift_dev` | 2.31.0 / 0.2.8 / 2.9.4 / 0.5.42 / 2.31.0 | sin cambios | Congelados a propósito: `web/sqlite3.wasm` y `web/drift_worker.dart.js` deben coincidir con el lock. Ver migración abajo. |

Para subir `live_activities` 2.6 y `wakelock_plus` 1.8 hace falta antes actualizar Flutter a ≥ 3.44 (Dart 3.12). Al hacerlo, revisar el CHANGELOG de `live_activities` contra el Swift de la extensión (`LiveActivitiesAppAttributes`, claves `<uuid>_<clave>` en el UserDefaults del App Group).

### Ruta de migración de `sqlite3_flutter_libs` (EOL) — no ejecutada
- `sqlite3_flutter_libs` 0.6.0+eol es un paquete vacío: desde `sqlite3` 3.x el binario nativo de SQLite lo aporta el propio paquete `sqlite3` mediante un *build hook* (native assets: `hooks`/`code_assets`), que descarga o compila la librería y Flutter la empaqueta en la app. Ya no hay pod ni AAR de `sqlite3_flutter_libs`.
- Pasos: subir juntos `sqlite3` → ^3.x, `drift` → ≥ 2.30 (la última, 2.35, pide `sqlite3` ^3.4), `drift_dev` a la misma versión y `drift_flutter` → 0.3.x; quitar `sqlite3_flutter_libs` de `pubspec.yaml` (o dejar el 0.6.0+eol, que `drift_flutter` 0.3 todavía declara). Hoy `pub outdated` deja `drift` resoluble solo hasta 2.31.0: hay que resolver antes los conflictos de `hooks` (^2.2 en `sqlite3` 3.x; el lock tiene 1.0.2) y del analizador de `drift_dev`/`freezed`/`build_runner`.
- `open_connection_io.dart`: revisar si `drift_flutter` 0.3 cambia `driftDatabase(...)`/las opciones nativas y si siguen existiendo los workarounds para Android antiguos (`applyWorkaroundToOpenSqlite3OnOldAndroidVersions`).
- Web: `web/sqlite3.wasm` debe volver a descargarse de la release `sqlite3-<versión 3.x>` (`curl -sSLfo web/sqlite3.wasm "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-<VERSION>/sqlite3.wasm"`) y `web/drift_worker.dart.js` recompilarse (`dart compile js tool/drift_worker.dart -o web/drift_worker.dart.js`). Si no coinciden, el primer query falla con `LinkError: ... function import requires a callable`. Revisar también la API de `WasmDatabase`/`open_connection_web.dart`.
- iOS: tras `pod install` el pod de `sqlite3_flutter_libs` desaparece; comprobar que el framework del native asset entra en Runner (no en la extensión) y que `flutter build ios` y el arranque (`localDb.ping()`) siguen OK. Android: el `.so` llega por native assets; probar en un API 24.
- Verificación: `flutter test`, flujos `test/integration/app_flows_test.dart`, smoke en web (OPFS + fallback IndexedDB) y en dispositivo con datos existentes (la base en disco no cambia de formato, pero conviene probar una app con outbox pendiente).

## P8 — AlarmKit (iOS 26+) — ESTADO: hecho (falta verificar en iPhone con iOS 26)
**Enfoque: canal nativo propio, no `flutter_alarmkit`.** El plugin (0.5.0, el más nuevo; Dart `^3.7`, Flutter `>=3.38`, podspec/Package.swift en iOS 13 con `@available`) compilaría, pero su setup no es trivial para este proyecto y choca con lo existente:
- exige crear a mano en Xcode un **segundo** Widget Extension (`AlarmkitWidget`, nombre fijo) con sus plantillas Swift, además de nuestra extensión de Live Activity;
- `flutter_alarmkit:setup` parchea `Info.plist` con claves que no necesitamos (`NSBonjourServices`, `NSLocalNetworkUsageDescription`, `UIApplicationSceneManifest` → migración a ciclo de vida por escenas), cambia `AppDelegate` a `FlutterImplicitEngineDelegate` y reescribe `project.pbxproj` (baja `objectVersion`, reordena las build phases), lo mismo que ya hacen los hacks del `post_install` del Podfile.

El canal propio son ~170 líneas Swift + ~200 Dart, compila con deployment 13 y AlarmKit/ActivityKit quedan weak-linkeados (`LC_LOAD_WEAK_DYLIB`, `minos 13.0`, comprobado con `otool -l` sobre el `Runner.app` release).

**Piezas:**
- `ios/Runner/RestAlarmChannel.swift` (canal `com.gymtracker.gym_flutter/rest_alarm`, registrado en `AppDelegate`): `authorizationState`, `requestAuthorization`, `schedule {epochMs}` (cancela las alarmas previas y programa una alarma de **fecha fija** `.fixed(date)`, título "¡A entrenar!", botón "Detener" en 26.0 —desde 26.1 lo pone el sistema—, sonido `.named("rest_alarm.caf")` del bundle), `cancelAll` (detiene la que suena y cancela todas). En iOS < 26 responde `unsupported` / `false`.
- `lib/core/notifications/alarm_kit_bridge.dart`: puente Dart; nunca lanza (error → `unsupported`/`false` + `AppLogger`). Solo invoca el canal si `Capabilities.mayUseAlarmKit` (iOS).
- `lib/core/notifications/rest_alarm_scheduler.dart`: `RestAlarmScheduler` (abstracción que usa `RestTimerController`) y `AlarmKitRestAlarmScheduler`, que elige AlarmKit o la notificación de P1. Operaciones en serie y con hora de fin absoluta (un `start` + `adjust` seguidos o el diálogo de autorización abierto no dejan dos avisos ni se aplican en desorden).
- `NSAlarmKitUsageDescription` en `Info.plist`: "Usamos alarmas para avisarte cuando termina tu descanso entre series, incluso con el iPhone en silencio."

**Comportamiento:**
- **iOS 26+ autorizado:** al iniciar el descanso se programa la alarma de AlarmKit y se cancela la notificación de P1 (una sola fuente de sonido). `+15 s`/`-15 s` la reprograma; saltar/parar la cancela. Suena como alarma con el interruptor de silencio y con Focus.
- **Autorización:** se pide la primera vez que arranca un descanso (no al abrir la app). Mientras el diálogo está abierto queda programada la notificación de P1 como cobertura; si se concede, se sustituye por la alarma; si se deniega, queda la notificación.
- **Fin con la app en primer plano:** en el último segundo (`≤ 1 s` restante y `AppLifecycleState.resumed`) la alarma se cambia por la notificación de P1 (primero se programa la notificación y luego se cancela la alarma): con el usuario mirando la app sobra una alarma a pantalla completa; basta háptico + snackbar + notificación (que respeta el modo silencio). Si la app está en segundo plano o la pantalla bloqueada, Dart no corre y suena la alarma.
- **Volver a la app con la alarma sonando:** el fin natural detectado al reanudar detiene la alarma (`cancelAll`).
- **iOS < 26, autorización denegada o error del canal:** notificación de P1 tal cual (time-sensitive, `rest_alarm.caf`, respeta silencio/Focus).
- **Android / web:** sin cambios (el `Timer` avisa con `showRestEnded`; el scheduler no se usa).

**Solapamiento con la Live Activity propia:** ninguno durante el descanso. Al ser una alarma de fecha fija (no `countdown`), AlarmKit no presenta cuenta atrás ni Live Activity propia hasta que suena; la cuenta atrás la sigue mostrando solo nuestra Live Activity (Dynamic Island + lock screen), sin cambios en la extensión. Al llegar a cero aparece la alerta de alarma del sistema (pantalla completa en lock screen / Dynamic Island) junto a nuestra Live Activity.

**Tests:** `test/core/notifications/rest_alarm_scheduler_test.dart` (AlarmKit vs fallback por versión/autorización/error, primer descanso con cobertura, orden en serie, cambio a notificación, sin doble programación) y `rest_timer_controller_test.dart` (start/adjust/stop/fin natural vía el scheduler, cambio a notificación solo en primer plano y una vez).

**Riesgos que solo se ven en dispositivo:**
- Que AlarmKit presente bien la alerta de una alarma `.fixed` sin un widget `ActivityConfiguration(for: AlarmAttributes<…>)` (la documentación lo exige para countdown/pausa, no para la alerta). Si en iOS 26.x la alerta no aparece o se descarta sola, añadir esa configuración a nuestra extensión (con `RestAlarmMetadata` idéntica) es el siguiente paso.
- Que `.named("rest_alarm.caf")` encuentre el tono en la raíz del bundle; si suena el tono por defecto o nada, copiarlo a `Library/Sounds` antes de programar (lo que hace `flutter_alarmkit`).
- Carrera del último segundo en primer plano: si el tick cae a pocos ms del fin, la alarma puede llegar a sonar un instante antes de cancelarse.

**Probar en un iPhone con iOS 26:**
1. Primer descanso: aparece el diálogo de AlarmKit con el texto en español; aceptar.
2. Descanso corto (p. ej. 15 s), interruptor de silencio activado, bloquear la pantalla → al llegar a cero debe sonar como alarma (pantalla completa, "¡A entrenar!", botón detener) y no la notificación.
3. Igual con un Focus activo → debe sonar.
4. Saltar el descanso antes de cero → no suena nada. `+15 s` → suena 15 s más tarde.
5. App en primer plano mirando el descanso → al llegar a cero: háptico + snackbar + notificación, sin alarma a pantalla completa.
6. Dejar sonar la alarma y abrir la app → la alarma se detiene.
7. Denegar el permiso (Ajustes → app → Alarmas) → vuelve la notificación de P1.
8. iPhone con iOS < 26 → notificación de P1 (P1 sigue igual) y la app arranca sin crash (weak link).

## Fuera de alcance (requieren decisión del usuario)
- Crash reporting (Sentry/Crashlytics): necesita cuenta y DSN.
- Unificar bundle ids / App Group (`com.andergymtracker.gymFlutter` vs `group.com.gymtracker.gym_flutter`).
- Subir el iOS mínimo (13 → 15/16).
- Reemplazar los hacks del Podfile para el ciclo con la extensión (funcionan hoy).

## Nota 2026-10-21 — entitlement time-sensitive retirado
La firma con el equipo personal (cuenta gratuita, SMK6B9QBM9) falla con `Personal development teams ... do not support the Time Sensitive Notifications capability`. Se quitó `com.apple.developer.usernotifications.time-sensitive` de `ios/Runner/Runner.entitlements`. El código sigue pidiendo `InterruptionLevel.timeSensitive`; sin el entitlement iOS la trata como `active` (suena, pero no atraviesa Focus). En iOS 26+ la alarma de AlarmKit (P8) no depende de este entitlement. Al pasar a una cuenta Apple Developer de pago, volver a añadirlo y activar la capability en el App ID.
