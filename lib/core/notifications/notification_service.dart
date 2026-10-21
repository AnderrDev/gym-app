import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

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
      'Notificación persistente mientras tienes un entrenamiento en curso';

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

  /// Nombre del archivo de sonido de fin de descanso en el bundle iOS.
  static const String restAlarmSoundIos = 'rest_alarm.caf';

  bool _initialized = false;
  Future<void>? _initFuture;

  bool get _isSupported => Capabilities.supportsLocalNotifications;

  /// Inicializa el plugin. Idempotente y compartido: llamadas concurrentes
  /// (el arranque diferido de `main.dart` y un uso temprano desde la UI)
  /// esperan al mismo `Future`. Si falla, se puede reintentar.
  Future<void> init() {
    if (!_isSupported || _initialized) return Future<void>.value();
    return _initFuture ??= _doInit().catchError((Object e) {
      _initFuture = null;
      throw e;
    });
  }

  Future<void> _doInit() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      // Permisos se piden explícitamente vía requestPermission().
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
    );
    // No se carga la base IANA (`initializeTimeZones`): se programa en
    // `tz.UTC` (instante absoluto), que es una constante del paquete y el
    // plugin no consulta `tz.local`.

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
      await init();
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
      await init();
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
        id: activeWorkoutNotificationId,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
      );
    } catch (e) {
      AppLogger.instance.warning('NotificationService.showActiveWorkout: $e');
    }
  }

  Future<void> cancelActiveWorkout() async {
    if (!_isSupported) return;
    try {
      await init();
      await _plugin.cancel(id: activeWorkoutNotificationId);
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
      await init();
      await _plugin.show(
        id: restEndNotificationId,
        title: '¡A entrenar!',
        body: 'Próxima serie te espera',
        notificationDetails: _restEndDetails(),
      );
    } catch (e) {
      AppLogger.instance.warning('NotificationService.showRestEnded: $e');
    }
  }

  /// Programa la alerta de fin de descanso en el sistema. En iOS la app se
  /// suspende con la pantalla bloqueada y el `Timer` de Dart no dispara:
  /// sólo una notificación programada suena a tiempo. Reprogramar con el
  /// mismo id sustituye a la anterior.
  Future<void> scheduleRestEnded(Duration after) async {
    if (!_isSupported) return;
    try {
      // El init puede estar diferido tras el primer frame: se espera (o se
      // fuerza) en vez de descartar el aviso de descanso.
      await init();
      if (!_initialized) return;
      // Desde flutter_local_notifications 19 no existe
      // `uiLocalNotificationDateInterpretation`: en iOS el trigger se arma
      // con la fecha en la zona del `TZDateTime` (UTC → instante absoluto),
      // igual que hacía `absoluteTime`.
      await _plugin.zonedSchedule(
        id: restEndNotificationId,
        title: '¡A entrenar!',
        body: 'Próxima serie te espera',
        scheduledDate: tz.TZDateTime.now(tz.UTC).add(after),
        notificationDetails: _restEndDetails(),
        // Inexacta: no requiere el permiso de alarmas exactas. En Android la
        // alerta la da el Timer (el proceso sigue vivo en segundo plano).
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      AppLogger.instance.warning('NotificationService.scheduleRestEnded: $e');
    }
  }

  /// Cancela la alerta programada (descanso saltado, ajustado o terminado
  /// con la app en primer plano).
  Future<void> cancelRestEnded() async {
    if (!_isSupported) return;
    try {
      await init();
      await _plugin.cancel(id: restEndNotificationId);
    } catch (e) {
      AppLogger.instance.warning('NotificationService.cancelRestEnded: $e');
    }
  }

  NotificationDetails _restEndDetails() {
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
      // Tono propio (≤ 30 s) empaquetado en el bundle de Runner
      // (`ios/Runner/rest_alarm.caf`, fase Resources). iOS respeta el
      // interruptor de silencio salvo con AlarmKit (P8).
      sound: restAlarmSoundIos,
      // Requiere el entitlement
      // `com.apple.developer.usernotifications.time-sensitive`.
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }
}
