import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/theme/app_palette.dart';

/// Ratio de contraste WCAG 2.x entre dos colores opacos.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Texto normal (WCAG AA).
const _text = 4.5;

/// Texto grande / componentes de UI (WCAG AA).
const _ui = 3.0;

void main() {
  for (final (name, p) in [
    ('light', AppPalette.light()),
    ('dark', AppPalette.dark()),
  ]) {
    group('AppPalette.$name', () {
      void expectContrast(String label, Color fg, Color bg, double min) {
        final ratio = _contrast(fg, bg);
        expect(
          ratio,
          greaterThanOrEqualTo(min),
          reason: '$label: ${ratio.toStringAsFixed(2)}:1 < $min:1',
        );
      }

      test('texto sobre background/surface/surfaceHighlight', () {
        final surfaces = {
          'background': p.background,
          'surface': p.surface,
          'surfaceHighlight': p.surfaceHighlight,
        };
        final texts = {
          'textPrimary': p.textPrimary,
          'textSecondary': p.textSecondary,
        };
        for (final s in surfaces.entries) {
          for (final t in texts.entries) {
            expectContrast('${t.key} / ${s.key}', t.value, s.value, _text);
          }
        }
      });

      test('colores usables como texto sobre background/surface', () {
        final texts = {
          'primary': p.primary,
          'error': p.error,
          'info': p.info,
          'successText': p.successText,
          'warningText': p.warningText,
          for (var i = 0; i < p.routineAccents.length; i++)
            'routineAccents[$i]': p.routineAccents[i],
        };
        for (final bg in {
          'background': p.background,
          'surface': p.surface,
        }.entries) {
          for (final t in texts.entries) {
            expectContrast('${t.key} / ${bg.key}', t.value, bg.value, _text);
          }
        }
      });

      test('on* sobre su relleno', () {
        expectContrast('onSuccess / success', p.onSuccess, p.success, _text);
        expectContrast('onWarning / warning', p.onWarning, p.warning, _text);
        // En dark se mantiene el azul/rojo iOS con texto blanco (3.6 y 3.4):
        // decisión de marca, cumple el mínimo de texto grande/UI.
        final fillMin = name == 'light' ? _text : _ui;
        expectContrast('onPrimary / primary', p.onPrimary, p.primary, fillMin);
        expectContrast('onError / error', p.onError, p.error, fillMin);
      });

      test('rellenos semánticos distinguibles del fondo (UI 3:1)', () {
        // success/warning en light son relleno, no texto: basta con que el
        // relleno lleve su `on*` encima. En dark además se leen sobre fondo.
        if (name == 'dark') {
          expectContrast('success / background', p.success, p.background, _ui);
          expectContrast('warning / background', p.warning, p.background, _ui);
        }
      });
    });
  }
}
