import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:gym_flutter/core/notifications/active_workout_notifier.dart';
import 'package:gym_flutter/core/notifications/notification_service.dart';
import 'package:gym_flutter/core/notifications/rest_alarm_scheduler.dart';
import 'package:gym_flutter/core/platform/capabilities.dart';
import 'package:gym_flutter/core/utils/clock.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/rest_timer_button.dart';

/// Controla el countdown de descanso entre series para `RoutineDayPage`.
///
/// Posee:
/// - El `Timer.periodic` que refresca el contador cada segundo. La cuenta se
///   calcula contra la hora de fin ([Clock]), no contando ticks: con la
///   pantalla bloqueada o la pestaña en segundo plano los ticks se congelan,
///   y al volver el contador debe mostrar el tiempo real restante.
/// - El `ValueNotifier<RestTimerSnapshot>` que el botón observa para
///   rebuildearse sin afectar al resto del scaffold.
/// - Las integraciones laterales (haptic, Live Activity vía [notifier],
///   notificación local, aviso programado vía [RestAlarmScheduler]).
///
/// Para mantener al controller libre de `BuildContext`, el fin natural notifica
/// vía el callback [onNaturalEnd] — la UI decide cómo presentarlo (snackbar,
/// toast, etc.).
class RestTimerController {
  RestTimerController({
    required this.notifier,
    required this.notifications,
    required this.restAlarm,
    this.onNaturalEnd,
    this.clock = const SystemClock(),
    @visibleForTesting bool? scheduledAlertOverride,
    @visibleForTesting bool Function()? isForeground,
  }) : _scheduledAlertOverride = scheduledAlertOverride,
       _isForeground = isForeground ?? _appIsResumed;

  final bool? _scheduledAlertOverride;
  final bool Function() _isForeground;

  static bool _appIsResumed() =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  final ActiveWorkoutNotifier notifier;
  final NotificationService notifications;

  /// Aviso programado de fin de descanso (iOS): alarma de AlarmKit en
  /// iOS 26+ o notificación local como fallback.
  final RestAlarmScheduler restAlarm;
  final VoidCallback? onNaturalEnd;
  final Clock clock;

  final ValueNotifier<RestTimerSnapshot> snapshot = ValueNotifier(
    const RestTimerSnapshot.idle(),
  );

  Timer? _timer;
  DateTime? _endsAt;

  /// Ya se pidió pasar el aviso a notificación en el último segundo.
  bool _switchedToNotification = false;

  /// `true` cuando el fin del descanso se avisa con una notificación local
  /// **programada en el sistema** (`zonedSchedule`) en vez del `Timer`.
  ///
  /// Por qué en iOS siempre, haya o no Live Activity: con la app en segundo
  /// plano o la pantalla bloqueada iOS suspende el proceso y Dart no corre.
  /// La Live Activity sigue contando sola (el countdown es nativo), pero el
  /// aviso sonoro no puede depender de un `updateActivity` con `alertConfig`
  /// disparado desde el `Timer`, porque ese código no se ejecuta a tiempo.
  /// El aviso programado es por eso la ÚNICA fuente de sonido en iOS (la Live
  /// Activity ya no manda `alertConfig`, así no hay duplicados). Qué suena lo
  /// decide [restAlarm]: alarma de AlarmKit (iOS 26+) o notificación local.
  ///
  /// En Android el proceso sigue vivo en segundo plano: el `Timer` llega a
  /// cero y avisa con `showRestEnded`, sin programar nada.
  ///
  /// [scheduledAlertOverride] permite fijar el valor en tests (que corren en
  /// el host, donde `Capabilities` no reporta iOS).
  bool get _usesScheduledAlert =>
      _scheduledAlertOverride ?? Capabilities.schedulesRestEndAlert;

  void dispose() {
    _timer?.cancel();
    snapshot.dispose();
  }

  void start(int seconds) {
    _timer?.cancel();
    if (seconds <= 0) {
      _endsAt = null;
      snapshot.value = const RestTimerSnapshot.idle();
      return;
    }
    final endsAt = clock.now().add(Duration(seconds: seconds));
    _endsAt = endsAt;
    _switchedToNotification = false;
    snapshot.value = RestTimerSnapshot(
      isResting: true,
      secondsRemaining: seconds,
      totalRestSeconds: seconds,
    );
    unawaited(notifier.onRestStarted(duration: Duration(seconds: seconds)));
    if (_usesScheduledAlert) {
      unawaited(restAlarm.schedule(endsAt));
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  int _remainingSeconds() {
    final endsAt = _endsAt;
    if (endsAt == null) return 0;
    final ms = endsAt.difference(clock.now()).inMilliseconds;
    // Redondeo hacia arriba: con 0.4s restantes se sigue mostrando "1".
    return ms <= 0 ? 0 : (ms + 999) ~/ 1000;
  }

  /// Recalcula el restante contra el reloj. Lo llama el `Timer.periodic`;
  /// expuesto para tests.
  @visibleForTesting
  void tick() {
    final current = snapshot.value;
    if (!current.isResting) return;
    final next = _remainingSeconds();
    if (next <= 0) {
      _onNaturalEnd();
      return;
    }
    _maybeSwitchToNotification(next);
    if (next == current.secondsRemaining) return;
    snapshot.value = RestTimerSnapshot(
      isResting: true,
      secondsRemaining: next,
      totalRestSeconds: current.totalRestSeconds,
    );
    if (next <= 3) HapticFeedback.lightImpact();
  }

  /// En el último segundo, con la app en primer plano, la alarma de
  /// AlarmKit se cambia por la notificación: el usuario está mirando la app
  /// y una alarma a pantalla completa sobra. Si la app está en segundo plano
  /// o la pantalla bloqueada, Dart no llega aquí y la alarma suena.
  void _maybeSwitchToNotification(int remaining) {
    final endsAt = _endsAt;
    if (!_usesScheduledAlert || _switchedToNotification || endsAt == null) {
      return;
    }
    if (remaining > 1 || !_isForeground()) return;
    _switchedToNotification = true;
    unawaited(restAlarm.switchToNotification(endsAt));
  }

  void _onNaturalEnd() {
    // Fin NATURAL del descanso. En iOS el sistema ya presenta el aviso
    // programado al llegar a cero (también en primer plano), así que no
    // posteamos otro; si era una alarma de AlarmKit y sigue sonando (la app
    // vuelve a primer plano tras el fin) se detiene. En Android el Timer es
    // quien avisa.
    if (_usesScheduledAlert) {
      unawaited(restAlarm.onRestFinished());
    } else {
      unawaited(notifications.showRestEnded());
    }
    HapticFeedback.vibrate();
    stop(naturalEnd: true);
    onNaturalEnd?.call();
  }

  void stop({bool naturalEnd = false}) {
    _timer?.cancel();
    _endsAt = null;
    snapshot.value = const RestTimerSnapshot.idle();
    // En el fin natural ya vibró `_onNaturalEnd`; no encadenar otra.
    if (!naturalEnd) {
      HapticFeedback.heavyImpact();
      // Descanso saltado/parado a mano: la alerta programada ya no toca. En
      // el fin natural NO se cancela: es la que está sonando/por sonar.
      if (_usesScheduledAlert) unawaited(restAlarm.cancel());
    }
    unawaited(notifier.onRestEnded());
  }

  /// Ajusta el descanso en curso. Si quedaría <= 0, lo detiene.
  void adjust(int delta) {
    final current = snapshot.value;
    if (!current.isResting) return;
    final newRemaining = _remainingSeconds() + delta;
    if (newRemaining <= 0) {
      stop();
      return;
    }
    // `totalRestSeconds` es el denominador de la progress bar. Mantenemos el
    // total como el máximo histórico — si el usuario suma más allá del peak,
    // lo expandimos para que el bar muestre 100% (lleno) momentáneamente.
    final newTotal = newRemaining > current.totalRestSeconds
        ? newRemaining
        : current.totalRestSeconds;
    final endsAt = clock.now().add(Duration(seconds: newRemaining));
    _endsAt = endsAt;
    _switchedToNotification = false;
    snapshot.value = RestTimerSnapshot(
      isResting: true,
      secondsRemaining: newRemaining,
      totalRestSeconds: newTotal,
    );
    // Re-sincronizamos el countdown nativo con el nuevo remaining para que
    // el chronometer del lock screen muestre el ajuste.
    unawaited(
      notifier.onRestStarted(duration: Duration(seconds: newRemaining)),
    );
    // Reprogramar sustituye el aviso anterior (alarma o notificación).
    if (_usesScheduledAlert) unawaited(restAlarm.schedule(endsAt));
  }
}
