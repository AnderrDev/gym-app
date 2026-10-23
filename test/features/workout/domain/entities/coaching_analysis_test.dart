import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/workout/domain/entities/coaching_analysis.dart';

void main() {
  group('CoachingAnalysis.fromJson', () {
    test('lee la forma del servidor (snake_case)', () {
      final c = CoachingAnalysis.fromJson(const {
        'exercise_id': 'e1',
        'exercise_name': 'Press banca',
        'completed_sets': 3,
        'target_sets': 3,
        'weight_met': true,
        'reps_met': false,
        'recommendation': 'INCREASE_REPS',
        'feedback': 'Mantén el peso e intenta sumar repeticiones.',
        'performance_score': 0.88,
      });
      expect(c.exerciseId, 'e1');
      expect(c.completedSets, 3);
      expect(c.repsMet, isFalse);
      expect(c.recommendation, 'INCREASE_REPS');
      expect(c.performanceScore, 0.88);
      expect(c.hasActionableAdvice, isTrue);
    });

    test('tipos inesperados y campos nuevos no lanzan', () {
      final c = CoachingAnalysis.fromJson(const {
        'exercise_name': 42,
        'completed_sets': 3.0,
        'target_sets': '3',
        'weight_met': 'yes',
        'recommendation': 'INCREASE_WEIGHT',
        'suggested_weight': 42.5,
        'engine_version': '2.0',
      });
      expect(c.exerciseName, 'Ejercicio');
      expect(c.completedSets, 3);
      expect(c.targetSets, isNull);
      expect(c.weightMet, isNull);
      expect(c.recommendation, 'INCREASE_WEIGHT');
    });

    test('normaliza el formato viejo con frase y código invertidos', () {
      final c = CoachingAnalysis.fromJson(const {
        'exerciseName': 'Sentadilla',
        'recommendation': '¡SUPERACIÓN! Sube el peso.',
        'feedback': 'PROGRESSIVE_OVERLOAD',
      });
      expect(c.recommendation, 'PROGRESSIVE_OVERLOAD');
      expect(c.feedback, '¡SUPERACIÓN! Sube el peso.');
    });

    test('estados en curso del formato viejo no son accionables', () {
      final pending = CoachingAnalysis.fromJson(const {
        'recommendation': '',
        'feedback': 'PENDING',
      });
      expect(pending.recommendation, 'PENDING');
      expect(pending.feedback, isNull);
      expect(pending.hasActionableAdvice, isFalse);

      final inProgress = CoachingAnalysis.fromJson(const {
        'recommendation': 'Te faltan 2 series.',
        'feedback': 'IN_PROGRESS',
      });
      expect(inProgress.hasActionableAdvice, isFalse);
    });

    test('toJson → fromJson conserva el consejo', () {
      const original = CoachingAnalysis(
        exerciseId: 'e1',
        exerciseName: 'Remo',
        recommendation: 'MAINTAIN',
        feedback: 'Buen trabajo.',
        performanceScore: 0.9,
      );
      expect(CoachingAnalysis.fromJson(original.toJson()), original);
    });
  });
}
