import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/durations.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/atoms/app_button.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_card.dart';
import 'package:gym_flutter/features/workout/presentation/routine_day/widgets/routine_day_focus_parts.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/weight_format.dart';

/// Vista "One Exercise Focus": un ejercicio ocupa la pantalla completa, swipe
/// horizontal entre ejercicios. El stepper superior muestra el progreso por
/// ejercicio y permite saltar tap-eando un dot.
///
/// Reutiliza la `ExerciseCard` existente para no duplicar la lógica de
/// timer/sets/save. Solo cambia el contenedor (PageView) y añade el stepper.
class RoutineDayActiveFocusView extends StatefulWidget {
  const RoutineDayActiveFocusView({
    super.key,
    required this.sessionId,
    required this.exercises,
    required this.completedLogs,
    this.setDrafts = const [],
    required this.lastPerformances,
    required this.coachingAnalyses,
    required this.effectiveReadOnly,
    required this.onSetAdded,
    this.onSetRemoved,
    this.onFinishWorkout,
    this.isAdapting = false,
    this.onAddExercise,
    this.onReplaceExercise,
    this.onQuickSetUndone,
  });

  final String sessionId;
  final List<Exercise> exercises;
  final List<SetLog> completedLogs;
  final List<SetLog> setDrafts;
  final Map<String, SetLog?> lastPerformances;
  final Map<String, CoachingAnalysis?> coachingAnalyses;
  final bool effectiveReadOnly;
  final void Function(SetLog log) onSetAdded;
  final void Function(String exerciseId, int setIndex)? onSetRemoved;
  final VoidCallback? onFinishWorkout;
  final bool isAdapting;
  final VoidCallback? onAddExercise;
  final ValueChanged<Exercise>? onReplaceExercise;

  /// Tras "Deshacer" una serie registrada de un toque (p. ej. para cortar el
  /// descanso que arrancó al registrarla).
  final VoidCallback? onQuickSetUndone;

  @override
  State<RoutineDayActiveFocusView> createState() =>
      _RoutineDayActiveFocusViewState();
}

class _RoutineDayActiveFocusViewState extends State<RoutineDayActiveFocusView> {
  late final PageController _pageController;

  /// Para abrir la serie siguiente desde el botón fijo inferior: la tarjeta
  /// es quien conoce borradores y prefill.
  final Map<String, GlobalKey<ExerciseCardState>> _cardKeys = {};

  GlobalKey<ExerciseCardState> _cardKeyFor(String exerciseId) =>
      _cardKeys.putIfAbsent(exerciseId, GlobalKey<ExerciseCardState>.new);

  /// Barra fija del botón de serie: el aviso "Deshacer" se coloca encima
  /// de ella, si no la tapaba y el toque de la serie siguiente caía en él.
  final _completeBarKey = GlobalKey();

  /// Primera serie objetivo sin registrar del ejercicio, o `null`.
  int? _nextPendingSetFor(Exercise ex) {
    final done = widget.completedLogs
        .where((l) => l.exerciseId == ex.id)
        .map((l) => l.setIndex)
        .toSet();
    for (var n = 1; n <= ex.targetSets; n++) {
      if (!done.contains(n)) return n;
    }
    return null;
  }

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = _firstIncompleteIndex();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void didUpdateWidget(covariant RoutineDayActiveFocusView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el padre rebuilde con una lista de ejercicios distinta (p.ej. el
    // bloc emite una nueva sesión) y nuestro índice ya no es válido, lo
    // clampeamos antes del próximo build para evitar RangeError en
    // `_ExerciseStepper` (que indexa `exercises[currentIndex]`).
    final exCount = widget.exercises.length;
    final oldIds = oldWidget.exercises.map((ex) => ex.id).toSet();
    final addedIndex = widget.exercises.indexWhere(
      (ex) => !oldIds.contains(ex.id),
    );
    if (addedIndex >= 0 && _pageController.hasClients) {
      _currentIndex = addedIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(addedIndex);
        }
      });
      return;
    }
    if (exCount == 0) {
      _currentIndex = 0;
    } else if (_currentIndex >= exCount) {
      _currentIndex = exCount - 1;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentIndex);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _firstIncompleteIndex() {
    for (var i = 0; i < widget.exercises.length; i++) {
      final ex = widget.exercises[i];
      final done = _doneCountFor(ex);
      if (done < ex.targetSets) return i;
    }
    return widget.exercises.isEmpty ? 0 : widget.exercises.length - 1;
  }

  /// Primer ejercicio con series objetivo pendientes, o `null` si están
  /// todos completos.
  int? _firstPendingIndex() {
    for (var i = 0; i < widget.exercises.length; i++) {
      final ex = widget.exercises[i];
      if (ex.replacedByExerciseName == null &&
          _doneCountFor(ex) < ex.targetSets) {
        return i;
      }
    }
    return null;
  }

  int _doneCountFor(Exercise ex) =>
      widget.completedLogs.where((l) => l.exerciseId == ex.id).length;

  void _jumpTo(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    _pageController.animateToPage(
      index,
      duration: AppDurations.medium,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.exercises.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No hay ejercicios para esta sesión',
                style: TextStyle(color: context.colors.textSecondary),
              ),
              if (!widget.effectiveReadOnly && widget.onAddExercise != null)
                TextButton.icon(
                  onPressed: widget.isAdapting ? null : widget.onAddExercise,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Añadir ejercicio extra'),
                ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        if (widget.isAdapting) const LinearProgressIndicator(),
        FocusViewExerciseStepper(
          exercises: widget.exercises,
          completedLogs: widget.completedLogs,
          currentIndex: _currentIndex,
          onTap: _jumpTo,
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.exercises.length,
            onPageChanged: (i) {
              HapticFeedback.selectionClick();
              setState(() {
                _currentIndex = i;
                _previewRetryScheduled = false;
              });
            },
            itemBuilder: (context, index) {
              final ex = widget.exercises[index];
              final allSetsDone = _doneCountFor(ex) >= ex.targetSets;
              final isLast = index == widget.exercises.length - 1;
              // En el último ejercicio, si quedó alguno anterior sin terminar
              // se ofrece volver a él antes que "Finalizar" ('TERMINASTE'
              // aparecía aunque faltaran series).
              final pendingIndex = isLast ? _firstPendingIndex() : null;
              final nextIndex = isLast ? pendingIndex : index + 1;
              final nextEx = nextIndex == null
                  ? null
                  : widget.exercises[nextIndex];
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.md,
                  Spacing.lg,
                  Spacing.lg,
                ),
                child: Column(
                  children: [
                    if (ex.isExtra ||
                        ex.replacesExerciseName != null ||
                        ex.replacedByExerciseName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          ex.replacesExerciseName != null
                              ? 'Sustituye a ${ex.replacesExerciseName} · Solo esta sesión'
                              : ex.replacedByExerciseName != null
                              ? 'Series conservadas · Continuar con ${ex.replacedByExerciseName}'
                              : 'Ejercicio extra · Solo esta sesión',
                          style: context.text.bodySmall,
                        ),
                      ),
                    if (ex.replacedByExerciseName != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: context.colors.divider),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ex.name, style: context.text.titleMedium),
                            for (final log in widget.completedLogs.where(
                              (log) => log.exerciseId == ex.id,
                            ))
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Serie ${log.setIndex} · ${log.actualWeight} kg × ${log.actualReps}',
                                ),
                              ),
                          ],
                        ),
                      )
                    else
                      AbsorbPointer(
                        absorbing: widget.isAdapting,
                        child: ExerciseCard(
                          key: _cardKeyFor(ex.id),
                          exercise: ex,
                          sessionId: widget.sessionId,
                          initialCompletedSets: widget.completedLogs,
                          initialDrafts: widget.setDrafts,
                          lastPerformance: widget.lastPerformances[ex.id],
                          readOnly:
                              widget.effectiveReadOnly ||
                              ex.replacedByExerciseName != null,
                          coachingAnalysis: widget.coachingAnalyses[ex.id],
                          forceExpanded:
                              !widget.effectiveReadOnly &&
                              ex.replacedByExerciseName == null,
                          showCompleteButton: false,
                          onReplace:
                              !widget.effectiveReadOnly &&
                                  !allSetsDone &&
                                  !widget.isAdapting &&
                                  widget.onReplaceExercise != null
                              ? () => widget.onReplaceExercise!(ex)
                              : null,
                          onSetAdded:
                              widget.effectiveReadOnly ||
                                  ex.replacedByExerciseName != null
                              ? null
                              : widget.onSetAdded,
                          onSetRemoved:
                              widget.effectiveReadOnly ||
                                  ex.replacedByExerciseName != null
                              ? null
                              : (idx) => widget.onSetRemoved?.call(ex.id, idx),
                        ),
                      ),
                    if (allSetsDone &&
                        !widget.effectiveReadOnly &&
                        !widget.isAdapting) ...[
                      const SizedBox(height: Spacing.md),
                      FocusViewNextStepCta(
                        nextExerciseName: nextEx?.name,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          if (nextIndex != null) {
                            _jumpTo(nextIndex);
                          } else if (widget.onFinishWorkout != null) {
                            widget.onFinishWorkout!();
                          }
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        _buildCompleteSetBar(context),
      ],
    );
  }

  /// La tarjeta aún no existe en el primer frame (el `PageView` la monta
  /// después): se repinta una vez para poder leer la serie propuesta.
  bool _previewRetryScheduled = false;

  void _completeQuick(Exercise ex) {
    final card = _cardKeyFor(ex.id).currentState;
    final log = card?.completeNextSetQuick();
    if (card == null || log == null) {
      card?.openNextPendingSet();
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final barHeight = _completeBarKey.currentContext?.size?.height ?? 0;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            Spacing.lg,
            0,
            Spacing.lg,
            barHeight + Spacing.sm,
          ),
          content: Text(
            'Serie ${log.setIndex} registrada · ${_loadLabel(log.actualWeight, log.actualReps)}',
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () {
              _cardKeyFor(ex.id).currentState?.undoSet(log.setIndex);
              widget.onQuickSetUndone?.call();
            },
          ),
        ),
      );
  }

  /// Botón fijo abajo, al alcance del pulgar: registra la serie siguiente
  /// con el peso y las reps propuestos de un toque. Para cambiarlos se
  /// pulsa la fila de la serie (abre la hoja). Sin valores que proponer
  /// abre directamente la hoja.
  Widget _buildCompleteSetBar(BuildContext context) {
    if (widget.effectiveReadOnly || widget.exercises.isEmpty) {
      return const SizedBox.shrink();
    }
    final ex =
        widget.exercises[_currentIndex.clamp(0, widget.exercises.length - 1)];
    final next = _nextPendingSetFor(ex);
    if (next == null || ex.replacedByExerciseName != null) {
      return const SizedBox.shrink();
    }
    final card = _cardKeyFor(ex.id).currentState;
    if (card == null && !_previewRetryScheduled) {
      _previewRetryScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
    final preview = card?.quickSetPreview;
    final isFirstSet = _doneCountFor(ex) == 0;
    return SafeArea(
      key: _completeBarKey,
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.xs,
          Spacing.lg,
          Spacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isFirstSet && preview != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.xs),
                child: Text(
                  'Toca una serie para cambiar peso o repeticiones',
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                key: const ValueKey('focus_complete_set_button'),
                label: preview == null
                    ? 'Registrar serie $next'
                    : 'Serie $next hecha · ${_loadLabel(preview.weight, preview.reps)}',
                uppercaseLabel: false,
                icon: Icons.check_rounded,
                onPressed: widget.isAdapting ? null : () => _completeQuick(ex),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _loadLabel(double weight, int reps) => '${formatLoad(weight)} × $reps';
