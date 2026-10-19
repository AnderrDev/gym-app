import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_day_card_content_parts.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_day_card_parts.dart';

/// Card de un día de la semana, con jerarquía fuerte por variante:
/// `today` ocupa más altura, gana borde primary, sombra y CTA play;
/// `past` y `future` se mantienen bajos y escaneables; `rest` es una row
/// minimalista para no robar atención.
///
/// La animación de tap (scale + haptics) vive en este widget — los
/// stagger/entrance los compone el padre (`DashboardWeekList`).
class DashboardDayCard extends StatefulWidget {
  const DashboardDayCard({
    super.key,
    required this.date,
    required this.dayOfWeek,
    required this.routineDay,
    required this.isToday,
    required this.isPast,
    required this.onTap,
  });

  final DateTime date;
  final int dayOfWeek; // 1..7
  final RoutineDay? routineDay;
  final bool isToday;
  final bool isPast;
  final VoidCallback? onTap;

  static const List<String> _initials = ['', 'L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  State<DashboardDayCard> createState() => _DashboardDayCardState();
}

class _DashboardDayCardState extends State<DashboardDayCard> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  void _handleTap() {
    if (widget.onTap == null) return;
    HapticFeedback.selectionClick();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final routineDay = widget.routineDay;
    final isRest = routineDay == null;
    final status = routineDay?.status ?? WorkoutDayStatus.rest;
    final variant = _variantFor(
      isToday: widget.isToday,
      isPast: widget.isPast,
      isRest: isRest,
    );
    final accent = _accentFor(
      context,
      status,
      isToday: widget.isToday,
      isPast: widget.isPast,
    );

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: RepaintBoundary(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
          onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
          onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
          onTap: widget.onTap == null ? null : _handleTap,
          child: DayCardSurface(
            variant: variant,
            accent: accent,
            child: _buildBody(
              variant: variant,
              accent: accent,
              routineDay: routineDay,
              status: status,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required DayCardVariant variant,
    required Color accent,
    required RoutineDay? routineDay,
    required WorkoutDayStatus status,
  }) {
    final initial = DashboardDayCard._initials[widget.dayOfWeek];
    if (variant == DayCardVariant.rest) {
      return DayCardRestRow(initial: initial, dayNumber: widget.date.day);
    }
    final isToday = variant == DayCardVariant.today;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        DayCardDateBlock(
          initial: initial,
          dayNumber: widget.date.day,
          accent: accent,
          variant: variant,
          status: status,
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: DayCardWorkoutContent(
            routineDay: routineDay!,
            status: status,
            accent: accent,
            variant: variant,
            isPast: widget.isPast,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        DayCardTrailingIndicator(
          status: status,
          isToday: isToday,
          accent: accent,
        ),
      ],
    );
  }

  static DayCardVariant _variantFor({
    required bool isToday,
    required bool isPast,
    required bool isRest,
  }) {
    if (isRest) return DayCardVariant.rest;
    if (isToday) return DayCardVariant.today;
    if (isPast) return DayCardVariant.past;
    return DayCardVariant.future;
  }

  static Color _accentFor(
    BuildContext context,
    WorkoutDayStatus status, {
    required bool isToday,
    required bool isPast,
  }) {
    final colors = context.colors;
    switch (status) {
      case WorkoutDayStatus.completed:
        return colors.success;
      case WorkoutDayStatus.completedPartial:
        return colors.warning;
      case WorkoutDayStatus.inProgress:
        return colors.primary;
      case WorkoutDayStatus.pending:
        if (isPast) return colors.textSecondary;
        return isToday ? colors.primary : colors.textPrimary;
      case WorkoutDayStatus.rest:
        return colors.textDisabled;
    }
  }
}
