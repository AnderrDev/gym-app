import 'package:equatable/equatable.dart';
import '../../domain/entities/exercise.dart';

class RoutineDay extends Equatable {
  final String id;
  final String routineId;
  final int dayOfWeek; // 1=Lunes, 7=Domingo
  final String name;   // "Pecho y Tríceps"
  final List<Exercise> exercises;
  final int targetSetsCount;
  final WorkoutDayStatus status;

  const RoutineDay({
    required this.id,
    required this.routineId,
    required this.dayOfWeek,
    required this.name,
    this.exercises = const [],
    this.targetSetsCount = 0,
    this.status = WorkoutDayStatus.pending,
  });

  RoutineDay copyWith({
    String? id,
    String? routineId,
    int? dayOfWeek,
    String? name,
    List<Exercise>? exercises,
    int? targetSetsCount,
    WorkoutDayStatus? status,
  }) {
    return RoutineDay(
      id: id ?? this.id,
      routineId: routineId ?? this.routineId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      targetSetsCount: targetSetsCount ?? this.targetSetsCount,
      status: status ?? this.status,
    );
  }

  String get dayName {
    const days = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[dayOfWeek];
  }

  String get dayNameFull {
    const days = ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return days[dayOfWeek];
  }

  @override
  List<Object?> get props => [id, routineId, dayOfWeek, name, exercises, targetSetsCount, status];
}

enum WorkoutDayStatus {
  completed,   // Sesión finalizada esta semana ✅
  completedPartial, // Sesión finalizada sin completar todas las series ⚠️
  inProgress,  // Sesión iniciada pero no terminada ⏱️
  pending,     // No hay sesión aún ⬜
  rest,        // No hay entrenamiento este día
}
