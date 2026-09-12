import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/i18n/coaching_messages.dart';
import 'package:gym_flutter/core/routes/args/routing_args.dart';
import 'package:gym_flutter/core/routes/router_helpers.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/complete_set_sheet.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_card_body.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_card_header.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_stats_bottom_sheet.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/remote_target_sheet.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/set_feedback.dart';

/// Tarjeta asistente por ejercicio con Records, Autofill y Edición.
/// El timer de descanso es gestionado por la pantalla padre (timer global).
class ExerciseCard extends StatefulWidget {
  final Exercise exercise;
  final String sessionId;
  final List<SetLog> initialCompletedSets;
  final SetLog? lastPerformance;
  final void Function(SetLog)? onSetAdded;
  final void Function(int setIndex)? onSetRemoved;
  final bool readOnly;
  final CoachingAnalysis? coachingAnalysis;
  final bool forceExpanded;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.sessionId,
    this.initialCompletedSets = const [],
    this.lastPerformance,
    this.onSetAdded,
    this.onSetRemoved,
    this.readOnly = false,
    this.coachingAnalysis,
    this.forceExpanded = false,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  final Map<int, SetLog> _completedSets = {};
  // Últimos valores de series desmarcadas (setIndex → log) para no perder
  // lo editado si el usuario desmarca y vuelve a completar.
  final Map<int, SetLog> _drafts = {};
  bool _isExpanded = true;

  // ── Feedback en tiempo real ────────────────────────────────
  String? _liveAdvice;
  bool _showLiveAdvice = false;
  Timer? _liveAdviceTimer;

  int get _targetSets => widget.exercise.targetSets;
  bool get _allDone => _completedSets.length >= _targetSets;
  bool get _hasActiveCoaching =>
      widget.coachingAnalysis?.hasActionableAdvice ?? false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    for (final log in widget.initialCompletedSets) {
      if (log.exerciseId == widget.exercise.id) {
        _completedSets[log.setIndex] = log;
      }
    }
    if (widget.readOnly) {
      // En historial colapsamos por defecto, salvo que el caller fuerce.
      _isExpanded = widget.forceExpanded;
    }
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant ExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // El bloc es la fuente de verdad: cuando emite una lista nueva (guardado
    // confirmado, o revertido porque falló) resincronizamos. Sin esto una
    // serie revertida seguía marcada en pantalla.
    if (!identical(
      oldWidget.initialCompletedSets,
      widget.initialCompletedSets,
    )) {
      _syncCompletedFromWidget();
    }
    _syncPulse();
  }

  void _syncCompletedFromWidget() {
    final incoming = <int, SetLog>{
      for (final log in widget.initialCompletedSets)
        if (log.exerciseId == widget.exercise.id) log.setIndex: log,
    };
    if (mapEquals(incoming, _completedSets)) return;
    setState(() {
      // Lo que desaparece se guarda como borrador: si el guardado falló,
      // el usuario reabre la serie con sus valores y reintenta.
      for (final entry in _completedSets.entries) {
        if (!incoming.containsKey(entry.key)) _drafts[entry.key] = entry.value;
      }
      _completedSets
        ..clear()
        ..addAll(incoming);
    });
  }

  /// Solo pulsa cuando hay coaching activo y aún quedan sets por hacer.
  /// Detener la animación cuando no es relevante evita repintar la card a
  /// 60fps mientras el usuario no necesita atención visual.
  void _syncPulse() {
    final shouldPulse = _hasActiveCoaching && !_allDone;
    if (shouldPulse && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!shouldPulse && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _liveAdviceTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _onSetSaved(SetLog log, int setIndex) {
    HapticFeedback.mediumImpact();
    _calculateLiveAdvice(log);
    setState(() {
      _completedSets[setIndex] = log;
      // Colapsa solo cuando termina la última serie y nadie nos fuerza.
      if (_completedSets.length >= _targetSets && !widget.forceExpanded) {
        _isExpanded = false;
      }
    });
    widget.onSetAdded?.call(log);
  }

  void _onSetUnsaved(int setIndex) {
    setState(() {
      final removed = _completedSets.remove(setIndex);
      // Recordamos lo registrado para que al volver a abrir la serie se
      // conserve el peso/reps editado en vez de volver al prefill.
      if (removed != null) _drafts[setIndex] = removed;
      // Si estábamos colapsados por "all done", volver a expandir.
      if (!widget.forceExpanded) _isExpanded = true;
    });
    widget.onSetRemoved?.call(setIndex);
  }

  int? get _nextPendingSet {
    for (var n = 1; n <= _targetSets; n++) {
      if (!_completedSets.containsKey(n)) return n;
    }
    return null;
  }

  /// Valores iniciales del modal para la serie [setNumber]. Prioridad:
  ///   1. Lo ya registrado (editar una serie completada).
  ///   2. El borrador de una serie desmarcada.
  ///   3. La serie previa registrada en esta sesión — si subiste el peso en
  ///      la serie 1, la 2 arranca con ese peso.
  ///   4. El objetivo de la rutina; si no tiene peso, la última performance.
  ({double weight, int reps}) _prefillFor(int setNumber) {
    final known = _completedSets[setNumber] ?? _drafts[setNumber];
    if (known != null) {
      return (weight: known.actualWeight, reps: known.actualReps);
    }
    final previous = _completedSets.entries
        .where((e) => e.key < setNumber)
        .fold<SetLog?>(null, (acc, e) {
          if (acc == null || e.key > acc.setIndex) return e.value;
          return acc;
        });
    if (previous != null) {
      return (weight: previous.actualWeight, reps: previous.actualReps);
    }
    final ex = widget.exercise;
    final last = widget.lastPerformance;
    if (ex.targetWeight <= 0 && last != null && last.actualWeight > 0) {
      return (weight: last.actualWeight, reps: last.actualReps);
    }
    return (weight: ex.targetWeight, reps: ex.targetReps);
  }

  Future<void> _openSetSheet(int setNumber) async {
    unawaited(HapticFeedback.selectionClick());
    final done = _completedSets[setNumber];
    final prefill = _prefillFor(setNumber);
    final result = await CompleteSetSheet.show(
      context,
      exerciseName: widget.exercise.name,
      setNumber: setNumber,
      targetSets: _targetSets,
      targetWeight: widget.exercise.targetWeight,
      targetReps: widget.exercise.targetReps,
      initialWeight: prefill.weight,
      initialReps: prefill.reps,
      isDone: done != null,
      lastPerformance: widget.lastPerformance,
    );
    if (!mounted || result == null) return;
    switch (result) {
      case CompleteSetSave(:final weight, :final reps):
        if (done != null &&
            done.actualWeight == weight &&
            done.actualReps == reps) {
          return;
        }
        _drafts.remove(setNumber);
        _onSetSaved(
          SetLog(
            sessionId: widget.sessionId,
            exerciseId: widget.exercise.id,
            actualWeight: weight,
            actualReps: reps,
            setIndex: setNumber,
          ),
          setNumber,
        );
      case CompleteSetUnsave():
        _onSetUnsaved(setNumber);
    }
  }

  void _calculateLiveAdvice(SetLog log) {
    final advice = evaluateSet(
      weight: log.actualWeight,
      reps: log.actualReps,
      targetWeight: widget.exercise.targetWeight,
      targetReps: widget.exercise.targetReps,
    ).message;

    setState(() {
      _liveAdvice = advice;
      _showLiveAdvice = true;
    });
    _liveAdviceTimer?.cancel();
    _liveAdviceTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _showLiveAdvice = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = _completedSets.length;

    return Card(
      color: context.colors.surface,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          ExerciseCardHeader(
            exercise: widget.exercise,
            lastPerformance: widget.lastPerformance,
            coachingAnalysis: widget.coachingAnalysis,
            readOnly: widget.readOnly,
            isExpanded: _isExpanded,
            allDone: _allDone,
            targetSets: _targetSets,
            doneCount: doneCount,
            showLiveAdvice: _showLiveAdvice,
            liveAdvice: _liveAdvice,
            pulseAnimation: _pulseAnimation,
            showExpandChevron: !widget.forceExpanded,
            onToggleExpanded: () {
              if (widget.forceExpanded) return;
              HapticFeedback.selectionClick();
              setState(() => _isExpanded = !_isExpanded);
            },
            onOpenTargetEditor: _showRemoteTargetEditor,
            onOpenInsights: () {
              HapticFeedback.selectionClick();
              final authState = context.read<AuthBloc>().state;
              if (authState is Authenticated) {
                ExerciseStatsBottomSheet.show(
                  context,
                  userId: authState.user.id,
                  exerciseId: widget.exercise.id,
                  exerciseName: widget.exercise.name,
                );
              }
            },
            onOpenProgress: () {
              HapticFeedback.selectionClick();
              final authState = context.read<AuthBloc>().state;
              if (authState is Authenticated) {
                pushExerciseProgress(
                  context,
                  ExerciseProgressArgs(
                    userId: authState.user.id,
                    exerciseId: widget.exercise.id,
                    exerciseName: widget.exercise.name,
                  ),
                );
              }
            },
            onOpenHowTo: () {
              HapticFeedback.selectionClick();
              pushExerciseDetail(context, widget.exercise.id);
            },
            recommendationText: _getFriendlyRecommendation,
          ),
          ExerciseCardBody(
            isExpanded: _isExpanded,
            targetSets: _targetSets,
            exercise: widget.exercise,
            completedSets: _completedSets,
            readOnly: widget.readOnly,
            coachingAnalysis: widget.coachingAnalysis,
            recommendationText: _getFriendlyRecommendation,
            nextPendingSet: _nextPendingSet,
            onOpenSet: widget.readOnly ? null : _openSetSheet,
          ),
        ],
      ),
    );
  }

  String _getFriendlyRecommendation(String rec) => CoachingMessages.short(rec);

  void _showRemoteTargetEditor() {
    RemoteTargetSheet.show(
      context,
      exerciseId: widget.exercise.id,
      initialWeight: widget.exercise.targetWeight,
      initialReps: widget.exercise.targetReps,
    );
  }
}
