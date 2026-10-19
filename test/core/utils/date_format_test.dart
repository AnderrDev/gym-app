import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/utils/date_format.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es', null);
  });

  group('AppDateFormat', () {
    final date = DateTime(2026, 5, 4, 18, 30);

    test('isoDate devuelve YYYY-MM-DD', () {
      expect(AppDateFormat.isoDate(date), '2026-05-04');
    });

    test('localIsoTimestamp devuelve YYYY-MM-DDTHH:MM:SS', () {
      expect(AppDateFormat.localIsoTimestamp(date), '2026-05-04T18:30:00');
    });

    test('dayMonth devuelve d/M', () {
      expect(AppDateFormat.dayMonth(date), '4/5');
    });

    test('time devuelve HH:mm', () {
      expect(AppDateFormat.time(date), '18:30');
    });

    test('long incluye nombre de mes y año en es', () {
      expect(AppDateFormat.long(date), contains('mayo'));
      expect(AppDateFormat.long(date), contains('2026'));
    });
  });
}
