import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/notifications/active_workout_notifier.dart';
import 'package:gym_flutter/core/notifications/live_activities_bridge.dart';
import 'package:gym_flutter/core/notifications/notification_service.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/rest_timer_button.dart';

/// Controla el countdown de descanso entre series para `RoutineDayPage`.
///
/// Posee:
/// - El `Timer.periodic` que decrementa el contador cada segundo.
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
  });

  final ActiveWorkoutNotifier notifier;
  final LiveActivitiesBridge liveActivities;
  final NotificationService notifications;
  final VoidCallback? onNaturalEnd;

  final ValueNotifier<RestTimerSnapshot> snapshot = ValueNotifier(
    const RestTimerSnapshot.idle(),
  );

  Timer? _timer;

  void dispose() {
    _timer?.cancel();
    snapshot.dispose();
  }

  void start(int seconds) {
    _timer?.cancel();
    snapshot.value = RestTimerSnapshot(
      isResting: true,
      secondsRemaining: seconds,
      totalRestSeconds: seconds,
    );
    unawaited(notifier.onRestStarted(duration: Duration(seconds: seconds)));
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = snapshot.value;
      if (current.secondsRemaining > 0) {
        final next = current.secondsRemaining - 1;
        snapshot.value = RestTimerSnapshot(
          isResting: true,
          secondsRemaining: next,
          totalRestSeconds: current.totalRestSeconds,
        );
        if (next > 0 && next <= 3) HapticFeedback.lightImpact();
      } else {
        _onNaturalEnd();
      }
    });
  }

  void _onNaturalEnd() {
    // Fin NATURAL del descanso. Multi-canal de feedback evitando duplicados:
    // si la Live Activity está activa, su `AlertConfig` ya muestra
    // banner+sonido en iOS → omitimos el push del sistema. En Android (sin
    // LA) sí firamos el push tradicional.
    if (!liveActivities.isAvailable) {
      unawaited(notifications.showRestEnded());
    }
    HapticFeedback.vibrate();
    stop(naturalEnd: true);
    onNaturalEnd?.call();
  }

  void stop({bool naturalEnd = false}) {
    _timer?.cancel();
    snapshot.value = const RestTimerSnapshot.idle();
    HapticFeedback.heavyImpact();
    unawaited(notifier.onRestEnded(naturalEnd: naturalEnd));
  }

  /// Ajusta el descanso en curso. Si quedaría <= 0, lo detiene.
  void adjust(int delta) {
    final current = snapshot.value;
    if (!current.isResting) return;
    final newRemaining = current.secondsRemaining + delta;
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
  }
}
