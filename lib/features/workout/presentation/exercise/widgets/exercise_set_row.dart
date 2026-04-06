import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/constants/app_colors.dart';
import 'package:gym_flutter/core/constants/app_text_styles.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/workout_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/workout_event.dart';

class ExerciseSetRow extends StatefulWidget {
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

  const ExerciseSetRow({
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
  State<ExerciseSetRow> createState() => _ExerciseSetRowState();
}

class _ExerciseSetRowState extends State<ExerciseSetRow> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
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
        onTap: widget.onActivate,
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
              _SetCircle(label: '${widget.setNumber}', filled: true),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${log.actualWeight} kg x ${log.actualReps} reps',
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
                _SetCircle(
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
                  child: TextField(
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
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
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
            _SetCircle(label: '${widget.setNumber}', filled: false),
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

class _SetCircle extends StatelessWidget {
  final String label;
  final bool filled;
  final bool active;

  const _SetCircle({
    required this.label,
    required this.filled,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
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
