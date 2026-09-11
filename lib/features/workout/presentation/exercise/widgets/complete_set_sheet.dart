import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gym_flutter/core/theme/theme_context.dart';
import 'package:gym_flutter/core/theme/tokens/radii.dart';
import 'package:gym_flutter/core/theme/tokens/spacing.dart';
import 'package:gym_flutter/core/ui/adaptive/adaptive_sheet.dart';
import 'package:gym_flutter/core/ui/atoms/app_button.dart';
import 'package:gym_flutter/core/ui/molecules/bottom_sheet_handle.dart';
import 'package:gym_flutter/features/workout/domain/entities/set_log.dart';
import 'package:gym_flutter/features/workout/presentation/exercise/widgets/exercise_set_row_parts.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/weight_format.dart';

/// Resultado del modal de serie. `null` (cerrar sin confirmar) = sin cambios.
sealed class CompleteSetResult {
  const CompleteSetResult();
}

class CompleteSetSave extends CompleteSetResult {
  const CompleteSetSave({required this.weight, required this.reps});

  final double weight;
  final int reps;
}

class CompleteSetUnsave extends CompleteSetResult {
  const CompleteSetUnsave();
}

/// Modal para confirmar peso y reps de una serie antes de registrarla.
/// Si la serie ya estaba completada, permite editarla o desmarcarla.
class CompleteSetSheet extends StatefulWidget {
  const CompleteSetSheet({
    super.key,
    required this.exerciseName,
    required this.setNumber,
    required this.targetSets,
    required this.targetWeight,
    required this.targetReps,
    required this.initialWeight,
    required this.initialReps,
    required this.isDone,
    this.lastPerformance,
  });

  final String exerciseName;
  final int setNumber;
  final int targetSets;
  final double targetWeight;
  final int targetReps;
  final double initialWeight;
  final int initialReps;
  final bool isDone;
  final SetLog? lastPerformance;

  static Future<CompleteSetResult?> show(
    BuildContext context, {
    required String exerciseName,
    required int setNumber,
    required int targetSets,
    required double targetWeight,
    required int targetReps,
    required double initialWeight,
    required int initialReps,
    required bool isDone,
    SetLog? lastPerformance,
  }) {
    return AdaptiveSheet.showRaw<CompleteSetResult>(
      context,
      builder: (_) => CompleteSetSheet(
        exerciseName: exerciseName,
        setNumber: setNumber,
        targetSets: targetSets,
        targetWeight: targetWeight,
        targetReps: targetReps,
        initialWeight: initialWeight,
        initialReps: initialReps,
        isDone: isDone,
        lastPerformance: lastPerformance,
      ),
    );
  }

  @override
  State<CompleteSetSheet> createState() => _CompleteSetSheetState();
}

class _CompleteSetSheetState extends State<CompleteSetSheet> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
      text: formatWeight(widget.initialWeight),
    )..addListener(_rebuild);
    _repsCtrl = TextEditingController(text: '${widget.initialReps}')
      ..addListener(_rebuild);
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  double get _weight =>
      double.tryParse(_weightCtrl.text.replaceAll(',', '.')) ?? 0;
  int get _reps => int.tryParse(_repsCtrl.text) ?? 0;

  // Misma regla que la fila inline anterior: no registrar sin peso o reps.
  bool get _isValid => _weight > 0 && _reps > 0;

  void _setText(TextEditingController ctrl, String text) {
    ctrl.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    HapticFeedback.selectionClick();
  }

  void _bumpWeight(double delta) =>
      _setText(_weightCtrl, formatWeight((_weight + delta).clamp(0, 9999)));

  void _bumpReps(int delta) =>
      _setText(_repsCtrl, '${(_reps + delta).clamp(0, 999)}');

  void _confirm() {
    if (!_isValid) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(CompleteSetSave(weight: _weight, reps: _reps));
  }

  void _unsave() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(const CompleteSetUnsave());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final last = widget.lastPerformance;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Radii.xxl),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        Spacing.xl,
        Spacing.md,
        Spacing.xl,
        Spacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BottomSheetHandle(topPadding: 0),
            const SizedBox(height: Spacing.lg),
            Text(
              'SERIE ${widget.setNumber} DE ${widget.targetSets}',
              style: context.text.labelMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(widget.exerciseName, style: context.text.headlineSmall),
            const SizedBox(height: Spacing.md),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                _InfoPill(
                  icon: Icons.flag_rounded,
                  label:
                      'Objetivo ${formatWeight(widget.targetWeight)} kg × '
                      '${widget.targetReps}',
                  color: colors.primary,
                ),
                if (last != null)
                  _InfoPill(
                    icon: Icons.history_rounded,
                    label:
                        'Última vez ${formatWeight(last.actualWeight)} kg × '
                        '${last.actualReps}',
                    color: colors.textSecondary,
                  ),
              ],
            ),
            const SizedBox(height: Spacing.xl),
            _StepperField(
              fieldKey: const ValueKey('complete_set_weight'),
              label: 'PESO',
              suffix: 'kg',
              controller: _weightCtrl,
              decimal: true,
              onMinus: () => _bumpWeight(-2.5),
              onPlus: () => _bumpWeight(2.5),
            ),
            const SizedBox(height: Spacing.sm),
            QuickStepStrip(
              steps: const [-2.5, -1, 1, 2.5],
              formatter: (v) {
                final s = formatWeight(v.abs());
                return v > 0 ? '+$s' : '-$s';
              },
              onTap: _bumpWeight,
            ),
            _WeightDeltaHint(weight: _weight, target: widget.targetWeight),
            const SizedBox(height: Spacing.lg),
            _StepperField(
              fieldKey: const ValueKey('complete_set_reps'),
              label: 'REPETICIONES',
              suffix: 'reps',
              controller: _repsCtrl,
              decimal: false,
              onMinus: () => _bumpReps(-1),
              onPlus: () => _bumpReps(1),
            ),
            const SizedBox(height: Spacing.xl),
            AppButton(
              key: const ValueKey('complete_set_confirm'),
              label: widget.isDone ? 'Guardar cambios' : 'Confirmar serie',
              icon: Icons.check_rounded,
              onPressed: _isValid ? _confirm : null,
            ),
            if (widget.isDone) ...[
              const SizedBox(height: Spacing.sm),
              AppButton(
                key: const ValueKey('complete_set_unsave'),
                label: 'Desmarcar serie',
                variant: AppButtonVariant.ghost,
                icon: Icons.undo_rounded,
                onPressed: _unsave,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: context.text.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo numérico grande con botones − / + a los lados.
class _StepperField extends StatelessWidget {
  const _StepperField({
    required this.fieldKey,
    required this.label,
    required this.suffix,
    required this.controller,
    required this.decimal,
    required this.onMinus,
    required this.onPlus,
  });

  final Key fieldKey;
  final String label;
  final String suffix;
  final TextEditingController controller;
  final bool decimal;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.text.labelMedium?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Row(
          children: [
            _RoundIconButton(icon: Icons.remove_rounded, onTap: onMinus),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: TextField(
                key: fieldKey,
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.numberWithOptions(decimal: decimal),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    decimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
                  ),
                ],
                style: context.text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: colors.background,
                  suffixText: suffix,
                  suffixStyle: context.text.labelMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.md,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: Spacing.md),
            _RoundIconButton(icon: Icons.add_rounded, onTap: onPlus),
          ],
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.primary.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: colors.primary),
        ),
      ),
    );
  }
}

/// Indica en vivo si el peso está por encima o por debajo del objetivo, para
/// que subir el peso se vea reconocido antes de confirmar.
class _WeightDeltaHint extends StatelessWidget {
  const _WeightDeltaHint({required this.weight, required this.target});

  final double weight;
  final double target;

  @override
  Widget build(BuildContext context) {
    final delta = weight - target;
    if (target <= 0 || weight <= 0 || delta.abs() < 0.01) {
      return const SizedBox.shrink();
    }
    final up = delta > 0;
    final color = up ? context.colors.success : context.colors.warning;
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Row(
        children: [
          Icon(
            up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            up
                ? '+${formatWeight(delta)} kg sobre el objetivo'
                : '-${formatWeight(-delta)} kg bajo el objetivo',
            style: context.text.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
