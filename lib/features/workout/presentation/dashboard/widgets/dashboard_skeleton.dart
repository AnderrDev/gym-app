import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/feedback/app_skeleton.dart';

/// Skeleton del dashboard alineado con la nueva vista vertical de días.
/// Mantiene la misma altura aproximada para evitar saltos cuando llega
/// el contenido real: navigator + mes label + 7 cards + insights.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppSkeleton(
      child: Padding(
        padding: EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Navigator: pill rutina + rango fechas
            Row(
              children: [
                AppSkeletonTile.line(width: 110, height: 22),
                Spacer(),
                AppSkeletonTile.line(width: 100, height: 14),
                Spacer(),
                AppSkeletonTile.circle(size: 28),
              ],
            ),
            SizedBox(height: Spacing.lg),
            // Month label "MAYO 2026"
            AppSkeletonTile.line(width: 120, height: 10),
            SizedBox(height: Spacing.sm),
            // 7 day cards (altura ~58 c/u con gap sm)
            _DayCardSkeleton(),
            SizedBox(height: Spacing.sm),
            _DayCardSkeleton(),
            SizedBox(height: Spacing.sm),
            _DayCardSkeleton(isToday: true),
            SizedBox(height: Spacing.sm),
            _DayCardSkeleton(),
            SizedBox(height: Spacing.sm),
            _DayCardSkeleton(),
            SizedBox(height: Spacing.sm),
            _DayCardSkeleton(),
            SizedBox(height: Spacing.sm),
            _DayCardSkeleton(),
            SizedBox(height: Spacing.xl),
            // Section label "INSIGHTS"
            AppSkeletonTile.line(width: 80, height: 10),
            SizedBox(height: Spacing.sm),
            // Métricas compactas
            Row(
              children: [
                Expanded(child: AppSkeletonTile(height: 48)),
                SizedBox(width: Spacing.sm),
                Expanded(child: AppSkeletonTile(height: 48)),
                SizedBox(width: Spacing.sm),
                Expanded(child: AppSkeletonTile(height: 48)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCardSkeleton extends StatelessWidget {
  const _DayCardSkeleton({this.isToday = false});

  /// La card de hoy tiene un poquito más de chrome (borde + CTA play).
  /// El skeleton apenas lo refleja con una altura igual y un tile a la
  /// derecha que simula el botón play.
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          const AppSkeletonTile(width: 36, height: 44),
          const SizedBox(width: Spacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppSkeletonTile.line(width: 140, height: 14),
                SizedBox(height: 6),
                AppSkeletonTile.line(width: 180, height: 10),
              ],
            ),
          ),
          const SizedBox(width: Spacing.sm),
          if (isToday)
            const AppSkeletonTile(width: 36, height: 36)
          else
            const AppSkeletonTile.circle(size: 20),
        ],
      ),
    );
  }
}
