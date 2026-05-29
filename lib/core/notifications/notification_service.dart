import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:gym_flutter/core/observability/app_logger.dart';
import 'package:gym_flutter/core/platform/capabilities.dart';

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

  /// Canal separado para la alerta de "fin del descanso". `Importance.high`
  /// para que suene y vibre, channel propio para que el usuario lo pueda
  /// configurar (silenciar la sesión activa sin perder la alerta de fin
  /// de descanso, por ejemplo).
  static const _restEndChannelId = 'rest_end';
  static const _restEndChannelName = 'Fin del descanso';
  static const _restEndChannelDesc =
      'Sonido + vibración cuando termina el descanso entre series';

  /// ID fijo para la única noti de sesión activa. Reusarla permite que
  /// `show()` actúe como update sin duplicar entradas.
  static const int activeWorkoutNotificationId = 1001;
  static const int restEndNotificationId = 1002;

  bool _initialized = false;

  bool get _isSupported => Capabilities.supportsLocalNotifications;

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
    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(
        _restEndChannelId,
        _restEndChannelName,
        description: _restEndChannelDesc,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        // Pattern corta-pausa-corta: 250ms vibra, 100ms silencio, 250ms vibra.
        vibrationPattern: Int64List.fromList([0, 250, 100, 250]),
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
  ///
  /// [chronoAnchor] activa el chronometer nativo de Android:
  /// - count-up (default): `chronoAnchor` es el momento de inicio; el sistema
  ///   cuenta hacia adelante. Para la vista de sesión activa.
  /// - count-down ([countdown] = true): `chronoAnchor` es el target en el
  ///   futuro (ej. fin del descanso); el sistema cuenta hacia atrás.
  ///
  /// En iOS no hay equivalente nativo pre-Live-Activities, así que el body
  /// queda estático en ambos modos.
  Future<void> showActiveWorkout({
    required String title,
    required String body,
    DateTime? chronoAnchor,
    bool countdown = false,
  }) async {
    if (!_isSupported) return;
    try {
      final androidDetails = AndroidNotificationDetails(
        _activeChannelId,
        _activeChannelName,
        channelDescription: _activeChannelDesc,
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        showWhen: chronoAnchor != null,
        when: chronoAnchor?.millisecondsSinceEpoch,
        usesChronometer: chronoAnchor != null,
        chronometerCountDown: countdown,
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
        NotificationDetails(android: androidDetails, iOS: iosDetails),
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

  /// Alerta one-shot al terminar el descanso: sonido + vibración + mensaje.
  /// Usa el channel `_restEndChannelId` (Importance.high) y respeta el modo
  /// silencio del dispositivo (no usa `criticalAlert`).
  Future<void> showRestEnded() async {
    if (!_isSupported) return;
    try {
      final androidDetails = AndroidNotificationDetails(
        _restEndChannelId,
        _restEndChannelName,
        channelDescription: _restEndChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 250, 100, 250]),
        autoCancel: true,
        ongoing: false,
        ticker: '¡A entrenar!',
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );
      await _plugin.show(
        restEndNotificationId,
        '¡A entrenar!',
        'Próxima serie te espera',
        NotificationDetails(android: androidDetails, iOS: iosDetails),
      );
    } catch (e) {
      AppLogger.instance.warning('NotificationService.showRestEnded: $e');
    }
  }
}
