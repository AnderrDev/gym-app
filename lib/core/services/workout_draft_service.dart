import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:gym_flutter/core/observability/app_logger.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';

/// Valores editados; no son series completadas ni una cola de sincronización.
class WorkoutDraftService {
  WorkoutDraftService(this.prefs);

  final SharedPreferences prefs;

  String _key(String userId, String sessionId) =>
      'workout_drafts.$userId.$sessionId';

  List<SetLog> load(String userId, String sessionId) {
    final raw = prefs.getString(_key(userId, sessionId));
    if (raw == null) return const [];
    try {
      final rows = jsonDecode(raw) as List<dynamic>;
      return rows.map((row) {
        final data = row as Map<String, dynamic>;
        final weight = (data['weight'] as num).toDouble();
        final reps = data['reps'] as int;
        final index = data['index'] as int;
        if (!weight.isFinite || weight < 0 || reps <= 0 || index < 1) {
          throw const FormatException('Invalid set draft');
        }
        return SetLog(
          sessionId: sessionId,
          exerciseId: data['exercise'] as String,
          setIndex: index,
          actualWeight: weight,
          actualReps: reps,
        );
      }).toList();
    } catch (e) {
      AppLogger.instance.warning('No se pudieron leer borradores: $e');
      return const [];
    }
  }

  Future<void> save(String userId, SetLog log) async {
    final logs = List<SetLog>.from(load(userId, log.sessionId))
      ..removeWhere(
        (l) => l.exerciseId == log.exerciseId && l.setIndex == log.setIndex,
      );
    logs.add(log);
    final saved = await prefs.setString(
      _key(userId, log.sessionId),
      jsonEncode([
        for (final l in logs)
          {
            'exercise': l.exerciseId,
            'index': l.setIndex,
            'weight': l.actualWeight,
            'reps': l.actualReps,
          },
      ]),
    );
    if (!saved) throw StateError('No se pudo guardar el borrador');
  }

  Future<void> clear(String userId, String sessionId) async {
    await prefs.remove(_key(userId, sessionId));
  }

  /// Borra los borradores de todas las sesiones de [userId] (p. ej. al
  /// eliminar la cuenta).
  Future<void> clearAllForUser(String userId) async {
    final prefix = 'workout_drafts.$userId.';
    final keys = prefs.getKeys().where((k) => k.startsWith(prefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
