import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/molecules/app_card.dart';
import 'package:gym_flutter/core/utils/calendar_dates.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/utils/routine_day_phase_resolver.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/utils/routine_color.dart';

/// Pestaña HOY con un plan semanal cargado.
///
/// Jerarquía: qué día es → cómo va la semana → qué toca entrenar (tarjeta
/// destacada) → el resto de días en filas compactas. El historial semana a
/// semana es un modo secundario. La fecha programada nunca se usa para
/// iniciar un entrenamiento nuevo: toda sesión nueva se registra con hoy.
class DashboardWeeklyView extends StatefulWidget {
  const DashboardWeeklyView({
    super.key,
    required this.days,
    this.weekSessions = const [],
    required this.weekStart,
    required this.selectedRoutine,
    required this.insights,
    required this.insightsError,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onOpenSelectedRoutineStats,
    required this.onOpenDay,
    this.onCurrentWeek,
    this.onChangeRoutine,
    this.onRefresh,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  final List<RoutineDay> days;
  final List<WorkoutSession> weekSessions;
  final DateTime weekStart;
  final Routine? selectedRoutine;
  final WeeklyInsights? insights;

  /// Si fallan los insights la pantalla sigue siendo útil sin ellos: no se
  /// muestra error, sólo se omite la fila de métricas.
  final String? insightsError;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onOpenSelectedRoutineStats;
  final void Function(RoutineDay day, DateTime date) onOpenDay;
  final VoidCallback? onCurrentWeek;

  /// `null` si el usuario tiene una sola rutina.
  final VoidCallback? onChangeRoutine;

  /// Recarga el plan. Tirar hacia abajo en móvil; botón en la cabecera para
  /// web/escritorio, donde con ratón no hay pull-to-refresh.
  final Future<void> Function()? onRefresh;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  State<DashboardWeeklyView> createState() => _DashboardWeeklyViewState();
}

class _DashboardWeeklyViewState extends State<DashboardWeeklyView>
    with WidgetsBindingObserver {
  bool _history = false;

  /// Semana para la que ya se pidió volver a la actual: evita disparar el
  /// refresco en cada frame mientras llega el plan nuevo.
  DateTime? _autoRefreshedFrom;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get _currentWeek =>
      !_today.isBefore(widget.weekStart) &&
      _today.isBefore(AppCalendar.addDays(widget.weekStart, 7));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// La app puede quedarse abierta de una semana a otra: al volver se
  /// re-evalúa "hoy" y, si cambió la semana, se recarga sola.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  void _maybeReturnToCurrentWeek() {
    if (_history || _currentWeek || widget.isLoading) return;
    if (_autoRefreshedFrom == widget.weekStart) return;
    _autoRefreshedFrom = widget.weekStart;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onCurrentWeek?.call();
    });
  }

  void _setHistory(bool value) {
    setState(() => _history = value);
    if (!value && !_currentWeek) widget.onCurrentWeek?.call();
  }

  @override
  Widget build(BuildContext context) {
    _maybeReturnToCurrentWeek();
    final days = [...widget.days]
      ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
    final enabled = !widget.isLoading && widget.errorMessage == null;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: _maybeRefreshable(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              Spacing.lgPlus,
              Spacing.md,
              Spacing.lgPlus,
              Spacing.xxl,
            ),
            children: [
              _Header(
                today: _today,
                routineName: widget.selectedRoutine?.name ?? 'Tu rutina',
                isLoading: widget.isLoading,
                onRefresh: widget.onRefresh,
                onChangeRoutine: widget.onChangeRoutine,
              ),
              const SizedBox(height: Spacing.lg),
              if (widget.isLoading) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: Spacing.md),
              ],
              if (widget.errorMessage != null) ...[
                _InlineError(
                  message: widget.errorMessage!,
                  onRetry: widget.onRetry,
                ),
                const SizedBox(height: Spacing.lg),
              ],
              if (_history)
                ..._buildHistory(context, days, enabled)
              else
                ..._buildToday(context, days, enabled && _currentWeek),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildToday(
    BuildContext context,
    List<RoutineDay> days,
    bool enabled,
  ) {
    if (days.isEmpty && !widget.isLoading) {
      return const [
        _Message(
          icon: Icons.playlist_add_rounded,
          text:
              'Esta rutina todavía no tiene entrenamientos. Añádelos desde Rutinas.',
        ),
      ];
    }
    final recommended = recommendedDay(days, _today);
    final done = days
        .where(
          (d) =>
              d.status == WorkoutDayStatus.completed ||
              d.status == WorkoutDayStatus.completedPartial,
        )
        .length;
    final others = [
      for (final d in days)
        if (d.id != recommended?.id) d,
    ];
    final insights = widget.insights;
    return [
      _WeekProgress(
        weekStart: widget.weekStart,
        today: _today,
        entries: historyEntries(days, widget.weekSessions),
        plannedWeekdays: {for (final d in days) d.dayOfWeek},
        done: done,
        total: days.length,
      ),
      if (insights != null && insights.completedSessions > 0) ...[
        const SizedBox(height: Spacing.md),
        _InsightsRow(insights: insights),
      ],
      const SizedBox(height: Spacing.xl),
      if (recommended != null)
        _HeroDayCard(
          day: recommended,
          today: _today,
          enabled: enabled,
          onOpen: () => widget.onOpenDay(recommended, _today),
        )
      else if (days.isNotEmpty)
        _WeekCompleteCard(total: days.length),
      if (others.isNotEmpty) ...[
        const SizedBox(height: Spacing.xl),
        Text(
          recommended == null ? 'Repetir un entrenamiento' : 'Otros días',
          style: context.text.titleMedium,
        ),
        const SizedBox(height: Spacing.sm),
        for (var i = 0; i < others.length; i++)
          _CompactDayRow(
            day: others[i],
            accentIndex: days.indexOf(others[i]),
            today: _today,
            enabled: enabled,
            onOpen: () => widget.onOpenDay(others[i], _today),
          ),
      ],
      const SizedBox(height: Spacing.lg),
      Wrap(
        spacing: Spacing.sm,
        children: [
          TextButton.icon(
            onPressed: () => _setHistory(true),
            icon: const Icon(Icons.history_rounded),
            label: const Text('Historial'),
          ),
          TextButton.icon(
            onPressed: widget.onOpenSelectedRoutineStats,
            icon: const Icon(Icons.insights_rounded),
            label: const Text('Estadísticas'),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildHistory(
    BuildContext context,
    List<RoutineDay> days,
    bool enabled,
  ) {
    final entries = historyEntries(days, widget.weekSessions);
    return [
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => _setHistory(false),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Volver a hoy'),
        ),
      ),
      Row(
        children: [
          IconButton(
            tooltip: 'Semana anterior',
            onPressed: widget.isLoading ? null : widget.onPreviousWeek,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Text(
              '${_shortDate(widget.weekStart)} — ${_shortDate(AppCalendar.addDays(widget.weekStart, 6))}',
              textAlign: TextAlign.center,
              style: context.text.titleSmall,
            ),
          ),
          IconButton(
            tooltip: 'Semana siguiente',
            onPressed: widget.isLoading || _currentWeek
                ? null
                : widget.onNextWeek,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
      const SizedBox(height: Spacing.md),
      if (entries.isEmpty && !widget.isLoading)
        const _Message(
          icon: Icons.event_busy_rounded,
          text: 'No hay entrenamientos registrados esta semana.',
        ),
      for (final day in entries)
        _HistoryRow(
          day: day,
          enabled: enabled,
          onOpen: () => widget.onOpenDay(day, day.lastSessionDate!),
        ),
      const SizedBox(height: Spacing.md),
      TextButton.icon(
        onPressed: widget.onOpenSelectedRoutineStats,
        icon: const Icon(Icons.insights_rounded),
        label: const Text('Ver historial completo'),
      ),
    ];
  }

  Widget _maybeRefreshable({required Widget child}) {
    final onRefresh = widget.onRefresh;
    if (onRefresh == null) return child;
    return RefreshIndicator(onRefresh: onRefresh, child: child);
  }
}

String _shortDate(DateTime date) => formatRoutineDayDateLabel(date);

const _weekdaysEs = [
  '',
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];
const _weekdayInitials = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
const _monthsShortEs = [
  '',
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// "12.345" — separador de miles español sin depender de los datos de
/// locale de `intl` (no inicializados en widget tests).
String _thousands(num value) {
  final digits = value.round().abs().toString();
  final buf = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  return buf.toString();
}

/// "5 ejercicios · 15 series" a partir de lo que traiga el día.
String? _dayMeta(RoutineDay day) {
  final exercises = day.exercises.isNotEmpty
      ? day.exercises.length
      : day.exerciseNamesPreview.length;
  if (exercises == 0) return null;
  final sets = day.targetSetsCount > 0
      ? day.targetSetsCount
      : day.exercises.fold<int>(0, (sum, e) => sum + e.targetSets);
  final parts = [
    '$exercises ${exercises == 1 ? 'ejercicio' : 'ejercicios'}',
    if (sets > 0) '$sets series',
  ];
  return parts.join(' · ');
}

/// Una entrada por sesión de la semana (la más reciente primero), con el
/// día de rutina al que pertenece. Sin sesiones conocidas cae a la última
/// sesión de cada día (lo único que trae `days`).
@visibleForTesting
List<RoutineDay> historyEntries(
  List<RoutineDay> days,
  List<WorkoutSession> sessions,
) {
  if (sessions.isEmpty) {
    return days.where((day) => day.lastSessionDate != null).toList()
      ..sort((a, b) => b.lastSessionDate!.compareTo(a.lastSessionDate!));
  }
  final byId = {for (final d in days) d.id: d};
  final sorted = [...sessions]
    ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
  return [
    for (final s in sorted)
      if (byId[s.routineDayId] case final day?)
        day.copyWith(
          lastSessionDate: s.sessionDate,
          status: s.completedAt == null
              ? WorkoutDayStatus.inProgress
              : s.totalTargetSets > 0 &&
                    s.completedSetsCount < s.totalTargetSets
              ? WorkoutDayStatus.completedPartial
              : WorkoutDayStatus.completed,
        ),
  ];
}

/// "El día que toca": la sesión en curso si la hay; si no, el primer día
/// sin entrenar esta semana a partir del día de hoy (o el primero pendiente
/// si los de hoy en adelante ya están hechos). `null` si está todo hecho.
@visibleForTesting
RoutineDay? recommendedDay(List<RoutineDay> days, DateTime today) {
  final sorted = [...days]..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
  final inProgress = sorted
      .where((d) => d.status == WorkoutDayStatus.inProgress)
      .firstOrNull;
  if (inProgress != null) return inProgress;
  final pending = sorted.where((d) => d.lastSessionDate == null).toList();
  return pending.where((d) => d.dayOfWeek >= today.weekday).firstOrNull ??
      pending.firstOrNull;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.today,
    required this.routineName,
    required this.isLoading,
    this.onRefresh,
    this.onChangeRoutine,
  });

  final DateTime today;
  final String routineName;
  final bool isLoading;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onChangeRoutine;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_weekdaysEs[today.weekday]}, ${today.day} '
                        '${_monthsShortEs[today.month]}'
                    .toUpperCase(),
                style: context.text.labelMedium?.copyWith(
                  color: colors.textSecondary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                routineName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (onRefresh != null)
          IconButton(
            tooltip: 'Actualizar',
            onPressed: isLoading ? null : onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        if (onChangeRoutine != null)
          TextButton.icon(
            onPressed: onChangeRoutine,
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('Cambiar'),
          ),
      ],
    );
  }
}

/// Tira L–D de la semana + "N de M entrenamientos hechos".
class _WeekProgress extends StatelessWidget {
  const _WeekProgress({
    required this.weekStart,
    required this.today,
    required this.entries,
    required this.plannedWeekdays,
    required this.done,
    required this.total,
  });

  final DateTime weekStart;
  final DateTime today;
  final List<RoutineDay> entries;
  final Set<int> plannedWeekdays;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final byDate = <DateTime, WorkoutDayStatus>{};
    for (final e in entries) {
      final d = e.lastSessionDate!;
      final key = DateTime(d.year, d.month, d.day);
      // Con varias sesiones el mismo día manda la que sigue abierta.
      if (byDate[key] != WorkoutDayStatus.inProgress) byDate[key] = e.status;
    }
    return AppCard(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$done de $total entrenamientos hechos',
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Esta semana',
                style: context.text.labelMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                _WeekDot(
                  initial: _weekdayInitials[i],
                  date: AppCalendar.addDays(weekStart, i),
                  status: byDate[AppCalendar.addDays(weekStart, i)],
                  isToday: AppCalendar.addDays(weekStart, i) == today,
                  planned: plannedWeekdays.contains(i + 1),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekDot extends StatelessWidget {
  const _WeekDot({
    required this.initial,
    required this.date,
    required this.status,
    required this.isToday,
    required this.planned,
  });

  final String initial;
  final DateTime date;
  final WorkoutDayStatus? status;
  final bool isToday;
  final bool planned;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final trained =
        status == WorkoutDayStatus.completed ||
        status == WorkoutDayStatus.completedPartial;
    final inProgress = status == WorkoutDayStatus.inProgress;
    final Color fill = trained
        ? colors.success
        : inProgress
        ? colors.primary.withValues(alpha: 0.15)
        : colors.surfaceHighlight;
    final Color border = isToday || inProgress
        ? colors.primary
        : Colors.transparent;
    final semantics = [
      _weekdaysEs[date.weekday],
      '${date.day}',
      if (trained) 'entrenado',
      if (inProgress) 'en curso',
      if (isToday) 'hoy',
    ].join(', ');
    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            initial,
            style: context.text.labelSmall?.copyWith(
              color: isToday ? colors.primary : colors.textSecondary,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: Border.all(color: border, width: 2),
            ),
            child: trained
                ? Icon(Icons.check_rounded, size: 18, color: colors.onSuccess)
                : Text(
                    '${date.day}',
                    style: context.text.labelMedium?.copyWith(
                      color: inProgress || isToday
                          ? colors.primary
                          : colors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(height: Spacing.xs),
          // Punto bajo los días que la rutina tiene previstos.
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: planned ? colors.textSecondary : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Volumen (con tendencia), adherencia y récords de la semana.
class _InsightsRow extends StatelessWidget {
  const _InsightsRow({required this.insights});

  final WeeklyInsights insights;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final trend = insights.volumeTrendPercent;
    final hasTrend = insights.previousWeekVolume > 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _InsightTile(
            label: 'Volumen',
            value: '${_thousands(insights.totalVolume)} kg',
            // En un tercio de pantalla "vs. semana anterior" no cabía: el
            // icono de tendencia lo dice y el lector de pantalla lo lee.
            caption: hasTrend
                ? '${trend >= 0 ? '+' : '−'}${trend.abs().toStringAsFixed(0)} %'
                : null,
            captionIcon: trend >= 0
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            captionSemantics:
                '${trend.abs().toStringAsFixed(0)} % ${trend >= 0 ? 'más' : 'menos'} que la semana anterior',
            captionColor: trend >= 0 ? colors.successText : colors.error,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: _InsightTile(
            label: 'Adherencia',
            value: '${insights.adherenceRate.toStringAsFixed(0)} %',
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: _InsightTile(
            label: 'Récords',
            value: '${insights.personalRecords}',
            valueColor: insights.personalRecords > 0
                ? colors.warningText
                : null,
          ),
        ),
      ],
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.label,
    required this.value,
    this.caption,
    this.captionIcon,
    this.captionSemantics,
    this.captionColor,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? caption;
  final IconData? captionIcon;
  final String? captionSemantics;
  final Color? captionColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.md,
      ),
      borderRadius: BorderRadius.circular(Radii.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.text.labelSmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: context.text.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: valueColor ?? colors.textPrimary,
              ),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Semantics(
              label: captionSemantics,
              excludeSemantics: captionSemantics != null,
              child: Row(
                children: [
                  if (captionIcon != null) ...[
                    Icon(captionIcon, size: 14, color: captionColor),
                    const SizedBox(width: 2),
                  ],
                  Flexible(
                    child: Text(
                      caption!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelSmall?.copyWith(
                        color: captionColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// El entrenamiento que toca: tarjeta destacada con el CTA principal.
class _HeroDayCard extends StatelessWidget {
  const _HeroDayCard({
    required this.day,
    required this.today,
    required this.enabled,
    required this.onOpen,
  });

  final RoutineDay day;
  final DateTime today;
  final bool enabled;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = day.status == WorkoutDayStatus.inProgress;
    final date = day.lastSessionDate;
    final meta = _dayMeta(day);
    final preview = day.exerciseNamesPreview.isNotEmpty
        ? day.exerciseNamesPreview.join(' · ')
        : day.exercises.map((e) => e.name).join(' · ');
    final label = active
        ? (date != null && DateUtils.isSameDay(date, today)
              ? 'Continuar sesión'
              : 'Continuar sesión anterior')
        : 'Entrenar hoy';
    return Container(
      padding: const EdgeInsets.all(Spacing.lgPlus),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            active ? 'EN CURSO' : 'TE TOCA HOY',
            style: context.text.labelMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            day.name,
            style: context.text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            ['Previsto el ${day.dayNameFull.toLowerCase()}', ?meta].join(' · '),
            style: context.text.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: Spacing.md),
            Text(
              preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodyMedium,
            ),
          ],
          if (active && date != null) ...[
            const SizedBox(height: Spacing.md),
            Text(
              'Empezada el ${_shortDate(date)}',
              style: context.text.bodyMedium?.copyWith(color: colors.primary),
            ),
          ],
          const SizedBox(height: Spacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: enabled ? onOpen : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekCompleteCard extends StatelessWidget {
  const _WeekCompleteCard({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(Spacing.lgPlus),
      decoration: BoxDecoration(
        color: colors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radii.xl),
        border: Border.all(color: colors.success.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.success,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.emoji_events_rounded, color: colors.onSuccess),
          ),
          const SizedBox(width: Spacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Semana completada!',
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  total == 1
                      ? 'Has hecho el entrenamiento de la semana. Toca descansar.'
                      : 'Has hecho los $total entrenamientos. Toca descansar.',
                  style: context.text.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Resto de días: fila compacta pulsable entera.
class _CompactDayRow extends StatelessWidget {
  const _CompactDayRow({
    required this.day,
    required this.accentIndex,
    required this.today,
    required this.enabled,
    required this.onOpen,
  });

  final RoutineDay day;
  final int accentIndex;
  final DateTime today;
  final bool enabled;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final date = day.lastSessionDate;
    final trained = date != null && day.status != WorkoutDayStatus.inProgress;
    final completedToday = trained && DateUtils.isSameDay(date, today);
    final accent = RoutineColor.byIndex(context, accentIndex);
    final status = date == null
        ? _dayMeta(day) ?? 'Sin entrenar esta semana'
        : '${trained ? 'Realizado el' : 'Pendiente desde'} ${_shortDate(date)}'
              '${day.status == WorkoutDayStatus.completedPartial ? ' · con series pendientes' : ''}';
    final action = completedToday ? 'Ver entrenamiento de hoy' : 'Entrenar hoy';
    return Semantics(
      button: true,
      label: '${day.name}. $status. $action',
      excludeSemantics: true,
      child: AppCard(
        margin: const EdgeInsets.only(bottom: Spacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: enabled ? onOpen : null,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Text(
                day.dayName,
                style: context.text.labelMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),
            trained
                ? Icon(Icons.check_circle_rounded, color: colors.success)
                : Icon(
                    Icons.chevron_right_rounded,
                    color: enabled ? colors.textSecondary : colors.textDisabled,
                  ),
          ],
        ),
      ),
    );
  }
}

/// Entrada del modo historial: sesión real de la semana elegida.
class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.day,
    required this.enabled,
    required this.onOpen,
  });

  final RoutineDay day;
  final bool enabled;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = day.status == WorkoutDayStatus.inProgress;
    final date = day.lastSessionDate!;
    return AppCard(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      padding: const EdgeInsets.all(Spacing.lg),
      borderRadius: BorderRadius.circular(Radii.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.name,
                  style: context.text.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${active ? 'Pendiente desde' : 'Realizado el'} ${_shortDate(date)}',
                  style: context.text.bodySmall?.copyWith(
                    color: active ? colors.primary : colors.textSecondary,
                  ),
                ),
                if (day.status == WorkoutDayStatus.completedPartial)
                  Text(
                    'Finalizado con series pendientes',
                    style: context.text.bodySmall?.copyWith(
                      color: colors.warningText,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.sm),
          FilledButton.tonal(
            onPressed: enabled ? onOpen : null,
            child: Text(active ? 'Continuar sesión' : 'Ver sesión'),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      borderColor: colors.error.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.sm,
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colors.error),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              message,
              style: context.text.bodyMedium?.copyWith(color: colors.error),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
      child: Row(
        children: [
          Icon(icon, color: context.colors.textSecondary),
          const SizedBox(width: Spacing.md),
          Expanded(child: Text(text, style: context.text.bodyMedium)),
        ],
      ),
    );
  }
}
