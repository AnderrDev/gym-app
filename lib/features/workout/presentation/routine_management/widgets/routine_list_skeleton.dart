import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/feedback/app_skeleton.dart';

/// Skeleton del listado de rutinas: 3 cards placeholder.
class RoutineListSkeleton extends StatelessWidget {
  const RoutineListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: ListView.separated(
        padding: const EdgeInsets.all(Spacing.lgPlus),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(height: Spacing.lg),
        // Misma forma que `RoutineListCard`: avatar + nombre/metadatos y
        // la acción abajo a la derecha.
        itemBuilder: (_, _) => const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                AppSkeletonTile(width: 44, height: 44),
                SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeletonTile.line(width: 160, height: 18),
                      SizedBox(height: Spacing.sm),
                      AppSkeletonTile.line(width: 200, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: Spacing.md),
            AppSkeletonTile(width: 110, height: 44),
          ],
        ),
      ),
    );
  }
}
