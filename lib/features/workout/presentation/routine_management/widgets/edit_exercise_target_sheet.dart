import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/presentation/widgets/kinetic_button.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/features/workout/domain/entities/exercise.dart';
import 'package:gym_flutter/features/workout/presentation/routine_management/widgets/edit_exercise_target_form.dart';

/// Resultado del sheet de edición de targets de un ejercicio.
class EditExerciseTargetResult {
  const EditExerciseTargetResult({
    required this.targetSets,
    required this.targetReps,
    required this.targetWeight,
    required this.restSeconds,
  });

  final int targetSets;
  final int targetReps;
  final double targetWeight;
  final int restSeconds;
}

/// Sheet para editar series, reps, peso y descanso de un ejercicio sin
/// salir del editor del día. Devuelve `EditExerciseTargetResult` al guardar
/// o `null` si el usuario cierra.
class EditExerciseTargetSheet extends StatefulWidget {
  const EditExerciseTargetSheet({super.key, required this.exercise});

  final Exercise exercise;

  @override
  State<EditExerciseTargetSheet> createState() =>
      _EditExerciseTargetSheetState();
}

class _EditExerciseTargetSheetState extends State<EditExerciseTargetSheet> {
  late int _sets = widget.exercise.targetSets;
  late int _reps = widget.exercise.targetReps;
  late int _rest = widget.exercise.restTimerSeconds;
  late final TextEditingController _weightController = TextEditingController(
    text: _formatWeight(widget.exercise.targetWeight),
  );

  static String _formatWeight(double w) {
    if (w == w.roundToDouble()) return w.toStringAsFixed(0);
    return w.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _bump(
    int delta, {
    required int min,
    required int max,
    required int Function() get,
    required void Function(int) set,
  }) {
    HapticFeedback.selectionClick();
    setState(() {
      final next = (get() + delta).clamp(min, max);
      set(next);
    });
  }

  void _submit() {
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (weight == null || weight < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Peso inválido')));
      return;
    }
    Navigator.pop<EditExerciseTargetResult>(
      context,
      EditExerciseTargetResult(
        targetSets: _sets,
        targetReps: _reps,
        targetWeight: weight,
        restSeconds: _rest,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.sm,
        Spacing.xl,
        Spacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.exercise.name.toUpperCase(),
            style: context.text.headlineMedium?.copyWith(
              fontSize: 16,
              letterSpacing: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            widget.exercise.targetMuscle.toUpperCase(),
            style: context.text.labelMedium?.copyWith(
              color: context.colors.primary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: Spacing.xl),
          TargetStepperRow(
            label: 'SERIES',
            value: '$_sets',
            onMinus: () => _bump(
              -1,
              min: 1,
              max: 20,
              get: () => _sets,
              set: (v) => _sets = v,
            ),
            onPlus: () => _bump(
              1,
              min: 1,
              max: 20,
              get: () => _sets,
              set: (v) => _sets = v,
            ),
          ),
          const SizedBox(height: Spacing.md),
          TargetStepperRow(
            label: 'REPETICIONES',
            value: '$_reps',
            onMinus: () => _bump(
              -1,
              min: 1,
              max: 50,
              get: () => _reps,
              set: (v) => _reps = v,
            ),
            onPlus: () => _bump(
              1,
              min: 1,
              max: 50,
              get: () => _reps,
              set: (v) => _reps = v,
            ),
          ),
          const SizedBox(height: Spacing.md),
          TargetWeightField(controller: _weightController),
          const SizedBox(height: Spacing.md),
          TargetStepperRow(
            label: 'DESCANSO',
            value: _formatRest(_rest),
            onMinus: () => _bump(
              -15,
              min: 0,
              max: 600,
              get: () => _rest,
              set: (v) => _rest = v,
            ),
            onPlus: () => _bump(
              15,
              min: 0,
              max: 600,
              get: () => _rest,
              set: (v) => _rest = v,
            ),
          ),
          const SizedBox(height: Spacing.xl),
          KineticButton(
            label: 'GUARDAR',
            icon: Icons.check_rounded,
            onTap: _submit,
          ),
        ],
      ),
    );
  }

  static String _formatRest(int secs) {
    if (secs < 60) return '${secs}s';
    final m = secs ~/ 60;
    final s = secs % 60;
    return s == 0 ? '${m}min' : '${m}m ${s}s';
  }
}
