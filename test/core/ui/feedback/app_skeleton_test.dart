import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';

import 'package:gym_flutter/core/theme/app_theme.dart';
import 'package:gym_flutter/core/ui/feedback/app_skeleton.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.dark(),
  home: Scaffold(body: child),
);

void main() {
  group('AppSkeleton', () {
    testWidgets('envuelve child en Shimmer', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppSkeleton(child: AppSkeletonTile())),
      );
      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(AppSkeletonTile), findsOneWidget);
    });

    testWidgets('respeta baseColor/highlightColor explícitos', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppSkeleton(
            baseColor: Colors.red,
            highlightColor: Colors.green,
            child: AppSkeletonTile(),
          ),
        ),
      );
      final shimmer = tester.widget<Shimmer>(find.byType(Shimmer));
      // `gradient.colors` debe contener los colores explícitos.
      expect(shimmer.gradient.colors, contains(Colors.red));
      expect(shimmer.gradient.colors, contains(Colors.green));
    });
  });

  group('AppSkeletonTile', () {
    testWidgets('default es rectangular con altura 16', (tester) async {
      await tester.pumpWidget(
        _wrap(const SizedBox(width: 100, child: AppSkeletonTile())),
      );
      final box = tester.getSize(find.byType(AppSkeletonTile));
      expect(box.height, 16);
    });

    testWidgets('.circle es cuadrada con borderRadius gigante', (tester) async {
      await tester.pumpWidget(_wrap(const AppSkeletonTile.circle(size: 48)));
      final box = tester.getSize(find.byType(AppSkeletonTile));
      expect(box.width, 48);
      expect(box.height, 48);
    });

    testWidgets('.line tiene altura 12 por defecto', (tester) async {
      await tester.pumpWidget(
        _wrap(const SizedBox(width: 80, child: AppSkeletonTile.line())),
      );
      final box = tester.getSize(find.byType(AppSkeletonTile));
      expect(box.height, 12);
    });
  });
}
