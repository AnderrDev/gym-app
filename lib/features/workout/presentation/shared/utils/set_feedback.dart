import 'dart:math' as math;

import 'package:gym_flutter/features/workout/presentation/shared/utils/weight_format.dart';

/// Veredicto de una serie individual contra el objetivo del ejercicio.
enum SetOutcome {
  /// Peso por debajo del objetivo.
  belowTargetWeight,

  /// Peso igual al objetivo, reps por debajo.
  missedReps,

  /// Peso y reps exactamente en el objetivo.
  targetMet,

  /// Superó el objetivo (más peso con las reps completas, o más reps).
  exceededTarget,

  /// Subió el peso y perdió algunas reps — progresión normal.
  heavierConsolidate,

  /// Subió el peso pero las reps cayeron demasiado.
  heavierTooFewReps,
}

class SetFeedback {
  const SetFeedback(this.outcome, this.message);

  final SetOutcome outcome;
  final String message;
}

const double _weightEpsilon = 0.01;

/// Reps "muy bajas": mismo umbral que `generate_coaching_v1` usa para
/// recomendar `DECREASE_WEIGHT` (`max(4, 60% del objetivo)`).
bool isVeryLowReps(int reps, int targetReps) =>
    reps < math.max(4, targetReps * 0.6);

/// Evalúa una serie teniendo en cuenta la dirección del peso. Subir el peso
/// y perder algunas reps es progresión, no motivo para bajar: sólo se sugiere
/// volver al objetivo si las reps caen por debajo de [isVeryLowReps].
SetFeedback evaluateSet({
  required double weight,
  required int reps,
  required double targetWeight,
  required int targetReps,
}) {
  final hasWeightTarget = targetWeight > 0;
  final heavier = hasWeightTarget && weight > targetWeight + _weightEpsilon;
  final lighter = hasWeightTarget && weight < targetWeight - _weightEpsilon;
  final repsMet = reps >= targetReps;

  if (heavier) {
    final delta = formatWeight(weight - targetWeight);
    if (repsMet) {
      return SetFeedback(
        SetOutcome.exceededTarget,
        '🚀 ¡Subiste +$delta kg y completaste las $targetReps reps! '
        'Considera subir el objetivo.',
      );
    }
    if (!isVeryLowReps(reps, targetReps)) {
      return SetFeedback(
        SetOutcome.heavierConsolidate,
        '💪 Subiste +$delta kg sobre el objetivo. Es normal perder algunas '
        'reps: mantén ${formatWeight(weight)} kg hasta llegar a $targetReps.',
      );
    }
    return SetFeedback(
      SetOutcome.heavierTooFewReps,
      'Subiste +$delta kg pero hiciste $reps de $targetReps reps. Si la '
      'técnica se resiente, vuelve a ${formatWeight(targetWeight)} kg.',
    );
  }

  if (lighter) {
    return SetFeedback(
      SetOutcome.belowTargetWeight,
      'Por debajo del objetivo (${formatWeight(targetWeight)} kg). Prioriza '
      'la técnica e intenta acercarte en la próxima serie.',
    );
  }

  if (!repsMet) {
    final missing = targetReps - reps;
    final missingText = missing == 1
        ? 'Te faltó 1 rep'
        : 'Te faltaron $missing reps';
    return SetFeedback(
      SetOutcome.missedReps,
      isVeryLowReps(reps, targetReps)
          ? '$missingText. Descansa un poco más; si se repite, baja 2.5 kg.'
          : '$missingText. Descansa un poco más antes de la siguiente serie.',
    );
  }

  if (reps > targetReps) {
    return SetFeedback(
      SetOutcome.exceededTarget,
      '🚀 ¡Hiciste $reps reps, más que el objetivo! Pronto podrás subir '
      'el peso.',
    );
  }

  return const SetFeedback(
    SetOutcome.targetMet,
    '¡Excelente! Objetivo cumplido. ¡Mantenlo así!',
  );
}
