import 'package:intl/intl.dart';

/// Helpers de formato de fecha. Centralizados para que ningún `lib/features/`
/// tenga `DateFormat('d/M')` ni manipule strings ad-hoc.
///
/// Cuando se migre a `.arb` (Fase 8), las locales viven aquí.
class AppDateFormat {
  AppDateFormat._();

  /// `2026-05-04` — fecha ISO sin hora (para queries Supabase, IDs).
  static String isoDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// `2026-05-04T18:30:00` — ISO timestamp local (sin TZ).
  static String localIsoTimestamp(DateTime date) {
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(date);
  }

  /// `04/05` — día/mes corto, para ejes de charts.
  static String dayMonth(DateTime date) {
    return DateFormat('d/M').format(date);
  }

  /// `4 may` — día y mes abreviado en es_ES.
  static String dayMonthShort(DateTime date) {
    return DateFormat('d MMM', 'es').format(date);
  }

  /// `lun 4 may` — día de semana corto + día + mes abreviado.
  static String weekdayDayMonth(DateTime date) {
    return DateFormat('E d MMM', 'es').format(date);
  }

  /// `4 mayo de 2026` — formato narrativo.
  static String long(DateTime date) {
    return DateFormat("d 'de' MMMM 'de' yyyy", 'es').format(date);
  }

  /// `4 may 2026` — día + mes corto + año, para encabezados.
  static String dayMonthShortYear(DateTime date) {
    return DateFormat('d MMM yyyy', 'es').format(date);
  }

  /// `lunes, 4 may` — día completo + día + mes abreviado.
  static String weekdayLongDayMonth(DateTime date) {
    return DateFormat('EEEE, d MMM', 'es').format(date);
  }

  /// `lunes, 4 mayo 2026` — día completo + día + mes completo + año.
  static String weekdayLongFull(DateTime date) {
    return DateFormat('EEEE, d MMMM yyyy', 'es').format(date);
  }

  /// `lunes` — solo nombre del día de la semana.
  static String weekdayLong(DateTime date) {
    return DateFormat('EEEE', 'es').format(date);
  }

  /// `18:30` — solo hora.
  static String time(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }
}
