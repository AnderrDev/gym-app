import 'package:equatable/equatable.dart';

/// Detalle enriquecido de un ejercicio del catálogo: media (imagen/animación/
/// video), instrucciones y consejos. Distinto de [ExerciseCatalogItem] (listado
/// resumido) y [Exercise] (instancia dentro de un día de rutina con targets).
///
/// Todos los campos opcionales pueden estar `null`: una entrada del catálogo
/// puede no tener foto, ni instrucciones, ni nivel de dificultad — la UI
/// debe degradar elegantemente.
class ExerciseDetail extends Equatable {
  const ExerciseDetail({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.description,
    this.imageUrl,
    this.animationUrl,
    this.videoUrl,
    this.instructions,
    this.tips,
    this.equipment,
    this.difficulty,
  });

  final String id;
  final String name;
  final String muscleGroup;

  /// Cue corto que ya existía en la tabla (ej. "Barra libre"). Lo conservamos
  /// como subtítulo rápido — los pasos detallados van en [instructions].
  final String? description;

  /// URL pública de imagen estática (PNG/JPG/WEBP). Sirve de preview y de
  /// fallback cuando no hay [animationUrl].
  final String? imageUrl;

  /// URL pública de GIF/MP4 corto demostrando el movimiento. Es el hero del
  /// detalle cuando existe.
  final String? animationUrl;

  /// URL externa (YouTube, etc.) para tutorial extendido. Se renderiza como
  /// CTA secundario "Ver tutorial".
  final String? videoUrl;

  /// Pasos para ejecutar. Markdown-lite: párrafos separados por blank line,
  /// bullets con prefijo "- " o "* ".
  final String? instructions;

  /// Consejos / errores comunes. Misma sintaxis que [instructions].
  final String? tips;

  /// Equipo necesario, ej. "Barra olímpica", "Mancuernas", "Polea alta".
  final String? equipment;

  /// "principiante" | "intermedio" | "avanzado" (validado a nivel SQL).
  final String? difficulty;

  /// `true` cuando hay al menos una pieza de contenido más allá de los
  /// campos básicos del catálogo. La UI lo usa para decidir si vale la pena
  /// abrir el detalle o si la pantalla quedaría vacía.
  bool get hasRichContent =>
      imageUrl != null ||
      animationUrl != null ||
      videoUrl != null ||
      (instructions?.trim().isNotEmpty ?? false) ||
      (tips?.trim().isNotEmpty ?? false);

  @override
  List<Object?> get props => [
        id,
        name,
        muscleGroup,
        description,
        imageUrl,
        animationUrl,
        videoUrl,
        instructions,
        tips,
        equipment,
        difficulty,
      ];
}
