import 'package:equatable/equatable.dart';
import '../../domain/entities/exercise.dart';

class RoutineDay extends Equatable {
  final String id;
  final String routineId;
  final int dayOfWeek; // 1=Lunes, 7=Domingo
  final String name; // "Pecho y Tríceps"
  final List<Exercise> exercises;
  final int targetSetsCount;
  final WorkoutDayStatus status;

  /// Nombres de los ejercicios del día, en orden, sin metadata adicional.
  /// Lo popula `getRoutineDays` para que `RoutineDayCard` pueda pintar un
  /// preview ("Press banca · Press militar · …") sin tener que cargar el
  /// día completo. Vacío cuando el day se construyó desde un contexto que
  /// no necesita preview.
  final List<String> exerciseNamesPreview;

  const RoutineDay({
    required this.id,
    required this.routineId,
    required this.dayOfWeek,
    required this.name,
    this.exercises = const [],
    this.targetSetsCount = 0,
    this.status = WorkoutDayStatus.pending,
    this.exerciseNamesPreview = const [],
  });

  RoutineDay copyWith({
    String? id,
    String? routineId,
    int? dayOfWeek,
    String? name,
    List<Exercise>? exercises,
    int? targetSetsCount,
    WorkoutDayStatus? status,
    List<String>? exerciseNamesPreview,
  }) {
    return RoutineDay(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      targetSetsCount: targetSetsCount ?? this.targetSetsCount,
      status: status ?? this.status,
      exerciseNamesPreview:
          exerciseNamesPreview ?? this.exerciseNamesPreview,
    );
  }

  String get dayName {
    const days = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[dayOfWeek];
  }

  String get dayNameFull {
    const days = [
      '',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return days[dayOfWeek];
  }

  @override
  List<Object?> get props => [
    id,
    routineId,
    dayOfWeek,
    name,
    exercises,
    targetSetsCount,
    status,
    exerciseNamesPreview,
  ];
}

enum WorkoutDayStatus {
  completed, // Sesión finalizada esta semana ✅
  completedPartial, // Sesión finalizada sin completar todas las series ⚠️
  inProgress, // Sesión iniciada pero no terminada ⏱️
  pending, // No hay sesión aún ⬜
  rest, // No hay entrenamiento este día
}
