import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

/// Delegates de Material/Cupertino/Widgets que solo cargan español.
///
/// `GlobalMaterialLocalizations.delegates` resuelve la traducción con un
/// `switch` sobre ~80 idiomas y carga los símbolos de fecha de todos ellos:
/// el compilador no puede descartar ninguno y en web eso son ~150 KB extra
/// de `main.dart.js`. Como la app solo soporta `es`, instanciamos las clases
/// en español directamente y el resto queda fuera del bundle.
///
/// Requiere que `initializeDateFormatting('es')` haya corrido antes (lo hace
/// `main()`); si no, cae a los formatos por defecto de `intl`.
const List<LocalizationsDelegate<dynamic>> spanishLocalizationsDelegates = [
  _SpanishCupertinoDelegate(),
  _SpanishMaterialDelegate(),
  _SpanishWidgetsDelegate(),
];

const String _es = 'es';

String? get _formatLocale => intl.DateFormat.localeExists(_es) ? _es : null;

class _SpanishMaterialDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _SpanishMaterialDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == _es;

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    final l = _formatLocale;
    return SynchronousFuture<MaterialLocalizations>(
      MaterialLocalizationEs(
        fullYearFormat: intl.DateFormat.y(l),
        compactDateFormat: intl.DateFormat.yMd(l),
        shortDateFormat: intl.DateFormat.yMMMd(l),
        mediumDateFormat: intl.DateFormat.MMMEd(l),
        longDateFormat: intl.DateFormat.yMMMMEEEEd(l),
        yearMonthFormat: intl.DateFormat.yMMMM(l),
        shortMonthDayFormat: intl.DateFormat.MMMd(l),
        decimalFormat: intl.NumberFormat.decimalPattern(l),
        twoDigitZeroPaddedFormat: intl.NumberFormat('00', l),
      ),
    );
  }

  @override
  bool shouldReload(_SpanishMaterialDelegate old) => false;
}

class _SpanishCupertinoDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _SpanishCupertinoDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == _es;

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    final l = _formatLocale;
    return SynchronousFuture<CupertinoLocalizations>(
      CupertinoLocalizationEs(
        fullYearFormat: intl.DateFormat.y(l),
        dayFormat: intl.DateFormat.d(l),
        weekdayFormat: intl.DateFormat.E(l),
        mediumDateFormat: intl.DateFormat.MMMEd(l),
        singleDigitHourFormat: intl.DateFormat('HH', l),
        singleDigitMinuteFormat: intl.DateFormat.m(l),
        doubleDigitMinuteFormat: intl.DateFormat('mm', l),
        singleDigitSecondFormat: intl.DateFormat.s(l),
        decimalFormat: intl.NumberFormat.decimalPattern(l),
      ),
    );
  }

  @override
  bool shouldReload(_SpanishCupertinoDelegate old) => false;
}

class _SpanishWidgetsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _SpanishWidgetsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == _es;

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      SynchronousFuture<WidgetsLocalizations>(const WidgetsLocalizationEs());

  @override
  bool shouldReload(_SpanishWidgetsDelegate old) => false;
}
