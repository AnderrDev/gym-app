import 'package:flutter/services.dart';

import 'package:gym_flutter/core/observability/app_logger.dart';
import 'package:gym_flutter/core/platform/capabilities.dart';

/// Estado de autorización de AlarmKit tal como lo reporta el canal nativo.
enum AlarmKitAuthorization {
  /// Plataforma sin AlarmKit (iOS < 26, Android, web) o canal no disponible.
  unsupported,
  notDetermined,
  denied,
  authorized,
}

/// Puente fino al canal nativo `RestAlarmChannel` (`ios/Runner/`), que
/// programa la alarma de fin de descanso con AlarmKit (iOS 26+).
///
/// Ninguna llamada lanza: un error del canal se loguea y se traduce a
/// `unsupported` / `false`, para que el llamador caiga a la notificación.
class AlarmKitBridge {
  AlarmKitBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'com.gymtracker.gym_flutter/rest_alarm';

  final MethodChannel _channel;

  /// Solo iOS registra el canal; la versión (26+) la decide el lado nativo.
  bool get _isSupported => Capabilities.mayUseAlarmKit;

  Future<AlarmKitAuthorization> authorizationState() =>
      _invokeAuthorization('authorizationState');

  /// Muestra el diálogo del sistema si aún no se decidió.
  Future<AlarmKitAuthorization> requestAuthorization() =>
      _invokeAuthorization('requestAuthorization');

  /// Programa la alarma para [endsAt] sustituyendo cualquier otra de la app.
  /// Devuelve `true` si AlarmKit la aceptó.
  Future<bool> scheduleAt(DateTime endsAt) async {
    if (!_isSupported) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('schedule', {
        'epochMs': endsAt.millisecondsSinceEpoch.toDouble(),
      });
      return ok ?? false;
    } catch (e) {
      AppLogger.instance.warning('AlarmKitBridge.scheduleAt: $e');
      return false;
    }
  }

  /// Detiene la alarma que esté sonando y cancela las programadas.
  Future<void> cancelAll() async {
    if (!_isSupported) return;
    try {
      await _channel.invokeMethod<void>('cancelAll');
    } catch (e) {
      AppLogger.instance.warning('AlarmKitBridge.cancelAll: $e');
    }
  }

  Future<AlarmKitAuthorization> _invokeAuthorization(String method) async {
    if (!_isSupported) return AlarmKitAuthorization.unsupported;
    try {
      final raw = await _channel.invokeMethod<String>(method);
      return AlarmKitAuthorization.values.firstWhere(
        (value) => value.name == raw,
        orElse: () => AlarmKitAuthorization.unsupported,
      );
    } catch (e) {
      AppLogger.instance.warning('AlarmKitBridge.$method: $e');
      return AlarmKitAuthorization.unsupported;
    }
  }
}
