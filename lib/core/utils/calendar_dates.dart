/// Aritmética de fechas por días de calendario.
///
/// `date.add(Duration(days: n))` suma `n * 24h` y se descuadra en los cambios
/// de horario (DST): el lunes 19-oct-2026 + 7 días da el domingo 25 a las
/// 23:00, que al normalizar vuelve al lunes 19. Construir el `DateTime` desde
/// sus componentes deja que Dart resuelva la medianoche local correcta.
class AppCalendar {
  AppCalendar._();

  /// Medianoche local de `date`.
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Medianoche `days` días de calendario después de `date` (negativo para ir
  /// hacia atrás). Descarta la hora y conserva si `date` es UTC o local.
  static DateTime addDays(DateTime date, int days) => date.isUtc
      ? DateTime.utc(date.year, date.month, date.day + days)
      : DateTime(date.year, date.month, date.day + days);

  /// Medianoche local del lunes de la semana de `date`.
  static DateTime startOfWeek(DateTime date) =>
      addDays(date, -(date.weekday - 1));
}
