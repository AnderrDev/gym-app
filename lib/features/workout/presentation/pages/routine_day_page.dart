import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/presentation/widgets/glass_container.dart';
import '../../../../core/presentation/widgets/kinetic_button.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/routine_day.dart';
import '../../domain/entities/set_log.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/entities/coaching_analysis.dart';
import '../bloc/workout_bloc.dart';
import '../bloc/workout_event.dart';
import '../bloc/workout_state.dart';
import '../widgets/exercise_card.dart';

class RoutineDayPage extends StatefulWidget {
  final RoutineDay routineDay;
  final String userId;
  final DateTime sessionDate;

  const RoutineDayPage({
    super.key,
    required this.routineDay,
    required this.userId,
    required this.sessionDate,
  });

  @override
  State<RoutineDayPage> createState() => _RoutineDayPageState();
}

class _RoutineDayPageState extends State<RoutineDayPage> {
  final List<SetLog> _currentSessionLogs = [];
  
  // ── Timer Global ──────────────────────────────────────────
  Timer? _globalRestTimer;
  int _secondsRemaining = 0;
  int _totalRestSeconds = 60;
  bool _isResting = false;

  @override
  void dispose() {
    _globalRestTimer?.cancel();
    super.dispose();
  }

  void _startRestTimer(int seconds) {
    _globalRestTimer?.cancel();
    setState(() {
      _secondsRemaining = seconds;
      _totalRestSeconds = seconds;
      _isResting = true;
    });

    _globalRestTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
        if (_secondsRemaining <= 3 && _secondsRemaining > 0) {
          HapticFeedback.lightImpact();
        }
      } else {
        _stopTimer();
      }
    });
  }

  void _stopTimer() {
    _globalRestTimer?.cancel();
    setState(() {
      _isResting = false;
      _secondsRemaining = 0;
    });
    HapticFeedback.heavyImpact();
  }

  String _formatTime(int seconds) {
    final mins = (seconds / 60).floor();
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    context.read<WorkoutBloc>().add(LoadDayInfo(
      userId: widget.userId,
      routineDayId: widget.routineDay.id,
      sessionDate: widget.sessionDate,
    ));
  }

  void _onSetAdded(SetLog log) {
    setState(() {
      final idx = _currentSessionLogs.indexWhere((l) => l.exerciseId == log.exerciseId && l.setIndex == log.setIndex);
      if (idx != -1) {
        _currentSessionLogs[idx] = log;
      } else {
        _currentSessionLogs.add(log);
      }
    });
    
    // Iniciar timer global (90s por defecto si no es edición)
    _startRestTimer(90);
  }

  double get _totalVolume => _currentSessionLogs.fold(0.0, (s, l) => s + (l.actualWeight * l.actualReps));
  

  bool get _isReadOnly => false;

  String get _dateLabel {
    const months = ['', 'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${widget.sessionDate.day} ${months[widget.sessionDate.month]} ${widget.sessionDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) context.read<WorkoutBloc>().add(const ResetWorkout());
      },
      child: BlocConsumer<WorkoutBloc, WorkoutState>(
        listener: (context, state) {
          if (state is WorkoutFinishedSuccess) {
            context.read<WorkoutBloc>().add(const ResetWorkout());
            Navigator.of(context).pop();
          }
          if (state is DayWorkoutStarted && _currentSessionLogs.isEmpty) {
            _currentSessionLogs.addAll(state.setLogs);
          }
        },
        builder: (context, state) {
          final session = state is DayWorkoutStarted ? state.session : null;
          final isCompleted = session?.completedAt != null;
          final effectiveReadOnly = _isReadOnly || isCompleted;
          
          final recentSessions = state is DayInfoLoaded ? state.recentSessions : (state is DayWorkoutStarted ? state.recentSessions : <WorkoutSession>[]);
          final recentSessionsLogs = (state is DayInfoLoaded ? state.recentSessionsLogs : (state is DayWorkoutStarted ? state.recentSessionsLogs : <String, List<SetLog>>{}));
          final lastSession = recentSessions.firstOrNull;
          final lastLogs = lastSession != null ? (recentSessionsLogs[lastSession.id] ?? <SetLog>[]) : <SetLog>[];
          final exercises = (state is DayInfoLoaded ? state.exercises : (state is DayWorkoutStarted ? state.exercises : <Exercise>[]));

          return Scaffold(
            backgroundColor: AppColors.background,
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  backgroundColor: AppColors.background,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  actions: [
                    if (lastSession != null)
                      IconButton(
                        icon: const Icon(Icons.history_rounded, color: AppColors.primary, size: 24),
                        onPressed: () => _showLastSessionDetails(lastSession, lastLogs, exercises),
                      ),
                    const SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: false,
                    titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    title: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.routineDay.name.toUpperCase(),
                          style: AppTextStyles.heading2.copyWith(fontSize: 16, letterSpacing: 1.2),
                        ),
                        Text(
                          _dateLabel,
                          style: AppTextStyles.label.copyWith(color: AppColors.textSecondary, fontSize: 10),
                        ),
                      ],
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primary.withOpacity(0.1),
                                AppColors.background,
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          right: -20,
                          top: 40,
                          child: Icon(
                            Icons.fitness_center,
                            size: 180,
                            color: AppColors.primary.withOpacity(0.03),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VOLUMEN ACTUAL',
                              style: AppTextStyles.label.copyWith(letterSpacing: 1.5, fontSize: 10),
                            ),
                            Text(
                              '${_totalVolume.toStringAsFixed(0)} KG',
                              style: AppTextStyles.displayNumber,
                            ),
                          ],
                        ),
                        if (effectiveReadOnly)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isCompleted ? AppColors.success.withOpacity(0.1) : AppColors.surfaceHighlight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isCompleted ? 'COMPLETADO' : 'LECTURA',
                              style: AppTextStyles.label.copyWith(
                                color: isCompleted ? AppColors.success : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                if (state is WorkoutInitial || state is WorkoutLoading)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
                else if (state is WorkoutError)
                  SliverFillRemaining(child: _buildError(state.message))
                else if (state is DayWorkoutStarted) ...[
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final ex = state.exercises[index];
                          final liveAnalysis = _analyzePerformance(
                            state.exercises, 
                            _currentSessionLogs,
                            history: state.recentSessions,
                            historyLogs: state.recentSessionsLogs,
                          );
                          final exAnalysis = liveAnalysis.firstWhereOrNull(
                            (a) => a.exerciseId == ex.id || a.exerciseName == ex.name
                          );
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ExerciseCard(
                              exercise: ex,
                              sessionId: state.session.id,
                              initialCompletedSets: _currentSessionLogs,
                              lastPerformance: state.lastPerformances[ex.id],
                              readOnly: effectiveReadOnly,
                              coachingAnalysis: exAnalysis,
                              onSetAdded: effectiveReadOnly ? null : (log) {
                                _onSetAdded(log);
                                HapticFeedback.selectionClick();
                              },
                            ),
                          );
                        },
                        childCount: state.exercises.length,
                      ),
                    ),
                  ),
                  _buildLiveCoachingSection(state.exercises, _currentSessionLogs),
                ]
                else
                  const SliverFillRemaining(child: SizedBox()),

                const SliverToBoxAdapter(child: SizedBox(height: 140)),
              ],
            ),
            bottomNavigationBar: effectiveReadOnly 
              ? null 
              : GlassContainer(
                  blur: 30,
                  opacity: 0.1,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
                  child: Row(
                    children: [
                      _buildTimerCircle(),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EN PROGRESO',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              '${exercises.length} ejercicios planificados',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      KineticButton(
                        fullWidth: false,
                        label: 'FINALIZAR',
                        onTap: () {
                          HapticFeedback.heavyImpact();
                          if (state is DayWorkoutStarted) {
                             final analysis = _analyzePerformance(
                              state.exercises, 
                              _currentSessionLogs,
                              history: state.recentSessions,
                              historyLogs: state.recentSessionsLogs,
                            );
                            _showSummaryModal(context, state.exercises, _currentSessionLogs, state.session.id, analysis);
                          }
                        },
                      ),
                    ],
                  ),
                ),
          );
        },
      ),
    );
  }

  Widget _buildLiveCoachingSection(List<Exercise> exercises, List<SetLog> logs) {
    final state = context.read<WorkoutBloc>().state;
    final history = state is DayWorkoutStarted ? state.recentSessions : (state is DayInfoLoaded ? state.recentSessions : <WorkoutSession>[]);
    final historyLogs = state is DayWorkoutStarted ? state.recentSessionsLogs : (state is DayInfoLoaded ? state.recentSessionsLogs : <String, List<SetLog>>{});
    
    final analysis = _analyzePerformance(
      exercises, 
      logs,
      history: history,
      historyLogs: historyLogs,
    );
    final relevantAnalysis = analysis.where((a) => a.completedSets! > 0 && a.recommendation.isNotEmpty).toList();
    if (relevantAnalysis.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: _buildPersistedCoachingSection(relevantAnalysis),
    );
  }

  Widget _buildHistoryExerciseCard(String exerciseName, List<SetLog> logs, SetLog? lastRecord, CoachingAnalysis? coaching) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exerciseName, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                if (lastRecord != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'RÉCORD: ${lastRecord.actualWeight.toStringAsFixed(0)}kg x ${lastRecord.actualReps}',
                      style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.surfaceHighlight),
          ...logs.map((log) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.surfaceHighlight.withOpacity(0.3))),
            ),
            child: Row(children: [
              _Circle(label: '${log.setIndex}'),
              const SizedBox(width: 16),
              Expanded(child: Text('${log.actualWeight.toStringAsFixed(1)} kg', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
              Text('${log.actualReps} reps', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            ]),
          )),
          if (coaching != null) ...[
            const Divider(height: 1, color: AppColors.surfaceHighlight),
            Padding(
              padding: const EdgeInsets.all(12),
              child: _buildCoachingAdvice(coaching),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCoachingAdvice(CoachingAnalysis coaching) {
    final score = coaching.performanceScore ?? 1.0;
    final isGood = score >= 0.85;
    final isGreat = score >= 1.0;
    
    final accentColor = isGreat 
        ? const Color(0xFF4CAF50) 
        : (isGood ? Colors.amber[400]! : Colors.orange[400]!);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, size: 16, color: accentColor),
              const SizedBox(width: 8),
              Text(
                'CONSEJO DEL COACH',
                style: AppTextStyles.label.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (coaching.recommendation.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getFriendlyRecommendation(coaching.recommendation),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (coaching.feedback?.isNotEmpty ?? false)
            Text(
              coaching.feedback!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }

  String _getFriendlyRecommendation(String rec) {
    switch (rec) {
      case 'INCREASE_WEIGHT': return '🔥 ¡Increíble! Sube un poco el peso el próximo día.';
      case 'MANTAIN_WEIGHT': return '✅ Buen trabajo. Mantén este peso para consolidar.';
      case 'DECREASE_WEIGHT': return '⚠️ Baja un poco el peso para mejorar la técnica.';
      case 'INCREASE_REPS': return '💪 Casi lo tienes. Intenta hacer 1-2 reps más.';
      case 'DECREASE_SETS': return '📉 Te has pasado un poco. Baja una serie para recuperar.';
      default: return rec;
    }
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(msg, textAlign: TextAlign.center, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<WorkoutBloc>().add(LoadDayInfo(userId: widget.userId, routineDayId: widget.routineDay.id, sessionDate: widget.sessionDate)),
              icon: const Icon(Icons.refresh),
              label: const Text('REINTENTAR'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.surface, foregroundColor: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  void _showLastSessionDetails(WorkoutSession session, List<SetLog> logs, List<Exercise> exercises) {
    HapticFeedback.mediumImpact();
    final dateLabel = '${session.sessionDate.day}/${session.sessionDate.month}/${session.sessionDate.year}';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            children: [
              Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 32, height: 4, decoration: BoxDecoration(color: AppColors.surfaceHighlight, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(children: [
                  const Icon(Icons.history_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('SESIÓN ANTERIOR', style: AppTextStyles.heading2.copyWith(fontSize: 20)),
                    Text('Completada el $dateLabel', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                  ])),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary)),
                ]),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  children: [
                    Builder(
                      builder: (context) {
                        final pastTotalVolume = logs.fold(0.0, (s, l) => s + (l.actualWeight * l.actualReps));
                        return Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.show_chart_rounded, color: AppColors.primary, size: 20),
                              const SizedBox(width: 12),
                              Text('VOLUMEN TOTAL: ${pastTotalVolume.toStringAsFixed(0)} kg', style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                            ],
                          ),
                        );
                      }
                    ),
                    ..._groupByExercise(logs, exercises).entries.map((e) {
                      final coaching = session.coachingAnalysis?.firstWhereOrNull(
                        (a) => a.exerciseName == e.key || a.exerciseId == exercises.firstWhereOrNull((ex) => ex.name == e.key)?.id
                      );
                      return _buildHistoryExerciseCard(e.key, e.value, null, coaching);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, List<SetLog>> _groupByExercise(List<SetLog> logs, List<Exercise> exercises) {
    final exerciseMap = {for (final e in exercises) e.id: e.name};
    final grouped = <String, List<SetLog>>{};
    for (final log in logs) {
      final name = exerciseMap[log.exerciseId] ?? 'Ejercicio';
      grouped.putIfAbsent(name, () => []).add(log);
    }
    return grouped;
  }

  void _showSummaryModal(BuildContext context, List<Exercise> exercises, List<SetLog> logs, String sessionId, List<CoachingAnalysis> analysis) {
    final totalTarget = widget.routineDay.targetSetsCount;
    final totalCompleted = logs.length;
    final isStriclyCompleted = totalCompleted >= totalTarget;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.surfaceHighlight, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Icon(
              isStriclyCompleted ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
              color: isStriclyCompleted ? AppColors.success : AppColors.primary,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              isStriclyCompleted ? '¡RUTINA COMPLETADA!' : 'SESIÓN INCOMPLETA',
              style: AppTextStyles.heading1.copyWith(fontSize: 24),
            ),
            Text(
              isStriclyCompleted 
                ? 'Has cumplido con todo el volumen programado.' 
                : 'Faltan ${totalTarget - totalCompleted} series para completar el objetivo.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(label: 'SERIES', value: '$totalCompleted/$totalTarget'),
                _StatItem(label: 'VOLUMEN', value: '${_totalVolume.toStringAsFixed(0)}kg'),
              ],
            ),
            
            if (analysis.any((a) => a.recommendation.isNotEmpty)) ...[
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('COACHING & AJUSTES', style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: analysis.where((a) => a.recommendation.isNotEmpty).length,
                  separatorBuilder: (_, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = analysis.where((a) => a.recommendation.isNotEmpty).toList()[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceHighlight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.exerciseName, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(item.recommendation, style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('CONTINUAR', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<WorkoutBloc>().add(FinishWorkoutSession(sessionId, coachingAnalysis: analysis));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('FINALIZAR Y GUARDAR', style: AppTextStyles.label.copyWith(color: AppColors.background, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<CoachingAnalysis> _analyzePerformance(
    List<Exercise> exercises, 
    List<SetLog> logs, {
    List<WorkoutSession> history = const [],
    Map<String, List<SetLog>> historyLogs = const {},
  }) {
    final List<CoachingAnalysis> results = [];
    
    for (final ex in exercises) {
      final exLogs = logs.where((l) => l.exerciseId == ex.id).toList();
      final completedSets = exLogs.length;
      
      bool weightMet = true;
      bool repsMet = true;
      String rec = '';
      double performanceScore = 1.0;
      String? feedback;

      // 1. Analizar rendimiento actual
      double currentAvgWeight = 0;
      double currentAvgReps = 0;
      if (completedSets > 0) {
        currentAvgWeight = exLogs.map((l) => l.actualWeight).reduce((a, b) => a + b) / completedSets;
        currentAvgReps = exLogs.map((l) => l.actualReps).reduce((a, b) => a + b) / completedSets;
        
        weightMet = currentAvgWeight >= ex.targetWeight;
        repsMet = currentAvgReps >= ex.targetReps;
        
        final weightRatio = ex.targetWeight > 0 ? currentAvgWeight / ex.targetWeight : 1.0;
        final repsRatio = ex.targetReps > 0 ? currentAvgReps / ex.targetReps : 1.0;
        final setsRatio = ex.targetSets > 0 ? (completedSets / ex.targetSets).clamp(0.0, 1.0) : 1.0;
        
        performanceScore = (weightRatio * 0.45 + repsRatio * 0.45 + setsRatio * 0.1);
      }

      // 2. Analizar Historial (Tendencias)
      // Obtenemos stats de las últimas sesiones para este ejercicio
      final List<Map<String, double>> historyStats = [];
      for (final session in history) {
        final sLogs = historyLogs[session.id] ?? [];
        final exPastLogs = sLogs.where((l) => l.exerciseId == ex.id).toList();
        if (exPastLogs.isNotEmpty) {
          final avgW = exPastLogs.map((l) => l.actualWeight).reduce((a, b) => a + b) / exPastLogs.length;
          final avgR = exPastLogs.map((l) => l.actualReps).reduce((a, b) => a + b) / exPastLogs.length;
          historyStats.add({'weight': avgW, 'reps': avgR});
        }
      }

      // 3. Lógica de coaching basada en rendimiento e historial
      if (completedSets > 0) {
        // Caso A: Estancamiento o Regresión (Lo que pidió el usuario)
        if (historyStats.length >= 2) {
          final last = historyStats[0]; // Sesión más reciente (1 semana atrás)
          final prev = historyStats[1]; // Penúltima sesión (2 semanas atrás)
          
          final isRegressing = last['reps']! < prev['reps']! && last['weight']! <= prev['weight']!;
          final isStagnated = last['reps']! < ex.targetReps && prev['reps']! < ex.targetReps;

          if (isRegressing || (isStagnated && currentAvgReps < ex.targetReps)) {
            rec = '📉 RENDIMIENTO DECRECIENTE: Llevas dos sesiones sin alcanzar las reps objetivo. Te aconsejo bajar un poco el peso (2.5 - 5kg) para recuperar la progresión y técnica.';
            feedback = 'WEIGHT_REDUCTION_ADVISED';
            performanceScore = performanceScore.clamp(0.0, 0.7);
          }
        }

        // Si no hay tendencia negativa clara, aplicamos lógica estándar refinada
        if (rec.isEmpty) {
          if (completedSets < ex.targetSets) {
            rec = 'Sigue así. Te faltan ${ex.targetSets - completedSets} series para completar el objetivo.';
            feedback = 'IN_PROGRESS';
          } else if (!weightMet) {
            rec = 'Peso por debajo del objetivo. Prioriza la técnica hoy, pero intenta subir 1-2kg la próxima sesión.';
            feedback = 'KEEP_CONSISTENCY';
          } else if (!repsMet) {
            rec = 'Reps por debajo del objetivo. Si te sientes pesado, baja 2.5kg para asegurar el rango de reps.';
            feedback = 'MODERATE_ADJUSTMENT';
          } else {
            if (currentAvgWeight > ex.targetWeight || currentAvgReps > ex.targetReps) {
              rec = '🚀 ¡SUPERACIÓN! Has superado los objetivos. Sube el peso un nivel la próxima sesión sin miedo.';
              feedback = 'PROGRESSIVE_OVERLOAD';
              performanceScore = 1.2;
            } else {
              rec = '🎯 OBJETIVO CUMPLIDO. Has mantenido la intensidad. Prepárate para subir carga pronto.';
              feedback = 'READY_TO_PROGRESS';
              performanceScore = 1.0;
            }
          }
        }
      } else {
        rec = ''; // Vacío para no mostrar consejos aún
        performanceScore = 1.0;
        feedback = 'PENDING';
      }

      results.add(CoachingAnalysis(
        exerciseId: ex.id,
        exerciseName: ex.name,
        completedSets: completedSets,
        targetSets: ex.targetSets,
        weightMet: weightMet,
        repsMet: repsMet,
        recommendation: rec,
        performanceScore: performanceScore,
        feedback: feedback,
      ));
    }
    return results;
  }

  Widget _buildTimerCircle() {
    final progress = _totalRestSeconds > 0 ? _secondsRemaining / _totalRestSeconds : 0.0;
    
    return GestureDetector(
      onTap: () {
        if (_isResting) {
          _stopTimer();
        } else {
          _startRestTimer(60); // Quick start 60s
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 54,
            height: 54,
            child: CircularProgressIndicator(
              value: _isResting ? progress : 0,
              strokeWidth: 3,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              color: AppColors.primary,
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _isResting ? AppColors.primary : AppColors.surfaceHighlight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isResting ? Icons.timer_rounded : Icons.play_arrow_rounded,
              color: _isResting ? Colors.black : AppColors.textPrimary,
              size: 20,
            ),
          ),
          if (_isResting)
            Positioned(
              bottom: -15,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatTime(_secondsRemaining),
                  style: AppTextStyles.label.copyWith(
                    color: Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPersistedCoachingSection(List<CoachingAnalysis> analysis) {
    final relevantAnalysis = analysis.where((a) => a.recommendation.isNotEmpty).toList();
    if (relevantAnalysis.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ANÁLISIS DE INTELIGENCIA',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Recomendaciones del Coach Pro',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...relevantAnalysis.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.arrow_right_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.exerciseName.toUpperCase(),
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.recommendation,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
          const Divider(height: 32, color: AppColors.surfaceHighlight),
          Center(
            child: Text(
              'Ajustes automáticos aplicados para tu próxima sesión.',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textDisabled,
                fontStyle: FontStyle.italic,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textDisabled, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary)),
      ],
    );
  }
}

// _StatHeaderDelegate removed as it was merged into SliverAppBar.bottom

class _Circle extends StatelessWidget {
  final String label;
  const _Circle({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
      child: Center(
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 10),
        ),
      ),
    );
  }
}
