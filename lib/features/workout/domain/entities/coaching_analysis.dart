import 'package:equatable/equatable.dart';

class CoachingAnalysis extends Equatable {
  final String? exerciseId;
  final String exerciseName;
  final int? completedSets;
  final int? targetSets;
  final bool? weightMet;
  final bool? repsMet;
  final String recommendation;
  final String? feedback;
  final double? performanceScore;

  const CoachingAnalysis({
    this.exerciseId,
    required this.exerciseName,
    this.completedSets,
    this.targetSets,
    this.weightMet,
    this.repsMet,
    required this.recommendation,
    this.feedback,
    this.performanceScore,
  });

  /// Lectura tolerante: un campo con tipo inesperado se descarta en vez de
  /// lanzar `TypeError`, para que un cambio aditivo del servidor (o un dato
  /// viejo) no rompa la carga de toda la sesión.
  factory CoachingAnalysis.fromJson(Map<String, dynamic> json) {
    Object? read(String camel, String snake) => json[camel] ?? json[snake];
    String? str(Object? v) => v is String ? v : null;
    int? integer(Object? v) => v is num ? v.toInt() : null;
    bool? boolean(Object? v) => v is bool ? v : null;

    var recommendation = str(json['recommendation']) ?? '';
    var feedback = str(json['feedback']);
    // Clientes viejos guardaban la frase en `recommendation` y el código en
    // `feedback`: se normaliza a la forma del servidor.
    if (!_isCode(recommendation) && feedback != null && _isCode(feedback)) {
      final code = feedback;
      feedback = recommendation.isEmpty ? null : recommendation;
      recommendation = code;
    }

    return CoachingAnalysis(
      exerciseId: str(read('exerciseId', 'exercise_id')),
      exerciseName: str(read('exerciseName', 'exercise_name')) ?? 'Ejercicio',
      completedSets: integer(read('completedSets', 'completed_sets')),
      targetSets: integer(read('targetSets', 'target_sets')),
      weightMet: boolean(read('weightMet', 'weight_met')),
      repsMet: boolean(read('repsMet', 'reps_met')),
      recommendation: recommendation,
      feedback: feedback,
      performanceScore: switch (read('performanceScore', 'performance_score')) {
        final num n => n.toDouble(),
        _ => null,
      },
    );
  }

  static final _codePattern = RegExp(r'^[A-Z_]+$');
  static bool _isCode(String value) => _codePattern.hasMatch(value);

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'completedSets': completedSets,
      'targetSets': targetSets,
      'weightMet': weightMet,
      'repsMet': repsMet,
      'recommendation': recommendation,
      'feedback': feedback,
      'performanceScore': performanceScore,
    };
  }

  /// Indica si este coaching aporta una recomendación accionable. Sin código
  /// (ejercicio sin series todavía) o con `PENDING`/`IN_PROGRESS` (workout en
  /// curso, no hay veredicto final) es ruido visual durante la sesión activa.
  bool get hasActionableAdvice =>
      recommendation.isNotEmpty &&
      recommendation != 'PENDING' &&
      recommendation != 'IN_PROGRESS';

  @override
  List<Object?> get props => [
    exerciseId,
    exerciseName,
    completedSets,
    targetSets,
    weightMet,
    repsMet,
    recommendation,
    feedback,
    performanceScore,
  ];
}
