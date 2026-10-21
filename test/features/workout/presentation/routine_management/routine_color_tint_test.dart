import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_flutter/core/theme/app_palette.dart';
import 'package:gym_flutter/core/theme/app_theme.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/utils/routine_color.dart';

/// Ratio de contraste WCAG 2.x entre dos colores opacos.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final (name, theme) in [
    ('light', AppTheme.light()),
    ('dark', AppTheme.dark()),
  ]) {
    testWidgets('RoutineColor.tint: acentos y primary legibles ($name)', (
      tester,
    ) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      );
      final p = theme.extension<AppPalette>()!;
      for (final accent in [...p.routineAccents, p.primary]) {
        final ratio = _contrast(accent, RoutineColor.tint(ctx, accent));
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '$accent: ${ratio.toStringAsFixed(2)}:1 < 4.5:1',
        );
      }
    });
  }
}
