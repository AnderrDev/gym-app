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
        itemBuilder: (_, _) => const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSkeletonTile.line(width: 200, height: 18),
            SizedBox(height: Spacing.md),
            Row(
              children: [
                AppSkeletonTile(width: 100, height: 28),
                SizedBox(width: Spacing.sm),
                AppSkeletonTile(width: 100, height: 28),
              ],
            ),
            SizedBox(height: Spacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppSkeletonTile(width: 70, height: 14),
                AppSkeletonTile(width: 90, height: 36),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
