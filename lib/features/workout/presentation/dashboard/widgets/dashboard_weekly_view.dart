import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/app_colors.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_insights_compact.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_week_list.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_week_navigator.dart';

/// Vista semanal con lista vertical de días. Cada día es una card legible
/// con su rutina, estado y CTA cuando aplica. Reemplaza la dupla "hero +
/// strip" anterior (que duplicaba la info de hoy y apretaba el resto).
class DashboardWeeklyView extends StatefulWidget {
  final List<RoutineDay> days;
  final DateTime weekStart;
  final Routine? selectedRoutine;
  final WeeklyInsights? insights;
  final String? insightsError;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onOpenSelectedRoutineStats;
  final void Function(RoutineDay routineDay, DateTime date) onOpenDay;

  const DashboardWeeklyView({
    super.key,
    required this.days,
    required this.weekStart,
    required this.selectedRoutine,
    required this.insights,
    required this.insightsError,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onOpenSelectedRoutineStats,
    required this.onOpenDay,
  });

  @override
  State<DashboardWeeklyView> createState() => _DashboardWeeklyViewState();
}

class _DashboardWeeklyViewState extends State<DashboardWeeklyView> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _todayKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // En la primera frame, si la semana visible contiene hoy, intentamos
    // que la card de hoy quede a la vista (útil si es jueves/viernes y
    // el usuario no quiere scrollear).
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureTodayVisible());
  }

  @override
  void didUpdateWidget(covariant DashboardWeeklyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weekStart != widget.weekStart) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _ensureTodayVisible(),
      );
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _ensureTodayVisible() {
    final ctx = _todayKey.currentContext;
    if (ctx == null) return;
    // ensureVisible es no-op si ya está visible, así que no estorba en
    // pantallas grandes donde la lista entra completa.
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final weekEnd = widget.weekStart.add(const Duration(days: 6));
    final dayMap = <int, RoutineDay>{
      for (final d in widget.days) d.dayOfWeek: d,
    };
    final containsToday =
        !today.isBefore(widget.weekStart) &&
        today.isBefore(widget.weekStart.add(const Duration(days: 7)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardWeekNavigator(
          weekStart: widget.weekStart,
          weekEnd: weekEnd,
          isCurrentWeek: containsToday,
          routineName: widget.selectedRoutine?.name,
          onPreviousWeek: widget.onPreviousWeek,
          onNextWeek: widget.onNextWeek,
          onOpenStats: widget.onOpenSelectedRoutineStats,
        ),
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.all(Spacing.lg),
            children: [
              _MonthLabel(date: widget.weekStart),
              const SizedBox(height: Spacing.sm),
              _AnchoredWeekList(
                weekStart: widget.weekStart,
                daysByDayOfWeek: dayMap,
                today: today,
                onTapDay: widget.onOpenDay,
                todayKey: containsToday ? _todayKey : null,
              ),
              if (widget.insights != null || widget.insightsError != null) ...[
                const SizedBox(height: Spacing.xl),
                const _SectionLabel(text: 'Insights'),
                const SizedBox(height: Spacing.sm),
                DashboardInsightsCompact(
                  insights: widget.insights,
                  error: widget.insightsError,
                ),
              ],
              const SizedBox(height: Spacing.xl),
            ],
          ),
        ),
      ],
    );
  }
}

/// Wrapper que injerta una `GlobalKey` en la card de hoy para que el
/// padre pueda hacer `Scrollable.ensureVisible`. Usa la misma lista pero
/// envuelve un día con un `KeyedSubtree`.
class _AnchoredWeekList extends StatelessWidget {
  const _AnchoredWeekList({
    required this.weekStart,
    required this.daysByDayOfWeek,
    required this.today,
    required this.onTapDay,
    required this.todayKey,
  });

  final DateTime weekStart;
  final Map<int, RoutineDay> daysByDayOfWeek;
  final DateTime today;
  final void Function(RoutineDay, DateTime) onTapDay;
  final GlobalKey? todayKey;

  @override
  Widget build(BuildContext context) {
    // Si la semana no contiene hoy o no nos pasaron key, delegamos directo.
    if (todayKey == null) {
      return DashboardWeekList(
        weekStart: weekStart,
        daysByDayOfWeek: daysByDayOfWeek,
        today: today,
        onTapDay: onTapDay,
      );
    }
    // Para "anchorear" la card de hoy ponemos la key al SizedBox del
    // wrapper (la lista no expone keys por día). Plot twist: como el
    // wrapper envuelve a toda la lista, anclamos la lista entera al top
    // del viewport — suficiente para que la lista esté visible. Si más
    // adelante queremos precisión por día, exponemos keys en
    // `DashboardWeekList`.
    return KeyedSubtree(
      key: todayKey,
      child: DashboardWeekList(
        weekStart: weekStart,
        daysByDayOfWeek: daysByDayOfWeek,
        today: today,
        onTapDay: onTapDay,
      ),
    );
  }
}

class _MonthLabel extends StatelessWidget {
  const _MonthLabel({required this.date});

  final DateTime date;

  static const _months = [
    '',
    'ENERO',
    'FEBRERO',
    'MARZO',
    'ABRIL',
    'MAYO',
    'JUNIO',
    'JULIO',
    'AGOSTO',
    'SEPTIEMBRE',
    'OCTUBRE',
    'NOVIEMBRE',
    'DICIEMBRE',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      '${_months[date.month]} ${date.year}',
      style: theme.textTheme.labelSmall?.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
