import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Single source of truth para preguntar "¿esta plataforma puede X?".
///
/// **Regla del codebase:** widgets y blocs nunca deben leer `kIsWeb` /
/// `Platform.isXxx` directamente — siempre vía esta clase. Mantenemos
/// `kIsWeb` solo en este archivo, en `lib/injection_container.dart` y
/// en las parejas de conditional-imports (`*_stub.dart` / `*_web.dart`).
///
/// Cuando una plataforma gane/pierda soporte para una API, se ajusta
/// un getter acá y todos los call sites quedan correctos.
class Capabilities {
  Capabilities._();

  /// True si la app corre en un navegador (canvaskit/skwasm). Usar este
  /// flag solo cuando la lógica depende de "ser web" como concepto —
  /// para preguntas tipo "¿puedo X?" preferir el getter específico.
  static bool get isWeb => kIsWeb;

  // ── Persistencia ──────────────────────────────────────────────────────

  /// Base de datos local (drift + sqlite).
  ///   - Mobile/desktop: sqlite3 nativo via sqlite3_flutter_libs.
  ///   - Web: sqlite3 WASM en SharedWorker; persiste a OPFS o
  ///     IndexedDB según soporte del browser (Phase W activada).
  static bool get hasLocalDatabase => true;

  /// Outbox + sync worker para escrituras local-first. Acoplado a
  /// `hasLocalDatabase` porque depende del mismo store.
  static bool get hasOfflineSync => hasLocalDatabase;

  // ── Feedback táctil / sistema ─────────────────────────────────────────

  /// Vibración / haptic feedback. En web es no-op; preferir esconder
  /// affordances que dependan del feedback para feel.
  static bool get supportsHaptics => !kIsWeb;

  /// `SystemChrome.setPreferredOrientations` y similares. Solo aplican
  /// en mobile — en web/desktop el browser maneja la ventana.
  static bool get supportsOrientationLock => !kIsWeb;

  /// Pintar status/navigation bar via `SystemUiOverlayStyle`. Same.
  static bool get supportsSystemUiStyling => !kIsWeb;

  // ── Notificaciones ────────────────────────────────────────────────────

  /// Notificaciones locales nativas (`flutter_local_notifications`).
  /// Web tiene Notification API pero el plugin no la expone.
  static bool get supportsLocalNotifications {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// iOS Live Activities (Dynamic Island, iOS 16.1+).
  static bool get supportsLiveActivities {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }

  // ── UX / look-and-feel ────────────────────────────────────────────────

  /// Si la plataforma prefiere `BouncingScrollPhysics` (overscroll
  /// elástico iOS) sobre `ClampingScrollPhysics` (Android/web).
  static bool get prefersBouncePhysics {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isMacOS;
  }

  /// `BackdropFilter` con blur tiene costo alto en canvaskit. Los
  /// widgets adaptive (`AdaptiveBlur`) lo evitan en web y usan un tint
  /// sólido equivalente.
  static bool get supportsCheapBlur => !kIsWeb;

  /// En mobile las modales subiendo desde abajo (`BottomSheet`) son
  /// idiomáticas. En web (browser) un `Dialog` centrado se siente más
  /// nativo y aprovecha mejor la ventana.
  static bool get prefersBottomSheetForModals => !kIsWeb;
}
