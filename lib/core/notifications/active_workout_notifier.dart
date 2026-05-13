import 'package:gym_flutter/core/notifications/notification_service.dart';
import 'package:gym_flutter/core/observability/app_logger.dart';
import 'package:gym_flutter/core/services/active_session_service.dart';

/// Coordinador entre el `ActiveWorkoutBloc` y el `NotificationService`.
/// El bloc llama `onStarted` / `onProgress` / `onEnded` en los handlers
/// relevantes; el notifier proyecta esa info al copy de la noti persistente.
///
/// MVP Fase 1: una sola noti estática "Día X · N/M series · iniciado HH:MM".
/// Cronómetro vivo y vista de descanso vienen en fases posteriores.
class ActiveWorkoutNotifier {
  ActiveWorkoutNotifier({
    required NotificationService notifications,
    required ActiveSessionService sessionService,
  }) : _notifications = notifications,
       _sessionService = sessionService;

  final NotificationService _notifications;
  final ActiveSessionService _sessionService;

  // Snapshot interno para que `onProgress` no necesite re-recibir dayName/
  // sessionStartedAt cada vez. Se setea en `onStarted` y se limpia en `onEnded`.
  String? _dayName;
  DateTime? _sessionStartedAt;
  int _totalSets = 0;

  /// Re-pone la noti si encontramos una sesión persistida en
  /// `ActiveSessionService` (caso típico: la app fue killed o relanzada en
  /// el medio de un workout). Llamado desde `main.dart` tras `di.init()`.
  Future<void> bootstrapFromPersistedSession() async {
    final ctx = _sessionService.getContext();
    if (ctx == null) return;
    _dayName = ctx.routineDayName;
    _sessionStartedAt = ctx.sessionDate;
    _totalSets = 0;
    await _post(completedSets: 0);
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
    await _post(completedSets: 0);
  }

  Future<void> onProgress({required int completedSets}) async {
    if (_dayName == null || _sessionStartedAt == null) return;
    await _post(completedSets: completedSets);
  }

  Future<void> onEnded() async {
    if (_dayName == null && _sessionStartedAt == null) {
      return;
    }
    AppLogger.instance.info('ActiveWorkoutNotifier: noti cancelada');
    _dayName = null;
    _sessionStartedAt = null;
    _totalSets = 0;
    await _notifications.cancelActiveWorkout();
  }

  Future<void> _post({required int completedSets}) async {
    final dayName = _dayName;
    final startedAt = _sessionStartedAt;
    if (dayName == null || startedAt == null) return;
    final seriesLabel = _totalSets > 0
        ? '$completedSets/$_totalSets series'
        : '$completedSets series';
    final hh = startedAt.hour.toString().padLeft(2, '0');
    final mm = startedAt.minute.toString().padLeft(2, '0');
    await _notifications.showActiveWorkout(
      title: dayName,
      body: '$seriesLabel · iniciado $hh:$mm',
    );
  }
}
