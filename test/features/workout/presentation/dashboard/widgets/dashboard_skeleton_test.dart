import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_flutter/core/theme/app_theme.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_skeleton.dart';

void main() {
  testWidgets('no desborda en una ventana baja', (tester) async {
    // Alto de la ventana de Chrome donde apareció el desbordamiento.
    tester.view.physicalSize = const Size(720, 561);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: DashboardSkeleton()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
  });
}
