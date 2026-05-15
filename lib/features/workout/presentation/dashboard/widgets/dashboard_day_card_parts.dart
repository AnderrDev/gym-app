import 'package:flutter/material.dart';

import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/core/theme/app_colors.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';

/// Variantes visuales de la card según el día y su estado. Determinan
/// padding, borde, sombra y prominencia del contenido.
enum DayCardVariant { today, past, future, rest }

class DayCardSurface extends StatelessWidget {
  const DayCardSurface({
    super.key,
    required this.variant,
    required this.accent,
    required this.child,
  });

  final DayCardVariant variant;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (variant == DayCardVariant.rest) {
      // Misma anatomía que los workout cards (radio + padding) pero con
      // un fill mucho más sutil — leen como parte de la lista, no como
      // separadores tipo footnote.
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.lg),
          color: AppColors.surface.withValues(alpha: 0.25),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: 10,
          ),
          child: child,
        ),
      );
    }

    final isToday = variant == DayCardVariant.today;
    final isFuture = variant == DayCardVariant.future;
    final radius = BorderRadius.circular(Radii.lg);

    final BoxDecoration decoration;
    if (isToday) {
      // Highlight más intenso para que "hoy" salte de la lista. Sube el
      // tinte del gradient, fortifica el borde y aumenta la shadow.
      decoration = BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.18),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.75),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      );
    } else {
      decoration = BoxDecoration(
        borderRadius: radius,
        color: isFuture
            ? AppColors.background
            : AppColors.surface.withValues(alpha: 0.55),
        border: Border.all(color: AppColors.divider),
      );
    }

    return DecoratedBox(
      decoration: decoration,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: isToday ? 14 : 10,
        ),
        child: child,
      ),
    );
  }
}

class DayCardRestRow extends StatelessWidget {
  const DayCardRestRow({
    super.key,
    required this.initial,
    required this.dayNumber,
  });

  final String initial;
  final int dayNumber;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                initial,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textDisabled,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$dayNumber',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textDisabled,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.bedtime_rounded,
                size: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                'Descanso',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DayCardDateBlock extends StatelessWidget {
  const DayCardDateBlock({
    super.key,
    required this.initial,
    required this.dayNumber,
    required this.accent,
    required this.variant,
    required this.status,
  });

  final String initial;
  final int dayNumber;
  final Color accent;
  final DayCardVariant variant;
  final WorkoutDayStatus status;

  @override
  Widget build(BuildContext context) {
    final isToday = variant == DayCardVariant.today;
    final isPast = variant == DayCardVariant.past;
    final muted = isPast && status == WorkoutDayStatus.pending;

    if (isToday) {
      // Pill compacta para hoy con fondo primary tenue y números nítidos.
      return Container(
        width: 44,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(Radii.md),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              initial,
              style: AppTextStyles.label.copyWith(
                color: AppColors.onPrimary.withValues(alpha: 0.85),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              '$dayNumber',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 19,
                height: 1.05,
              ),
            ),
          ],
        ),
      );
    }

    final initialColor = muted ? AppColors.textSecondary : accent;
    final numberColor =
        muted ? AppColors.textSecondary : AppColors.textPrimary;
    return SizedBox(
      width: 36,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            initial,
            style: AppTextStyles.label.copyWith(
              color: initialColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$dayNumber',
            style: AppTextStyles.bodyLarge.copyWith(
              color: numberColor,
              fontWeight: FontWeight.w800,
              fontSize: 19,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}
