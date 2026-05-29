@Tags(['lint'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Garantía mecánica de que ningún archivo bajo `lib/features/` introduce
/// un color hex literal. La paleta vive en `core/theme/app_colors.dart` y los
/// features deben consumirla vía `AppColors.*`.
///
/// Si este test rompe: añadí el color faltante a `AppColors` y reemplazá el
/// literal por el token. Nunca añadas excepciones aquí.
void main() {
  test('lib/features no contiene literales hex', () {
    final hexLiteral = RegExp(r'0x[0-9A-Fa-f]{8}');
    final featuresDir = Directory('lib/features');
    expect(
      featuresDir.existsSync(),
      isTrue,
      reason: 'Se esperaba el directorio lib/features/',
    );

    final offenders = <String>[];
    final dartFiles = featuresDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (hexLiteral.hasMatch(line)) {
          offenders.add('${file.path}:${i + 1}: $line');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Se encontraron literales hex en lib/features/. Reemplazá por '
          'AppColors.* o agregá un token nuevo:\n${offenders.join('\n')}',
    );
  });
}
