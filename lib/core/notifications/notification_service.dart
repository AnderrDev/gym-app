import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:gym_flutter/core/observability/app_logger.dart';

/// Wrapper fino sobre `flutter_local_notifications`. Centraliza el setup, los
/// permisos y el channel Android para que el resto del app no toque el plugin
/// directo. Es plataforma-aware: en web todas las llamadas son no-ops.
class NotificationService {
  NotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  /// Canal único para la noti de sesión activa. `Importance.low` evita
  /// sonido/vibración de cada update (la noti es informativa, no alerta).
  static const _activeChannelId = 'active_workout';
  static const _activeChannelName = 'Sesión activa';
  static const _activeChannelDesc =
      'Notificación persistente mientras tenés un entrenamiento en curso';

  /// ID fijo para la única noti de sesión activa. Reusarla permite que
  /// `show()` actúe como update sin duplicar entradas.
  static const int activeWorkoutNotificationId = 1001;

  bool _initialized = false;

  bool get _isSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<void> init() async {
    if (!_isSupported || _initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      // Permisos se piden explícitamente vía requestPermission().
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _activeChannelId,
        _activeChannelName,
        description: _activeChannelDesc,
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      ),
    );

    _initialized = true;
  }

  /// Pide permiso de notis. Devuelve `true` si quedó concedido (o si la
  /// plataforma no lo requiere). Idempotente: si ya estaba concedido, no
  /// re-prompta.
  Future<bool> requestPermission() async {
    if (!_isSupported) return false;
    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final grantedAndroid =
          await androidPlugin?.requestNotificationsPermission() ?? true;

      final iosPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final grantedIos =
          await iosPlugin?.requestPermissions(
            alert: true,
            badge: false,
            sound: true,
          ) ??
          true;

      return grantedAndroid && grantedIos;
    } catch (e) {
      AppLogger.instance.warning('NotificationService.requestPermission: $e');
      return false;
    }
  }

  /// Muestra (o actualiza) la noti persistente de sesión activa.
  /// Reusa el mismo id para que sea un update silencioso, no una alerta nueva.
  Future<void> showActiveWorkout({
    required String title,
    required String body,
  }) async {
    if (!_isSupported) return;
    try {
      const androidDetails = AndroidNotificationDetails(
        _activeChannelId,
        _activeChannelName,
        channelDescription: _activeChannelDesc,
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        showWhen: false,
        playSound: false,
        enableVibration: false,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
        interruptionLevel: InterruptionLevel.passive,
      );
      await _plugin.show(
        activeWorkoutNotificationId,
        title,
        body,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
      );
    } catch (e) {
      AppLogger.instance.warning('NotificationService.showActiveWorkout: $e');
    }
  }

  Future<void> cancelActiveWorkout() async {
    if (!_isSupported) return;
    try {
      await _plugin.cancel(activeWorkoutNotificationId);
    } catch (e) {
      AppLogger.instance.warning('NotificationService.cancelActiveWorkout: $e');
    }
  }
}
