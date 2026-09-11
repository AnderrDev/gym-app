@Tags(['lint'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Garantía mecánica de que ningún archivo bajo `lib/features/` introduce
/// un color hex literal ni un color estático de Material (`Colors.amber`,
/// `Colors.black`, etc.). La paleta vive en `core/theme/app_palette.dart`
/// (`context.colors.*`, theme-aware) y `core/theme/app_colors.dart`
/// (`AppColors.*`, brand-stable). Los features deben consumir siempre esos
/// tokens — un `Colors.*` estático no se adapta a dark mode.
///
/// Si este test rompe: añadí el color faltante a `AppPalette`/`AppColors` y
/// reemplazá el literal por el token. Nunca añadas excepciones aquí.
/// `Colors.transparent` está exento — es brightness-agnostic por definición.
void main() {
  test('lib/features no contiene literales hex ni Colors.* estáticos', () {
    final hexLiteral = RegExp(r'0x[0-9A-Fa-f]{8}');
    final staticMaterialColor = RegExp(r'\bColors\.(?!transparent\b)\w+');
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
        if (hexLiteral.hasMatch(line) || staticMaterialColor.hasMatch(line)) {
          offenders.add('${file.path}:${i + 1}: $line');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Se encontraron literales de color en lib/features/. Reemplazá '
          'por context.colors.* / AppColors.* o agregá un token nuevo:\n'
          '${offenders.join('\n')}',
    );
  });
}
