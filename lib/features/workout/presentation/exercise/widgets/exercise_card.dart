import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/i18n/coaching_messages.dart';
import 'package:gym_flutter/core/routes/args/routing_args.dart';
import 'package:gym_flutter/core/routes/router_helpers.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_card_body.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_card_header.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_stats_bottom_sheet.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/remote_target_sheet.dart';

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
    _syncPulse();
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
      _completedSets.remove(setIndex);
      // Si estábamos colapsados por "all done", volver a expandir.
      if (!widget.forceExpanded) _isExpanded = true;
    });
    widget.onSetRemoved?.call(setIndex);
  }

  void _calculateLiveAdvice(SetLog log) {
    final targetW = widget.exercise.targetWeight;
    final targetR = widget.exercise.targetReps;

    String? advice;
    if (log.actualWeight < targetW) {
      advice =
          'No alcanzaste el peso objetivo. Baja un poco el ritmo y prioriza técnica, o mantén este peso para la siguiente.';
    } else if (log.actualReps < targetR) {
      advice =
          'Te faltaron repeticiones. Intenta descansar un poco más antes de la siguiente serie o reduce el peso 2.5kg.';
    } else if (log.actualWeight >= targetW && log.actualReps >= targetR) {
      advice = '¡Excelente! Objetivo cumplido. ¡Mantenlo así!';
    }

    if (advice != null) {
      setState(() {
        _liveAdvice = advice;
        _showLiveAdvice = true;
      });
      _liveAdviceTimer?.cancel();
      _liveAdviceTimer = Timer(const Duration(seconds: 8), () {
        if (mounted) setState(() => _showLiveAdvice = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = _completedSets.length;

    return Card(
      color: AppColors.surface,
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
            recommendationText: _getFriendlyRecommendation,
          ),
          ExerciseCardBody(
            isExpanded: _isExpanded,
            targetSets: _targetSets,
            exercise: widget.exercise,
            sessionId: widget.sessionId,
            completedSets: _completedSets,
            lastPerformance: widget.lastPerformance,
            readOnly: widget.readOnly,
            coachingAnalysis: widget.coachingAnalysis,
            onSaveSet: _onSetSaved,
            onUnsaveSet: widget.readOnly ? null : _onSetUnsaved,
            recommendationText: _getFriendlyRecommendation,
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
