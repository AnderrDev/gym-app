import 'package:flutter/foundation.dart';

import 'package:gym_flutter/core/observability/app_logger.dart';

/// Centraliza el reporte de errores no manejados de la app.
///
/// Capa fina sobre [AppLogger] que actúa como handler para los hooks de Flutter
/// ([FlutterError.onError], [PlatformDispatcher.onError]) y como sink para
/// errores capturados por [runZonedGuarded] en `main.dart`.
class ErrorReporter {
  const ErrorReporter._();

  /// Handler para errores del framework Flutter (build/layout/paint, gestos).
  static void onFlutterError(FlutterErrorDetails details) {
    AppLogger.instance.handle(details.exception, details.stack, 'flutter');
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  }

  /// Handler para errores asíncronos no capturados a nivel de plataforma.
  /// Debe retornar `true` para indicar que el error fue manejado.
  static bool onPlatformError(Object error, StackTrace stack) {
    AppLogger.instance.handle(error, stack, 'platform');
    return true;
  }

  /// Sink para [runZonedGuarded] y reportes manuales (`catch` explícitos).
  static void report(Object error, StackTrace stack, {String? context}) {
    AppLogger.instance.handle(error, stack, context ?? 'zone');
  }
}
