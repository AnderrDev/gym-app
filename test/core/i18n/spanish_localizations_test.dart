import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gym_flutter/core/i18n/spanish_localizations.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  testWidgets('resuelve Material, Cupertino y Widgets en español', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: spanishLocalizationsDelegates,
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final material = MaterialLocalizations.of(ctx);
    expect(material.backButtonTooltip, 'Atrás');
    expect(material.cancelButtonLabel, 'Cancelar');
    expect(material.formatMediumDate(DateTime(2026, 10, 19)), 'lun, 19 oct');
    expect(CupertinoLocalizations.of(ctx).alertDialogLabel, 'Alerta');
    expect(Directionality.of(ctx), TextDirection.ltr);
  });
}
