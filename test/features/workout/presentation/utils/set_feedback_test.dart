import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/workout/presentation/shared/utils/set_feedback.dart';

void main() {
  SetFeedback eval(double weight, int reps) =>
      evaluateSet(weight: weight, reps: reps, targetWeight: 38, targetReps: 10);

  group('evaluateSet', () {
    test('subir el peso con reps completas → superó el objetivo', () {
      final f = eval(40, 10);
      expect(f.outcome, SetOutcome.exceededTarget);
      expect(f.message, contains('+2 kg'));
    });

    test('subir el peso perdiendo algunas reps → consolidar, no bajar', () {
      final f = eval(40, 8);
      expect(f.outcome, SetOutcome.heavierConsolidate);
      expect(f.message, contains('Subiste +2 kg'));
      expect(f.message.toLowerCase(), isNot(contains('baja')));
    });

    test('subir el peso con reps muy bajas → sugiere volver al objetivo', () {
      final f = eval(40, 4);
      expect(f.outcome, SetOutcome.heavierTooFewReps);
      expect(f.message, contains('vuelve a 38 kg'));
    });

    test('peso por debajo del objetivo', () {
      expect(eval(35, 10).outcome, SetOutcome.belowTargetWeight);
    });

    test('mismo peso, faltan reps', () {
      final f = eval(38, 9);
      expect(f.outcome, SetOutcome.missedReps);
      expect(f.message, startsWith('Te faltó 1 rep'));
    });

    test('mismo peso y reps → objetivo cumplido', () {
      expect(eval(38, 10).outcome, SetOutcome.targetMet);
    });

    test('mismo peso, más reps → superó el objetivo', () {
      expect(eval(38, 12).outcome, SetOutcome.exceededTarget);
    });

    test('sin peso objetivo (0) no compara peso', () {
      final f = evaluateSet(
        weight: 20,
        reps: 10,
        targetWeight: 0,
        targetReps: 10,
      );
      expect(f.outcome, SetOutcome.targetMet);
    });
  });
}
