import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gym_flutter/core/forms/inputs/reps_input.dart';
import 'package:gym_flutter/core/forms/inputs/weight_input.dart';
import 'package:gym_flutter/core/ui/feedback/app_bottom_sheet.dart';
import 'package:gym_flutter/core/ui/feedback/app_snack_bar.dart';
import 'package:gym_flutter/core/theme/app_colors.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/molecules/app_form_field.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_workout/active_workout_bloc.dart';
import 'package:gym_flutter/features/workout/presentation/bloc/active_workout/active_workout_event.dart';

/// Bottom sheet para editar el objetivo de un ejercicio durante la sesión.
/// Reemplaza el `showDialog` de `exercise_card._showRemoteTargetEditor` que
/// fugaba `TextEditingController`s — ahora `AppFormField` los maneja y los
/// libera con `dispose`.
class RemoteTargetSheet extends StatefulWidget {
  const RemoteTargetSheet({
    super.key,
    required this.exerciseId,
    required this.initialWeight,
    required this.initialReps,
  });

  final String exerciseId;
  final double initialWeight;
  final int initialReps;

  static Future<void> show(
    BuildContext context, {
    required String exerciseId,
    required double initialWeight,
    required int initialReps,
  }) {
    return AppBottomSheet.showRaw<void>(
      context,
      builder: (_) => BlocProvider.value(
        value: context.read<ActiveWorkoutBloc>(),
        child: RemoteTargetSheet(
          exerciseId: exerciseId,
          initialWeight: initialWeight,
          initialReps: initialReps,
        ),
      ),
    );
  }

  @override
  State<RemoteTargetSheet> createState() => _RemoteTargetSheetState();
}

class _RemoteTargetSheetState extends State<RemoteTargetSheet> {
  late WeightInput _weight;
  late RepsInput _reps;

  @override
  void initState() {
    super.initState();
    _weight = WeightInput.dirty(widget.initialWeight.toStringAsFixed(0));
    _reps = RepsInput.dirty(widget.initialReps.toString());
  }

  bool get _isValid => _weight.isValid && _reps.isValid;

  void _onSubmit() {
    if (!_isValid) return;
    final w = _weight.parsed ?? widget.initialWeight;
    final r = _reps.parsed ?? widget.initialReps;
    context.read<ActiveWorkoutBloc>().add(
      UpdateActiveExerciseTarget(
        exerciseId: widget.exerciseId,
        targetWeight: w,
        targetReps: r,
      ),
    );
    Navigator.of(context).pop();
    AppSnackBar.success(context, 'Objetivo actualizado remotamente');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.lg,
        Spacing.xl,
        Spacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Text('Cambiar objetivo remoto', style: textTheme.headlineSmall),
            const SizedBox(height: Spacing.xs),
            Text(
              'Ajustá el peso y las reps para el resto de la sesión.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: Spacing.lg),
            AppFormField(
              label: 'Nuevo peso (kg)',
              value: _weight.value,
              onChanged: (v) => setState(() => _weight = WeightInput.dirty(v)),
              errorText: _weight.isPure ? null : _weight.error?.message,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.fitness_center_rounded,
            ),
            const SizedBox(height: Spacing.lg),
            AppFormField(
              label: 'Nuevas reps',
              value: _reps.value,
              onChanged: (v) => setState(() => _reps = RepsInput.dirty(v)),
              errorText: _reps.isPure ? null : _reps.error?.message,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _onSubmit(),
              prefixIcon: Icons.repeat_rounded,
            ),
            const SizedBox(height: Spacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isValid ? _onSubmit : null,
                    child: const Text('Actualizar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
