import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/coaching_analysis.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/set_log.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_event.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import 'exercise_stats_bottom_sheet.dart';

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

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────────
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isExpanded = !_isExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _allDone
                              ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                              : AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _allDone ? Icons.check_circle : Icons.fitness_center,
                          size: 20,
                          color: _allDone
                              ? const Color(0xFF4CAF50)
                              : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.exercise.name,
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'TARGET: ${widget.exercise.targetWeight.toStringAsFixed(0)}kg x ${widget.exercise.targetReps}',
                                        style: AppTextStyles.label.copyWith(
                                          color: AppColors.primary,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$_targetSets series',
                                      style: AppTextStyles.label.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (widget.lastPerformance != null) ...[
                                  Text(
                                    '  •  ',
                                    style: TextStyle(
                                      color: AppColors.textSecondary
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  Icon(
                                    Icons.history,
                                    size: 12,
                                    color: AppColors.primary.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Record: ${widget.lastPerformance!.actualWeight.toStringAsFixed(0)}kg x ${widget.lastPerformance!.actualReps}',
                                    style: AppTextStyles.label.copyWith(
                                      color: AppColors.primary.withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      // ── Control Remoto de Objetivo ─────────────────
                      if (!widget.readOnly)
                        IconButton(
                          icon: const Icon(Icons.settings_remote, size: 20),
                          color: AppColors.primary.withValues(alpha: 0.6),
                          tooltip: 'Cambiar Objetivo Remotamente',
                          onPressed: () => _showRemoteTargetEditor(),
                        ),
                      const SizedBox(width: 4),
                      Text(
                        '$doneCount/$_targetSets',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: widget.readOnly
                              ? AppColors.textSecondary
                              : (_allDone
                                    ? const Color(0xFF4CAF50)
                                    : AppColors.primary),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.insights, size: 20),
                        color: AppColors.primary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
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
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.open_in_full_rounded, size: 18),
                        color: AppColors.primary.withValues(alpha: 0.9),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Ver progreso completo',
                        onPressed: () {
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
                      ),
                      const SizedBox(width: 4),
                      if (widget.coachingAnalysis != null &&
                          widget.coachingAnalysis!.feedback != 'PENDING') ...[
                        _buildCoachingBadge(widget.coachingAnalysis!),
                        const SizedBox(width: 8),
                      ],
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: progressFraction),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 5,
                            backgroundColor: AppColors.background,
                            color: _allDone
                                ? const Color(0xFF4CAF50)
                                : AppColors.primary,
                          );
                        },
                      ),
                    ),
                  ),
                  if (widget.coachingAnalysis != null &&
                      widget.coachingAnalysis!.feedback != 'PENDING' &&
                      !_isExpanded) ...[
                    const SizedBox(height: 12),
                    _buildCoachingAdvice(
                      widget.coachingAnalysis!,
                      compact: true,
                    ),
                  ],
                  if (_showLiveAdvice && _liveAdvice != null) ...[
                    const SizedBox(height: 12),
                    _buildLiveAdviceWidget(),
                  ],
                ],
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.fastOutSlowIn,
            alignment: Alignment.topCenter,
            child: !_isExpanded
                ? const SizedBox(width: double.infinity, height: 0)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        const Divider(height: 1, color: Color(0xFF2A2A2A)),
                        if (widget.coachingAnalysis != null &&
                            widget.coachingAnalysis!.feedback != 'PENDING') ...[
                          const SizedBox(height: 12),
                          _buildCoachingAdvice(widget.coachingAnalysis!),
                        ],
                        const SizedBox(height: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.0, 0.05),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          layoutBuilder: (currentChild, previousChildren) =>
                              Stack(
                                alignment: Alignment.topCenter,
                                children: <Widget>[
                                  ...previousChildren,
                                  ?currentChild,
                                ],
                              ),
                          child: _isResting
                              ? _buildRestTimer()
                              : Column(
                                  key: const ValueKey('sets_list'),
                                  children: List.generate(_targetSets, (i) {
                                    final n = i + 1;
                                    return _SetRow(
                                      key: ValueKey(
                                        'set_${widget.exercise.id}_$n',
                                      ),
                                      setNumber: n,
                                      targetReps: widget.exercise.targetReps,
                                      targetWeight:
                                          widget.exercise.targetWeight,
                                      isDone: _completedSets.containsKey(n),
                                      isActive: _activeSetIndex == n,
                                      completedLog: _completedSets[n],
                                      lastPerformanceLog:
                                          widget.lastPerformance,
                                      sessionId: widget.sessionId,
                                      exerciseId: widget.exercise.id,
                                      readOnly: widget.readOnly,
                                      onActivate: widget.readOnly
                                          ? () {}
                                          : () => _activateSet(n),
                                      onSaved: widget.readOnly
                                          ? (log) {}
                                          : (log) => _onSetSaved(log, n),
                                    );
                                  }),
                                ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachingBadge(CoachingAnalysis coaching) {
    final score = coaching.performanceScore ?? 1.0;
    final isGood = score >= 0.85;
    final isGreat = score >= 1.0;

    final color = isGreat
        ? const Color(0xFF4CAF50)
        : (isGood ? Colors.amber[400]! : Colors.orange[400]!);

    IconData trendIcon = Icons.psychology;
    switch (coaching.recommendation) {
      case 'INCREASE_WEIGHT':
        trendIcon = Icons.trending_up;
        break;
      case 'DECREASE_WEIGHT':
        trendIcon = Icons.trending_down;
        break;
      case 'MAINTAIN':
        trendIcon = Icons.trending_flat;
        break;
    }

    return ScaleTransition(
      scale: Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(trendIcon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              'COACH',
              style: AppTextStyles.label.copyWith(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachingAdvice(
    CoachingAnalysis coaching, {
    bool compact = false,
  }) {
    final score = coaching.performanceScore ?? 1.0;
    final isGood = score >= 0.85;
    final isGreat = score >= 1.0;

    final accentColor = isGreat
        ? const Color(0xFF4CAF50)
        : (isGood ? Colors.amber[400]! : Colors.orange[400]!);

    if (compact) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accentColor.withValues(alpha: 0.15), width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline, size: 14, color: accentColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                coaching.recommendation.isEmpty
                    ? (coaching.feedback ?? '')
                    : _getFriendlyRecommendation(coaching.recommendation),
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textPrimary,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right, size: 14, color: AppColors.textDisabled),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_outlined, size: 16, color: accentColor),
              const SizedBox(width: 8),
              Text(
                'CONSEJO DEL COACH',
                style: AppTextStyles.label.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (coaching.feedback != null && coaching.feedback!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                coaching.feedback ?? '',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          Text(
            _getFriendlyRecommendation(coaching.recommendation),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
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

  Widget _buildLiveAdviceWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.flash_on, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _liveAdvice!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildRestTimer() {
    final nextSet = _completedSets.length + 1;
    final fraction = _restSecondsLeft / widget.exercise.restTimerSeconds;
    final isDanger = _restSecondsLeft <= 10;
    return Container(
      key: const ValueKey('rest_timer'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (isDanger ? AppColors.error : AppColors.primary).withValues(
          alpha: 0.06,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDanger ? AppColors.error : AppColors.primary).withValues(
            alpha: 0.25,
          ),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            'DESCANSO',
            style: AppTextStyles.label.copyWith(
              color: isDanger ? AppColors.error : AppColors.primary,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: fraction.clamp(0.0, 1.0),
                  strokeWidth: 6,
                  strokeCap: StrokeCap.round,
                  backgroundColor: AppColors.background,
                  color: isDanger ? AppColors.error : AppColors.primary,
                ),
                Text(
                  _fmtTime(_restSecondsLeft),
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 24,
                    color: isDanger ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () => _skipRest(nextSet),
            icon: const Icon(Icons.skip_next, size: 20),
            label: const Text('Saltar descanso'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetRow extends StatefulWidget {
  final int setNumber;
  final int targetReps;
  final double targetWeight;
  final bool isDone;
  final bool isActive;
  final SetLog? completedLog;
  final SetLog? lastPerformanceLog;
  final String sessionId;
  final String exerciseId;
  final bool readOnly;
  final VoidCallback onActivate;
  final void Function(SetLog log) onSaved;

  const _SetRow({
    super.key,
    required this.setNumber,
    required this.targetReps,
    required this.targetWeight,
    required this.isDone,
    required this.isActive,
    required this.completedLog,
    required this.lastPerformanceLog,
    required this.sessionId,
    required this.exerciseId,
    required this.readOnly,
    required this.onActivate,
    required this.onSaved,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // ── Autofill Lógica ───────────────────
    final initialWeight = widget.isDone
        ? widget.completedLog!.actualWeight
        : widget.lastPerformanceLog?.actualWeight ?? widget.targetWeight;
    final initialReps = widget.isDone
        ? widget.completedLog!.actualReps
        : widget.lastPerformanceLog?.actualReps ?? widget.targetReps;

    _weightCtrl = TextEditingController(
      text: initialWeight > 0 ? initialWeight.toStringAsFixed(0) : '',
    );
    _repsCtrl = TextEditingController(
      text: initialReps > 0 ? initialReps.toString() : '',
    );
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final weight = double.tryParse(_weightCtrl.text) ?? 0.0;
    final reps = int.tryParse(_repsCtrl.text) ?? 0;
    if (reps <= 0) return;
    setState(() => _saving = true);
    final setLog = SetLog(
      sessionId: widget.sessionId,
      exerciseId: widget.exerciseId,
      actualWeight: weight,
      actualReps: reps,
      setIndex: widget.setNumber,
    );
    context.read<WorkoutBloc>().add(AddSetLogEvent(setLog));
    widget.onSaved(setLog);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDone && !widget.isActive) {
      final log = widget.completedLog!;
      return InkWell(
        onTap: widget.onActivate, // Permite EDITAR al tocar
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              _Circle(label: '${widget.setNumber}', filled: true),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${log.actualWeight} kg × ${log.actualReps} reps',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!widget.readOnly)
                const Icon(
                  Icons.edit,
                  color: Color(0xFF4CAF50),
                  size: 16,
                  semanticLabel: 'Editar',
                ),
            ],
          ),
        ),
      );
    }
    if (widget.isActive) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Circle(
                  label: '${widget.setNumber}',
                  filled: false,
                  active: true,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.isDone
                      ? 'Editando Serie ${widget.setNumber}'
                      : 'Serie ${widget.setNumber}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Peso (kg)',
                          labelStyle: AppTextStyles.label,
                          helperText:
                              'Objetivo: ${widget.targetWeight.toStringAsFixed(0)}kg',
                          helperStyle: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _repsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Reps',
                          labelStyle: AppTextStyles.label,
                          helperText: 'Objetivo: ${widget.targetReps}',
                          helperStyle: const TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _saving
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Icon(
                          widget.isDone ? Icons.refresh : Icons.check,
                          color: Colors.white,
                        ),
                      ),
              ],
            ),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: widget.onActivate,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Row(
          children: [
            _Circle(label: '${widget.setNumber}', filled: false),
            const SizedBox(width: 12),
            Text(
              'Serie ${widget.setNumber} pendiente',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final String label;
  final bool filled;
  final bool active;
  const _Circle({
    required this.label,
    required this.filled,
    this.active = false,
  });
  @override
  build(BuildContext context) {
    final bg = filled
        ? const Color(0xFF4CAF50)
        : active
        ? AppColors.primary
        : Colors.transparent;
    final border = filled
        ? const Color(0xFF4CAF50)
        : active
        ? AppColors.primary
        : AppColors.textSecondary;
    final textColor = (filled || active)
        ? Colors.white
        : AppColors.textSecondary;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1.5),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
