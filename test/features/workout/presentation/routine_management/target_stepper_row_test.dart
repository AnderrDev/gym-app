import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/core/theme/app_theme.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/edit_exercise_target_form.dart';

void main() {
  testWidgets('mantener pulsado + repite hasta soltar', (tester) async {
    var plus = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: TargetStepperRow(
            label: 'Descanso',
            value: '90 s',
            onMinus: () {},
            onPlus: () => plus++,
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.add_rounded)),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    final afterRelease = plus;
    await tester.pump(const Duration(milliseconds: 500));

    expect(afterRelease, greaterThan(3));
    expect(plus, afterRelease);
  });
}
