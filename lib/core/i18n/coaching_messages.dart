/// Códigos de recomendación que produce el motor de coaching.
///
/// Centralizados aquí para que la UI no tenga literales sueltos. Cuando se
/// migre a `.arb` (Fase 8), las claves van directo a un `AppLocalizations`.
class CoachingRecommendation {
  CoachingRecommendation._();

  static const String increaseWeight = 'INCREASE_WEIGHT';
  static const String decreaseWeight = 'DECREASE_WEIGHT';
  static const String increaseReps = 'INCREASE_REPS';
  static const String decreaseSets = 'DECREASE_SETS';
  static const String maintain = 'MAINTAIN';
  static const String maintainWeight = 'MANTAIN_WEIGHT'; // legacy spelling
}

/// Mensajes user-facing en español. Hay dos variantes para cubrir los dos
/// estilos del codebase: completo (con emoji + tono motivacional) y compacto
/// (sin emoji, una sola línea para usar dentro de cards).
class CoachingMessages {
  CoachingMessages._();

  /// Variante full con emoji — usada por `WorkoutPerformanceAnalyzer.
  /// friendlyRecommendation`.
  static String long(String code) {
    switch (code) {
      case CoachingRecommendation.increaseWeight:
        return '🔥 ¡Increíble! Sube un poco el peso el próximo día.';
      case CoachingRecommendation.maintainWeight:
      case CoachingRecommendation.maintain:
        return '✅ Buen trabajo. Mantén este peso para consolidar.';
      case CoachingRecommendation.decreaseWeight:
        return '⚠️ Baja un poco el peso para mejorar la técnica.';
      case CoachingRecommendation.increaseReps:
        return '💪 Casi lo tienes. Intenta hacer 1-2 reps más.';
      case CoachingRecommendation.decreaseSets:
        return '📉 Te has pasado un poco. Baja una serie para recuperar.';
      default:
        return code;
    }
  }

  /// Variante compacta — usada por `exercise_card._getFriendlyRecommendation`.
  static String short(String code) {
    switch (code) {
      case CoachingRecommendation.increaseWeight:
        return 'Sube el peso en la próxima sesión';
      case CoachingRecommendation.decreaseWeight:
        return 'Baja un poco el peso para mejorar la técnica';
      case CoachingRecommendation.increaseReps:
        return 'Intenta hacer mas repeticiones con este peso';
      case CoachingRecommendation.maintain:
      case CoachingRecommendation.maintainWeight:
        return 'Buen trabajo, mantén el peso actual';
      default:
        return code;
    }
  }
}
