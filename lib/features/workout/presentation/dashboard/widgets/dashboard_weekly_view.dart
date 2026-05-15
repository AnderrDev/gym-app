import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/app_colors.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_insights_compact.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_week_header.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_week_list.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_week_summary.dart';

/// Vista semanal del dashboard. Compone:
/// - `DashboardWeekHeader` (rango + rutina + progress ring + flechas)
/// - Lista vertical de días con stagger de entrada (`DashboardWeekList`)
/// - Insights compactos al final
///
/// La transición entre semanas se anima con `AnimatedSwitcher` direccional
/// (slide horizontal + fade) y un `GestureDetector` capta swipes para
/// llamar a `onPreviousWeek` / `onNextWeek`. El header se mantiene estable
/// y sus subcomponentes animan sus propios cambios (rango de fechas,
/// progress ring).
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

class _DashboardWeeklyViewState extends State<DashboardWeeklyView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerController;
  final ScrollController _scroll = ScrollController();
  final GlobalKey _todayKey = GlobalKey();

  /// +1 = la nueva semana es posterior; -1 = anterior; 0 = primera carga.
  /// Lo usa el `AnimatedSwitcher` para deslizar la lista en la dirección
  /// correcta.
  int _direction = 0;

  /// Umbral de drag horizontal (px) para disparar prev/next.
  static const double _swipeThreshold = 60;
  double _dragX = 0;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureTodayVisible());
  }

  @override
  void didUpdateWidget(covariant DashboardWeeklyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weekStart != widget.weekStart) {
      _direction = widget.weekStart.isAfter(oldWidget.weekStart) ? 1 : -1;
      _staggerController
        ..reset()
        ..forward();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _ensureTodayVisible(),
      );
    }
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _ensureTodayVisible() {
    final ctx = _todayKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _onRefresh() async {
    // El bloc expone `prev/next` para cambiar semana pero no un evento
    // idempotente de "recargar la actual". Mantenemos el `RefreshIndicator`
    // por afordancia (gesture aprendido) y por el feedback táctil; cuando
    // exista un evento de refresh lo conectamos aquí.
    await Future<void>.delayed(const Duration(milliseconds: 320));
  }

  void _onHorizontalDragUpdate(DragUpdateDetails d) {
    _dragX += d.delta.dx;
  }

  void _onHorizontalDragEnd(DragEndDetails d) {
    final dx = _dragX;
    final velocity = d.primaryVelocity ?? 0;
    _dragX = 0;
    if (dx <= -_swipeThreshold || velocity < -400) {
      widget.onNextWeek();
    } else if (dx >= _swipeThreshold || velocity > 400) {
      widget.onPreviousWeek();
    }
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
        DashboardWeekHeader(
          weekStart: widget.weekStart,
          weekEnd: weekEnd,
          isCurrentWeek: containsToday,
          routineName: widget.selectedRoutine?.name,
          onPreviousWeek: widget.onPreviousWeek,
          onNextWeek: widget.onNextWeek,
          onOpenStats: widget.onOpenSelectedRoutineStats,
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.background,
            onRefresh: _onRefresh,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              child: ListView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                // Bottom `xxxl` (40px) le da aire al resumen semanal antes
                // de la bottom nav.
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.md,
                  Spacing.lg,
                  Spacing.xxxl,
                ),
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, anim) {
                      final beginX = _direction >= 0 ? 0.12 : -0.12;
                      final inOffset = Tween<Offset>(
                        begin: Offset(beginX, 0),
                        end: Offset.zero,
                      ).animate(anim);
                      return ClipRect(
                        child: FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: inOffset,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(widget.weekStart.toIso8601String()),
                      child: DashboardWeekList(
                        weekStart: widget.weekStart,
                        daysByDayOfWeek: dayMap,
                        today: today,
                        onTapDay: widget.onOpenDay,
                        stagger: _staggerController,
                        todayKey: containsToday ? _todayKey : null,
                      ),
                    ),
                  ),
                  // Resumen semanal SIEMPRE visible: data local desde la
                  // lista de días, sin esperar al RPC remoto. Esto evita el
                  // gigante hueco blanco entre los días y la bottom nav.
                  if (widget.days.isNotEmpty) ...[
                    const SizedBox(height: Spacing.xl),
                    DashboardWeekSummary(
                      days: widget.days,
                      weekStart: widget.weekStart,
                      onTapNext: widget.onOpenDay,
                    ),
                  ],
                  // Insights remotos sólo si efectivamente hay data — el
                  // placeholder "no disponibles" lo absorbió el resumen.
                  if (widget.insights != null) ...[
                    const SizedBox(height: Spacing.lg),
                    const _SectionLabel(text: 'Insights'),
                    const SizedBox(height: Spacing.sm),
                    DashboardInsightsCompact(
                      insights: widget.insights,
                      error: null,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
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
