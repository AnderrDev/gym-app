import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/feedback/app_skeleton.dart';

/// Skeleton del dashboard para "Focus Today". Refleja la nueva composición:
/// hero del día + strip semanal + métricas compactas. La forma se mantiene
/// en altura para evitar saltos cuando llega el contenido real.
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
            // Header de semana
            Center(child: AppSkeletonTile.line(width: 160, height: 14)),
            SizedBox(height: Spacing.lg),
            // Hero today
            AppSkeletonTile(height: 200),
            SizedBox(height: Spacing.xl),
            // Section label
            AppSkeletonTile.line(width: 140, height: 10),
            SizedBox(height: Spacing.sm),
            // Strip de 7 días
            AppSkeletonTile(height: 72),
            SizedBox(height: Spacing.xl),
            // Insights label
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
