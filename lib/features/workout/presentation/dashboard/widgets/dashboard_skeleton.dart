import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/feedback/app_skeleton.dart';

/// Skeleton del dashboard alineado con la nueva vista semanal:
/// - Cabecera con rango + flechas (sin ring; quedó redundante con el
///   tile de Resumen semanal de abajo)
/// - 7 day-cards con stack visual: la card de hoy más alta (highlight)
/// - Tile de Resumen semanal: 3 stats + barra de progreso
///
/// Mantiene proporciones cercanas al contenido real para evitar saltos.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header strip
          Container(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.md,
              Spacing.lg,
              Spacing.md,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.colors.divider)),
            ),
            child: const Row(
              children: [
                AppSkeletonTile(width: 40, height: 40),
                SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppSkeletonTile.line(width: 140, height: 16),
                      SizedBox(height: 6),
                      AppSkeletonTile.line(width: 90, height: 12),
                    ],
                  ),
                ),
                SizedBox(width: Spacing.md),
                AppSkeletonTile(width: 40, height: 40),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.md,
              Spacing.lg,
              Spacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DayCardSkeleton(height: 64),
                SizedBox(height: 10),
                _DayCardSkeleton(height: 64),
                SizedBox(height: 10),
                _DayCardSkeleton(height: 96, isToday: true),
                SizedBox(height: 10),
                _DayCardSkeleton(height: 64),
                SizedBox(height: 10),
                _DayCardSkeleton(height: 64),
                SizedBox(height: 10),
                _DayCardSkeleton(height: 64),
                SizedBox(height: 10),
                _DayCardSkeleton(height: 40, isRest: true),
                SizedBox(height: Spacing.xl),
                // Skeleton del tile "Resumen de la semana":
                // header label + 3 stats grandes + barra de progreso.
                _WeekSummarySkeleton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekSummarySkeleton extends StatelessWidget {
  const _WeekSummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.divider.withValues(alpha: 0.4)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppSkeletonTile.circle(size: 18),
              SizedBox(width: Spacing.sm),
              AppSkeletonTile.line(width: 160, height: 10),
            ],
          ),
          SizedBox(height: Spacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeletonTile.line(width: 70, height: 28),
                    SizedBox(height: 4),
                    AppSkeletonTile.line(width: 84, height: 10),
                  ],
                ),
              ),
              SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeletonTile.line(width: 40, height: 28),
                    SizedBox(height: 4),
                    AppSkeletonTile.line(width: 70, height: 10),
                  ],
                ),
              ),
              SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeletonTile.line(width: 56, height: 28),
                    SizedBox(height: 4),
                    AppSkeletonTile.line(width: 90, height: 10),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Spacing.md),
          AppSkeletonTile(height: 6),
          SizedBox(height: Spacing.xs),
          AppSkeletonTile.line(width: 180, height: 10),
        ],
      ),
    );
  }
}

class _DayCardSkeleton extends StatelessWidget {
  const _DayCardSkeleton({
    required this.height,
    this.isToday = false,
    this.isRest = false,
  });

  final double height;
  final bool isToday;
  final bool isRest;

  @override
  Widget build(BuildContext context) {
    if (isRest) {
      return SizedBox(
        height: height,
        child: const Row(
          children: [
            SizedBox(width: 36, child: AppSkeletonTile.line(height: 12)),
            SizedBox(width: Spacing.md),
            Expanded(child: AppSkeletonTile.line(width: 80, height: 10)),
          ],
        ),
      );
    }

    return SizedBox(
      height: height,
      child: Row(
        children: [
          AppSkeletonTile(width: isToday ? 44 : 36, height: isToday ? 46 : 38),
          const SizedBox(width: Spacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppSkeletonTile.line(width: 160, height: 14),
                SizedBox(height: 6),
                AppSkeletonTile.line(width: 200, height: 10),
              ],
            ),
          ),
          const SizedBox(width: Spacing.sm),
          if (isToday)
            const AppSkeletonTile(width: 44, height: 44)
          else
            const AppSkeletonTile.circle(size: 24),
        ],
      ),
    );
  }
}
