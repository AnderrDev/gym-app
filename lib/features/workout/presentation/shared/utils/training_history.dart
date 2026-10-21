import 'package:gym_flutter/core/utils/calendar_dates.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_history_session.dart';

/// Entrenamientos y volumen de una semana (lunes a domingo).
class WeekTotals {
  const WeekTotals({
    required this.weekStart,
    required this.sessions,
    required this.volume,
  });

  final DateTime weekStart;
  final int sessions;
  final double volume;
}

/// Totales de las [weeks] semanas que terminan en la de [lastWeekStart],
/// de la más antigua a la más reciente. Las semanas sin entrenar salen con
/// ceros: un hueco en el historial también es información.
List<WeekTotals> weeklyTotals(
  Iterable<RoutineHistorySession> sessions, {
  required DateTime lastWeekStart,
  int weeks = 8,
}) {
  final last = AppCalendar.startOfWeek(lastWeekStart);
  final starts = [
    for (var i = weeks - 1; i >= 0; i--) AppCalendar.addDays(last, -7 * i),
  ];
  final count = {for (final s in starts) s: 0};
  final volume = {for (final s in starts) s: 0.0};
  for (final session in sessions) {
    final week = AppCalendar.startOfWeek(
      AppCalendar.dateOnly(session.sessionDate),
    );
    if (!count.containsKey(week)) continue;
    count[week] = count[week]! + 1;
    volume[week] = volume[week]! + session.totalVolume;
  }
  return [
    for (final s in starts)
      WeekTotals(weekStart: s, sessions: count[s]!, volume: volume[s]!),
  ];
}

/// Cambio relativo en %, o `null` si no hay base con la que comparar
/// (antes salía "+100 %" frente a una semana sin entrenar).
double? percentChange(double current, double previous) =>
    previous <= 0 ? null : (current - previous) / previous * 100;
