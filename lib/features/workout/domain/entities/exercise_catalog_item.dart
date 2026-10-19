import 'package:equatable/equatable.dart';

/// Item del catálogo de ejercicios (lectura). No confundir con [Exercise], que
/// representa un ejercicio configurado dentro de un día de rutina (con sets,
/// reps, peso objetivo, etc.).
class ExerciseCatalogItem extends Equatable {
  const ExerciseCatalogItem({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.description,
  });

  final String id;
  final String name;
  final String muscleGroup;
  final String? description;

  @override
  List<Object?> get props => [id, name, muscleGroup, description];
}
