import 'package:flutter/material.dart';

import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_day_card.dart';

/// Lista vertical de los 7 días de la semana. Compone `DashboardDayCard`
/// con stagger de entrada (fade + slide-y) cuando el padre reinicia su
/// animación al cambiar de semana. El stagger se controla mediante una
/// `Listenable` opcional para evitar `AnimationController` propio.
class DashboardWeekList extends StatelessWidget {
  const DashboardWeekList({
    super.key,
    required this.weekStart,
    required this.daysByDayOfWeek,
    required this.today,
    required this.onTapDay,
    this.stagger,
    this.todayKey,
  });

  final DateTime weekStart;
  final Map<int, RoutineDay> daysByDayOfWeek;
  final DateTime today;
  final void Function(RoutineDay routineDay, DateTime date) onTapDay;

  /// Animación maestra (0..1). Cuando es `null`, las cards se renderizan
  /// con valor final (1.0) sin animar — útil en tests y skeletons.
  final Animation<double>? stagger;

  /// Si `weekStart..weekStart+6` contiene hoy, el padre puede pasar una
  /// `GlobalKey` para hacer `Scrollable.ensureVisible` sobre la card de hoy.
  final GlobalKey? todayKey;

  static const int _count = 7;
  static const double _gap = 10;

  @override
  Widget build(BuildContext context) {
    final todayDate = DateTime(today.year, today.month, today.day);
    return Column(
      children: [
        for (var i = 0; i < _count; i++) ...[
          if (i > 0) const SizedBox(height: _gap),
          _buildDay(i, todayDate),
        ],
      ],
    );
  }

  Widget _buildDay(int i, DateTime todayDate) {
    final date = weekStart.add(Duration(days: i));
    final dayOnly = DateTime(date.year, date.month, date.day);
    final dayOfWeek = i + 1;
    final routineDay = daysByDayOfWeek[dayOfWeek];
    final isToday = dayOnly == todayDate;
    final isPast = dayOnly.isBefore(todayDate);

    final card = DashboardDayCard(
      date: date,
      dayOfWeek: dayOfWeek,
      routineDay: routineDay,
      isToday: isToday,
      isPast: isPast,
      onTap: routineDay == null ? null : () => onTapDay(routineDay, date),
    );

    final wrapped = isToday && todayKey != null
        ? KeyedSubtree(key: todayKey, child: card)
        : card;

    final stagger = this.stagger;
    if (stagger == null) return wrapped;

    return _StaggeredEntry(
      index: i,
      total: _count,
      stagger: stagger,
      child: wrapped,
    );
  }
}

/// Envoltorio que mapea una `Animation<double>` 0..1 maestra a una entrada
/// staggered por índice: cada card abre su ventana de animación a
/// `index / total * 0.6` y la cierra `0.4` de progreso más tarde.
class _StaggeredEntry extends StatelessWidget {
  const _StaggeredEntry({
    required this.index,
    required this.total,
    required this.stagger,
    required this.child,
  });

  final int index;
  final int total;
  final Animation<double> stagger;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (index / total) * 0.55;
    final end = (start + 0.45).clamp(0.0, 1.0);
    final curved = CurvedAnimation(
      parent: stagger,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, c) {
        final t = curved.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 14),
            child: c,
          ),
        );
      },
      child: child,
    );
  }
}
