import 'package:gym_flutter/core/utils/calendar_dates.dart';
import 'package:flutter/material.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/weekly_insights.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/utils/routine_day_phase_resolver.dart';

/// Elegir qué entrenar y consultar el historial son dos tareas distintas.
/// La fecha programada nunca se utiliza para iniciar un entrenamiento nuevo.
class DashboardWeeklyView extends StatefulWidget {
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
    this.onCurrentWeek,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  final List<RoutineDay> days;
  final DateTime weekStart;
  final Routine? selectedRoutine;
  final WeeklyInsights? insights;
  final String? insightsError;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onOpenSelectedRoutineStats;
  final void Function(RoutineDay day, DateTime date) onOpenDay;
  final VoidCallback? onCurrentWeek;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  State<DashboardWeeklyView> createState() => _DashboardWeeklyViewState();
}

class _DashboardWeeklyViewState extends State<DashboardWeeklyView> {
  bool _history = false;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get _currentWeek =>
      !_today.isBefore(widget.weekStart) &&
      _today.isBefore(AppCalendar.addDays(widget.weekStart, 7));

  @override
  Widget build(BuildContext context) {
    final days = [...widget.days]
      ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
    final historyDays =
        days.where((day) => day.lastSessionDate != null).toList()
          ..sort((a, b) => b.lastSessionDate!.compareTo(a.lastSessionDate!));
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: [
            Text(
              widget.selectedRoutine?.name ?? 'Tu rutina',
              style: context.text.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Elige qué entrenar. Cada sesión nueva se registra con la fecha de hoy.',
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Entrenar')),
                ButtonSegment(value: true, label: Text('Historial')),
              ],
              selected: {_history},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                setState(() => _history = selection.single);
                if (!_history && !_currentWeek) widget.onCurrentWeek?.call();
              },
            ),
            const SizedBox(height: 24),
            if (widget.isLoading) const LinearProgressIndicator(),
            if (widget.errorMessage != null) ...[
              Text(
                widget.errorMessage!,
                style: TextStyle(color: context.colors.error),
              ),
              TextButton(
                onPressed: widget.onRetry,
                child: const Text('Reintentar'),
              ),
            ],
            if (_history) ...[
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
              const SizedBox(height: 16),
              if (historyDays.isEmpty && !widget.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No hay entrenamientos registrados esta semana.'),
                ),
              for (final day in historyDays)
                _TrainingRow(
                  day: day,
                  history: true,
                  today: _today,
                  enabled: !widget.isLoading && widget.errorMessage == null,
                  onOpen: () => widget.onOpenDay(day, day.lastSessionDate!),
                ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: widget.onOpenSelectedRoutineStats,
                icon: const Icon(Icons.insights_rounded),
                label: const Text('Ver historial completo'),
              ),
            ] else ...[
              Text(
                'Hoy · ${_shortDate(_today)}',
                style: context.text.titleMedium,
              ),
              const SizedBox(height: 16),
              if (days.isEmpty && !widget.isLoading)
                const Text(
                  'Esta rutina todavía no tiene entrenamientos. Añádelos desde Rutinas.',
                ),
              for (final day in days)
                _TrainingRow(
                  day: day,
                  history: false,
                  today: _today,
                  enabled:
                      !widget.isLoading &&
                      widget.errorMessage == null &&
                      _currentWeek,
                  onOpen: () => widget.onOpenDay(day, _today),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

String _shortDate(DateTime date) => formatRoutineDayDateLabel(date);

class _TrainingRow extends StatelessWidget {
  const _TrainingRow({
    required this.day,
    required this.history,
    required this.today,
    required this.enabled,
    required this.onOpen,
  });

  final RoutineDay day;
  final bool history;
  final DateTime today;
  final bool enabled;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final date = day.lastSessionDate;
    final active = day.status == WorkoutDayStatus.inProgress;
    final completedToday =
        date != null && DateUtils.isSameDay(date, today) && !active;
    final preview = day.exerciseNamesPreview.isNotEmpty
        ? day.exerciseNamesPreview.join(' · ')
        : day.exercises.map((e) => e.name).join(' · ');
    final status = date == null
        ? 'Sin entrenar esta semana'
        : '${active ? 'Pendiente desde' : 'Realizado el'} ${_shortDate(date)}';
    final label = history
        ? (active ? 'Continuar sesión' : 'Ver sesión')
        : active
        ? (DateUtils.isSameDay(date, today)
              ? 'Continuar sesión'
              : 'Continuar sesión anterior')
        : completedToday
        ? 'Ver entrenamiento de hoy'
        : 'Entrenar hoy';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.divider),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            day.name,
            style: context.text.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Programado: ${day.dayNameFull}',
            style: context.text.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodyMedium,
            ),
          ],
          const SizedBox(height: 12),
          Text(
            status,
            style: context.text.bodyMedium?.copyWith(
              color: active
                  ? context.colors.primary
                  : context.colors.textSecondary,
            ),
          ),
          if (day.status == WorkoutDayStatus.completedPartial)
            Text(
              'Finalizado con series pendientes',
              style: context.text.bodySmall,
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: enabled ? onOpen : null,
            icon: Icon(
              history || completedToday
                  ? Icons.arrow_forward_rounded
                  : Icons.play_arrow_rounded,
            ),
            label: Text(label),
          ),
        ],
      ),
    );
  }
}
