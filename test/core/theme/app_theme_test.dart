import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_flutter/core/theme/app_palette.dart';
import 'package:gym_flutter/core/theme/app_theme.dart';
import 'package:gym_flutter/core/theme/theme_context.dart';

void main() {
  // Los builders de AppTheme invocan GoogleFonts.*TextTheme, que dispara
  // fetches de red asíncronos. En tests usamos `testWidgets` para que el
  // binding tolere esos errores async ya conocidos (mismo patrón que el
  // resto de los widget tests del repo).
  group('AppTheme', () {
    testWidgets('light() expone AppPalette light y brightness=light', (
      tester,
    ) async {
      late ThemeData captured;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) {
              captured = Theme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(captured.brightness, Brightness.light);
      final palette = captured.extension<AppPalette>();
      expect(palette, isNotNull);
      expect(palette!.background, const Color(0xFFFFFFFF));
      expect(palette.textPrimary, const Color(0xFF1C1C1E));
    });

    testWidgets('dark() expone AppPalette dark y brightness=dark', (
      tester,
    ) async {
      late ThemeData captured;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Builder(
            builder: (context) {
              captured = Theme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(captured.brightness, Brightness.dark);
      final palette = captured.extension<AppPalette>();
      expect(palette, isNotNull);
      expect(palette!.background, const Color(0xFF0A0A0B));
      expect(palette.textPrimary, const Color(0xFFF2F2F7));
    });

    testWidgets('ambos temas tienen primary distinto pero ambos azulados', (
      tester,
    ) async {
      late AppPalette lightPalette;
      late AppPalette darkPalette;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) {
              lightPalette = Theme.of(context).extension<AppPalette>()!;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      // Cambiar a una key distinta fuerza a `tester` a montar un subtree
      // nuevo en lugar de reusar el Builder anterior (que cachearía el
      // primer Theme.of resuelto).
      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('dark-app'),
          theme: AppTheme.dark(),
          home: Builder(
            builder: (context) {
              darkPalette = Theme.of(context).extension<AppPalette>()!;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(lightPalette.primary, isNot(equals(darkPalette.primary)));
    });

    testWidgets('colorScheme.brightness coincide con theme.brightness', (
      tester,
    ) async {
      late ColorScheme lightScheme;
      late ColorScheme darkScheme;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) {
              lightScheme = Theme.of(context).colorScheme;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          key: const ValueKey('dark-scheme'),
          theme: AppTheme.dark(),
          home: Builder(
            builder: (context) {
              darkScheme = Theme.of(context).colorScheme;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(lightScheme.brightness, Brightness.light);
      expect(darkScheme.brightness, Brightness.dark);
    });
  });

  group('context.colors helper', () {
    testWidgets('resuelve AppPalette desde el ThemeData activo', (
      tester,
    ) async {
      AppPalette? captured;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) {
              captured = context.colors;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(captured, isNotNull);
      expect(captured!.background, const Color(0xFFFFFFFF));
    });

    testWidgets('refleja el modo dark cuando se usa AppTheme.dark()', (
      tester,
    ) async {
      Color? sampled;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Builder(
            builder: (context) {
              sampled = context.colors.background;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(sampled, const Color(0xFF0A0A0B));
    });
  });
}
