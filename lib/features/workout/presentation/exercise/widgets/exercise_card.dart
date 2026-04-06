import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_flutter/core/routes/app_routes.dart';
import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/workout_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/workout_event.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gym_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_card_body.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_card_header.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_stats_bottom_sheet.dart';

// Duración de descanso por defecto (segundos)
const int _kDefaultRestSeconds = 90;

/// Tarjeta asistente por ejercicio con Timer, Records, Autofill y Edición.
class ExerciseCard extends StatefulWidget {
  final Exercise exercise;
  final String sessionId;
  final List<SetLog> initialCompletedSets;
  final SetLog? lastPerformance;
  final void Function(SetLog)? onSetAdded;
  final bool readOnly;
  final CoachingAnalysis? coachingAnalysis;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.sessionId,
    this.initialCompletedSets = const [],
    this.lastPerformance,
    this.onSetAdded,
    this.readOnly = false,
    this.coachingAnalysis,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  final Map<int, SetLog> _completedSets = {};
  int? _activeSetIndex;
  bool _isExpanded = true;

  // ── Timer de descanso ─────────────────────────────────────
  bool _isResting = false;
  int _restSecondsLeft = _kDefaultRestSeconds;
  Timer? _restTimer;

  // ── Feedback en tiempo real ────────────────────────────────
  String? _liveAdvice;
  bool _showLiveAdvice = false;

  int get _targetSets => widget.exercise.targetSets;
  bool get _allDone => _completedSets.length >= _targetSets;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    for (final log in widget.initialCompletedSets) {
      if (log.exerciseId == widget.exercise.id) {
        _completedSets[log.setIndex] = log;
      }
    }
    if (!widget.readOnly) {
      _findNextIncompleteSet();
    } else {
      setState(() {
        _activeSetIndex = null;
        _isExpanded = false; // Por defecto contraído en historial
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _restTimer?.cancel();
    super.dispose();
  }

  void _findNextIncompleteSet() {
    if (widget.readOnly) return;
    for (int i = 1; i <= _targetSets; i++) {
      if (!_completedSets.containsKey(i)) {
        setState(() => _activeSetIndex = i);
        return;
      }
    }
    setState(() {
      _activeSetIndex = null;
      if (_allDone) _isExpanded = false;
    });
  }

  void _onSetSaved(SetLog log, int setIndex) {
    HapticFeedback.mediumImpact();
    // Si era una edición de una serie ya completada, no activamos descanso
    final wasEditing = _completedSets.containsKey(setIndex);

    // Calcular feedback en tiempo real
    _calculateLiveAdvice(log);

    setState(() {
      _completedSets[setIndex] = log;
      _activeSetIndex = null;
    });
    widget.onSetAdded?.call(log);

    if (wasEditing) {
      _findNextIncompleteSet();
      return;
    }

    // Si es nueva serie, activar descanso
    final next = _getNextIncompleteSetAfter(setIndex);
    if (next != null) {
      _startRestTimer(next);
    } else {
      setState(() => _isExpanded = false);
    }
  }

  void _calculateLiveAdvice(SetLog log) {
    final targetW = widget.exercise.targetWeight;
    final targetR = widget.exercise.targetReps;

    String? advice;
    if (log.actualWeight < targetW) {
      advice =
          "No alcanzaste el peso objetivo. Baja un poco el ritmo y prioriza técnica, o mantén este peso para la siguiente.";
    } else if (log.actualReps < targetR) {
      advice =
          "Te faltaron repeticiones. Intenta descansar un poco más antes de la siguiente serie o reduce el peso 2.5kg.";
    } else if (log.actualWeight >= targetW && log.actualReps >= targetR) {
      advice = "¡Excelente! Objetivo cumplido. ¡Mantenlo así!";
    }

    if (advice != null) {
      setState(() {
        _liveAdvice = advice;
        _showLiveAdvice = true;
      });
      // Ocultar después de 8 segundos
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted) setState(() => _showLiveAdvice = false);
      });
    }
  }

  int? _getNextIncompleteSetAfter(int current) {
    for (int i = current + 1; i <= _targetSets; i++) {
      if (!_completedSets.containsKey(i)) return i;
    }
    return null;
  }

  void _startRestTimer(int nextSetIndex) {
    _restTimer?.cancel();
    setState(() {
      _isResting = true;
      _restSecondsLeft = widget.exercise.restTimerSeconds;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _restSecondsLeft--);
      if (_restSecondsLeft > 0 && _restSecondsLeft <= 3) {
        HapticFeedback.lightImpact();
      }
      if (_restSecondsLeft <= 0) {
        t.cancel();
        HapticFeedback.heavyImpact();
        setState(() {
          _isResting = false;
          _activeSetIndex = nextSetIndex;
        });
      }
    });
  }

  void _skipRest(int nextSetIndex) {
    _restTimer?.cancel();
    HapticFeedback.selectionClick();
    setState(() {
      _isResting = false;
      _activeSetIndex = nextSetIndex;
    });
  }

  void _activateSet(int setIndex) {
    if (_isResting || widget.readOnly) return;
    HapticFeedback.selectionClick();
    setState(() => _activeSetIndex = setIndex);
  }

  String _fmtTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return m > 0 ? '$m:${s.toString().padLeft(2, '0')}' : '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = _completedSets.length;
    final progressFraction = _targetSets > 0 ? doneCount / _targetSets : 0.0;
    final pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

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
            progressFraction: progressFraction,
            showLiveAdvice: _showLiveAdvice,
            liveAdvice: _liveAdvice,
            pulseAnimation: pulseAnimation,
            onToggleExpanded: () {
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
                context.push(
                  AppRoutes.exerciseProgress,
                  extra: {
                    'userId': authState.user.id,
                    'exerciseId': widget.exercise.id,
                    'exerciseName': widget.exercise.name,
                  },
                );
              }
            },
            recommendationText: _getFriendlyRecommendation,
          ),
          ExerciseCardBody(
            isExpanded: _isExpanded,
            isResting: _isResting,
            restSecondsLeft: _restSecondsLeft,
            restTotalSeconds: widget.exercise.restTimerSeconds,
            formattedRestTime: _fmtTime(_restSecondsLeft),
            targetSets: _targetSets,
            exercise: widget.exercise,
            sessionId: widget.sessionId,
            completedSets: _completedSets,
            activeSetIndex: _activeSetIndex,
            lastPerformance: widget.lastPerformance,
            readOnly: widget.readOnly,
            coachingAnalysis: widget.coachingAnalysis,
            onSkipRest: _skipRest,
            onActivateSet: _activateSet,
            onSaveSet: _onSetSaved,
            recommendationText: _getFriendlyRecommendation,
          ),
        ],
      ),
    );
  }

  String _getFriendlyRecommendation(String rec) {
    switch (rec) {
      case 'INCREASE_WEIGHT':
        return 'Sube el peso en la próxima sesión';
      case 'DECREASE_WEIGHT':
        return 'Baja un poco el peso para mejorar la técnica';
      case 'INCREASE_REPS':
        return 'Intenta hacer mas repeticiones con este peso';
      case 'MAINTAIN':
        return 'Buen trabajo, mantén el peso actual';
      default:
        return rec;
    }
  }

  void _showRemoteTargetEditor() {
    final weightCtrl = TextEditingController(
      text: widget.exercise.targetWeight.toStringAsFixed(0),
    );
    final repsCtrl = TextEditingController(
      text: widget.exercise.targetReps.toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Cambiar Objetivo Remoto', style: AppTextStyles.heading2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ajusta el objetivo para el resto de la sesión:',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: weightCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nuevo Peso (kg)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: repsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nuevas Reps'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final w =
                  double.tryParse(weightCtrl.text) ??
                  widget.exercise.targetWeight;
              final r =
                  int.tryParse(repsCtrl.text) ?? widget.exercise.targetReps;
              context.read<WorkoutBloc>().add(
                UpdateExerciseTarget(
                  exerciseId: widget.exercise.id,
                  targetWeight: w,
                  targetReps: r,
                ),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Objetivo actualizado remotamente'),
                ),
              );
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }
}
