import 'dart:async';

import 'package:gym_flutter/core/notifications/alarm_kit_bridge.dart';
import 'package:gym_flutter/core/notifications/notification_service.dart';
import 'package:gym_flutter/core/observability/app_logger.dart';
import 'package:gym_flutter/core/utils/clock.dart';

/// Aviso **programado en el sistema** para el fin del descanso (iOS).
///
/// `RestTimerController` solo habla con esta abstracción; qué mecanismo
/// suena (alarma de AlarmKit o notificación local de P1) es un detalle de la
/// implementación.
abstract class RestAlarmScheduler {
  /// Programa (o reprograma) el aviso para [endsAt], sustituyendo al anterior.
  Future<void> schedule(DateTime endsAt);

  /// La app está en primer plano en el último segundo del descanso: si el
  /// aviso es una alarma de AlarmKit se cambia por la notificación, para que
  /// en pantalla no salte la alarma a pantalla completa (basta háptico +
  /// snackbar + notificación).
  Future<void> switchToNotification(DateTime endsAt);

  /// Descanso saltado/parado a mano: no debe sonar nada.
  Future<void> cancel();

  /// Fin natural detectado por la app: detiene la alarma de AlarmKit si está
  /// sonando. La notificación ya presentada no se toca.
  Future<void> onRestFinished();
}

/// Qué está programado ahora mismo.
enum _Source { none, alarmKit, notification }

/// iOS 26+ con autorización → AlarmKit (suena con el modo silencio y Focus).
/// iOS < 26, autorización denegada o error → notificación local de P1.
///
/// Las operaciones se encadenan en serie: `start` + `adjust` seguidos (o el
/// diálogo de autorización abierto) no pueden dejar dos avisos vivos ni
/// aplicarse en desorden. Por eso la API recibe la hora de fin absoluta y el
/// restante se calcula al ejecutar.
class AlarmKitRestAlarmScheduler implements RestAlarmScheduler {
  AlarmKitRestAlarmScheduler({
    required NotificationService notifications,
    required AlarmKitBridge alarmKit,
    Clock clock = const SystemClock(),
  }) : _notifications = notifications,
       _alarmKit = alarmKit,
       _clock = clock;

  final NotificationService _notifications;
  final AlarmKitBridge _alarmKit;
  final Clock _clock;

  _Source _source = _Source.none;
  Future<void> _queue = Future<void>.value();

  Future<void> _enqueue(Future<void> Function() op) {
    final next = _queue.then((_) => op()).catchError((Object e) {
      AppLogger.instance.warning('RestAlarmScheduler: $e');
    });
    _queue = next;
    return next;
  }

  Duration _remaining(DateTime endsAt) => endsAt.difference(_clock.now());

  Future<void> _scheduleNotification(DateTime endsAt) async {
    final remaining = _remaining(endsAt);
    if (remaining <= Duration.zero) return;
    await _notifications.scheduleRestEnded(remaining);
    _source = _Source.notification;
  }

  @override
  Future<void> schedule(DateTime endsAt) => _enqueue(() async {
    var auth = await _alarmKit.authorizationState();
    var covered = false;
    if (auth == AlarmKitAuthorization.notDetermined) {
      // Primer descanso: cobertura con la notificación mientras el usuario
      // responde al diálogo de AlarmKit.
      await _scheduleNotification(endsAt);
      covered = true;
      auth = await _alarmKit.requestAuthorization();
    }
    if (auth == AlarmKitAuthorization.authorized &&
        _remaining(endsAt) > Duration.zero &&
        await _alarmKit.scheduleAt(endsAt)) {
      // Una sola fuente de sonido: fuera la notificación de P1.
      await _notifications.cancelRestEnded();
      _source = _Source.alarmKit;
      return;
    }
    if (_source == _Source.alarmKit) await _alarmKit.cancelAll();
    if (!covered) await _scheduleNotification(endsAt);
  });

  @override
  Future<void> switchToNotification(DateTime endsAt) => _enqueue(() async {
    if (_source != _Source.alarmKit) return;
    if (_remaining(endsAt) <= Duration.zero) return;
    // Primero la notificación y luego cancelar la alarma: nunca queda un
    // hueco sin aviso.
    await _scheduleNotification(endsAt);
    await _alarmKit.cancelAll();
  });

  @override
  Future<void> cancel() => _enqueue(() async {
    if (_source == _Source.alarmKit) await _alarmKit.cancelAll();
    await _notifications.cancelRestEnded();
    _source = _Source.none;
  });

  @override
  Future<void> onRestFinished() => _enqueue(() async {
    if (_source == _Source.alarmKit) await _alarmKit.cancelAll();
    _source = _Source.none;
  });
}
