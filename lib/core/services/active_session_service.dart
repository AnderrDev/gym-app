import 'package:shared_preferences/shared_preferences.dart';

/// Persiste el contexto de la sesión activa en SharedPreferences.
/// Esto permite reanudación automática si el usuario cierra o pone en
/// segundo plano la app durante un entrenamiento.
class ActiveSessionService {
  static const _keySessionId = 'active_session_id';
  static const _keyRoutineDayId = 'active_routine_day_id';
  static const _keyUserId = 'active_user_id';
  static const _keySessionDate = 'active_session_date';
  static const _keyRoutineDayName = 'active_routine_day_name';

  final SharedPreferences prefs;

  ActiveSessionService(this.prefs);

  Future<void> save({
    required String sessionId,
    required String routineDayId,
    required String userId,
    required DateTime sessionDate,
    required String routineDayName,
  }) async {
    await prefs.setString(_keySessionId, sessionId);
    await prefs.setString(_keyRoutineDayId, routineDayId);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keySessionDate, sessionDate.toIso8601String());
    await prefs.setString(_keyRoutineDayName, routineDayName);
  }

  Future<void> clear() async {
    await prefs.remove(_keySessionId);
    await prefs.remove(_keyRoutineDayId);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keySessionDate);
    await prefs.remove(_keyRoutineDayName);
  }

  /// Devuelve el contexto de la sesión activa o null si no hay ninguna guardada.
  ActiveSessionContext? getContext() {
    final sessionId = prefs.getString(_keySessionId);
    final routineDayId = prefs.getString(_keyRoutineDayId);
    final userId = prefs.getString(_keyUserId);
    final sessionDateStr = prefs.getString(_keySessionDate);
    final routineDayName = prefs.getString(_keyRoutineDayName);

    if (sessionId == null ||
        routineDayId == null ||
        userId == null ||
        sessionDateStr == null ||
        routineDayName == null) {
      return null;
    }

    return ActiveSessionContext(
      sessionId: sessionId,
      routineDayId: routineDayId,
      userId: userId,
      sessionDate: DateTime.parse(sessionDateStr),
      routineDayName: routineDayName,
    );
  }

  bool get hasActiveSession => getContext() != null;
}

class ActiveSessionContext {
  final String sessionId;
  final String routineDayId;
  final String userId;
  final DateTime sessionDate;
  final String routineDayName;

  const ActiveSessionContext({
    required this.sessionId,
    required this.routineDayId,
    required this.userId,
    required this.sessionDate,
    required this.routineDayName,
  });
}
