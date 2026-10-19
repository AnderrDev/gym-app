import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/notifications/active_workout_notifier.dart';
import 'package:gym_flutter/core/notifications/live_activities_bridge.dart';
import 'package:gym_flutter/core/notifications/notification_service.dart';
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
/// - Las integraciones laterales (haptic, Live Activity, notificación push).
///
/// Para mantener al controller libre de `BuildContext`, el fin natural notifica
/// vía el callback [onNaturalEnd] — la UI decide cómo presentarlo (snackbar,
/// toast, etc.).
class RestTimerController {
  RestTimerController({
    required this.notifier,
    required this.liveActivities,
    required this.notifications,
    this.onNaturalEnd,
    this.clock = const SystemClock(),
    @visibleForTesting bool? scheduledAlertOverride,
  }) : _scheduledAlertOverride = scheduledAlertOverride;

  final bool? _scheduledAlertOverride;

  final ActiveWorkoutNotifier notifier;
  final LiveActivitiesBridge liveActivities;
  final NotificationService notifications;
  final VoidCallback? onNaturalEnd;
  final Clock clock;

  final ValueNotifier<RestTimerSnapshot> snapshot = ValueNotifier(
    const RestTimerSnapshot.idle(),
  );

  Timer? _timer;
  DateTime? _endsAt;

  /// iOS sin Live Activity: la app se suspende con la pantalla bloqueada y
  /// ni el Timer ni `showRestEnded` llegan a tiempo, así que el fin del
  /// descanso se programa en el sistema. Con Live Activity ya avisa su
  /// `AlertConfig`; en Android el proceso sigue vivo y avisa el Timer.
  bool get _usesScheduledAlert =>
      _scheduledAlertOverride ??
      (Capabilities.supportsLiveActivities && !liveActivities.isAvailable);

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
    _endsAt = clock.now().add(Duration(seconds: seconds));
    snapshot.value = RestTimerSnapshot(
      isResting: true,
      secondsRemaining: seconds,
      totalRestSeconds: seconds,
    );
    unawaited(notifier.onRestStarted(duration: Duration(seconds: seconds)));
    if (_usesScheduledAlert) {
      unawaited(notifications.scheduleRestEnded(Duration(seconds: seconds)));
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
    if (next == current.secondsRemaining) return;
    snapshot.value = RestTimerSnapshot(
      isResting: true,
      secondsRemaining: next,
      totalRestSeconds: current.totalRestSeconds,
    );
    if (next <= 3) HapticFeedback.lightImpact();
  }

  void _onNaturalEnd() {
    // Fin NATURAL del descanso. Multi-canal de feedback evitando duplicados:
    // si la Live Activity está activa, su `AlertConfig` ya muestra
    // banner+sonido en iOS → omitimos el push del sistema. En Android (sin
    // LA) sí firamos el push tradicional.
    if (!liveActivities.isAvailable && !_usesScheduledAlert) {
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
      // Descanso saltado: la alerta programada ya no toca.
      if (_usesScheduledAlert) unawaited(notifications.cancelRestEnded());
    }
    unawaited(notifier.onRestEnded(naturalEnd: naturalEnd));
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
    _endsAt = clock.now().add(Duration(seconds: newRemaining));
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
    if (_usesScheduledAlert) {
      unawaited(
        notifications.scheduleRestEnded(Duration(seconds: newRemaining)),
      );
    }
  }
}
