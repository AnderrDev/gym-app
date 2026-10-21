import 'package:gym_flutter/core/notifications/live_activities_bridge.dart';
import 'package:gym_flutter/core/notifications/notification_service.dart';
import 'package:gym_flutter/core/observability/app_logger.dart';
import 'package:gym_flutter/core/services/active_session_service.dart';

/// Coordinador del feedback visual de "sesión activa" en la barra de notis.
///
/// En Android usa `NotificationService` (chronometer nativo de la noti).
/// En iOS 16.1+ usa `LiveActivitiesBridge` (lock screen + Dynamic Island).
/// En iOS pre-16.1 y otras plataformas cae al `NotificationService` con
/// noti estática como fallback.
///
/// Estados visuales:
/// - **workout-view**: chronometer asc. con tiempo total de sesión.
/// - **rest-view**: chronometer desc. con tiempo restante de descanso.
class ActiveWorkoutNotifier {
  ActiveWorkoutNotifier({
    required NotificationService notifications,
    required LiveActivitiesBridge liveActivities,
    required ActiveSessionService sessionService,
  }) : _notifications = notifications,
       _liveActivities = liveActivities,
       _sessionService = sessionService;

  final NotificationService _notifications;
  final LiveActivitiesBridge _liveActivities;
  final ActiveSessionService _sessionService;

  String? _dayName;
  DateTime? _sessionStartedAt;
  int _totalSets = 0;
  int _completedSets = 0;
  DateTime? _restEndsAt;

  /// True cuando preferimos la Live Activity (iOS 16.1+ con permiso). El
  /// notifier se asegura de no postear duplicados: si la LA está activa, no
  /// emite la noti tradicional encima.
  bool get _preferLiveActivity => _liveActivities.isAvailable;

  /// Reconstruye la notificación / Live Activity tras relanzar la app. El
  /// contexto persistido no incluye el progreso de series, así que arranca
  /// con `totalSets = 0`: las vistas ocultan el contador hasta el primer
  /// `onProgress` / `onPlanChanged`, en vez de mostrar "0/0 series".
  Future<void> bootstrapFromPersistedSession() async {
    // El arranque lo difiere tras el primer frame: si el usuario ya inició
    // (o reanudó) una sesión, `onStarted` es la fuente de verdad y no se
    // pisa con el contexto persistido (que no trae el progreso de series).
    if (_dayName != null) return;
    final ctx = _sessionService.getContext();
    if (ctx == null) return;
    _dayName = ctx.routineDayName;
    _sessionStartedAt = ctx.sessionDate;
    _totalSets = 0;
    _completedSets = 0;
    _restEndsAt = null;
    await _post(isStart: true);
  }

  Future<void> onStarted({
    required String dayName,
    required DateTime sessionStartedAt,
    required int totalSets,
  }) async {
    AppLogger.instance.info(
      'ActiveWorkoutNotifier: noti de sesión "$dayName" iniciada',
    );
    _dayName = dayName;
    _sessionStartedAt = sessionStartedAt;
    _totalSets = totalSets;
    _completedSets = 0;
    _restEndsAt = null;
    await _post(isStart: true);
  }

  Future<void> onProgress({required int completedSets}) async {
    if (_dayName == null || _sessionStartedAt == null) return;
    _completedSets = completedSets;
    await _post();
  }

  /// Cambiar ejercicios conserva el inicio y el descanso de la sesión.
  Future<void> onPlanChanged({
    required int totalSets,
    required int completedSets,
  }) async {
    _totalSets = totalSets;
    _completedSets = completedSets;
    if (_dayName != null && _sessionStartedAt != null) await _post();
  }

  Future<void> onRestStarted({required Duration duration}) async {
    if (_dayName == null) return;
    _restEndsAt = DateTime.now().add(duration);
    await _post();
  }

  /// Vuelve a la vista de entrenamiento (fin natural o descanso saltado).
  /// Es silencioso: el sonido de fin de descanso lo da la notificación
  /// programada (iOS) o `showRestEnded` (Android), no este update.
  Future<void> onRestEnded() async {
    if (_restEndsAt == null) return;
    _restEndsAt = null;
    if (_dayName == null) return;
    await _post();
  }

  Future<void> onEnded() async {
    if (_dayName == null && _sessionStartedAt == null) return;
    AppLogger.instance.info('ActiveWorkoutNotifier: noti cancelada');
    _dayName = null;
    _sessionStartedAt = null;
    _totalSets = 0;
    _completedSets = 0;
    _restEndsAt = null;
    await _liveActivities.end();
    await _notifications.cancelActiveWorkout();
  }

  Future<void> _post({bool isStart = false}) async {
    final dayName = _dayName;
    final startedAt = _sessionStartedAt;
    if (dayName == null || startedAt == null) return;

    // Hasta que el bridge termine su init `isAvailable` es false; esperarlo
    // evita caer a la noti tradicional cuando hay Live Activity.
    await _liveActivities.ready;
    if (_preferLiveActivity) {
      if (isStart) {
        await _liveActivities.start(
          dayName: dayName,
          sessionStartedAt: startedAt,
          totalSets: _totalSets,
        );
      } else {
        await _liveActivities.update(
          dayName: dayName,
          sessionStartedAt: startedAt,
          completedSets: _completedSets,
          totalSets: _totalSets,
          restEndsAt: _restEndsAt,
        );
      }
      return;
    }

    // Fallback Android + iOS pre-16.1.
    final seriesLabel = _totalSets > 0
        ? '$_completedSets/$_totalSets series'
        : '$_completedSets series';

    final restEnd = _restEndsAt;
    if (restEnd != null) {
      await _notifications.showActiveWorkout(
        title: 'Descanso · $dayName',
        body: seriesLabel,
        chronoAnchor: restEnd,
        countdown: true,
      );
      return;
    }

    await _notifications.showActiveWorkout(
      title: dayName,
      body: seriesLabel,
      chronoAnchor: startedAt,
    );
  }
}
