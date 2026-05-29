import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/exercise.dart';

part 'routine_day.freezed.dart';

@freezed
abstract class RoutineDay with _$RoutineDay {
  const RoutineDay._();

  const factory RoutineDay({
    required String id,
    required String routineId,
    required int dayOfWeek, // 1=Lunes, 7=Domingo
    required String name, // "Pecho y Tríceps"
    @Default([]) List<Exercise> exercises,
    @Default(0) int targetSetsCount,
    @Default(WorkoutDayStatus.pending) WorkoutDayStatus status,

    /// Nombres de los ejercicios del día, en orden, sin metadata adicional.
    /// Lo popula `getRoutineDays` para que `RoutineDayCard` pueda pintar un
    /// preview ("Press banca · Press militar · …") sin tener que cargar el
    /// día completo. Vacío cuando el day se construyó desde un contexto que
    /// no necesita preview.
    @Default([]) List<String> exerciseNamesPreview,
  }) = _RoutineDay;

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
}

enum WorkoutDayStatus {
  completed, // Sesión finalizada esta semana ✅
  completedPartial, // Sesión finalizada sin completar todas las series ⚠️
  inProgress, // Sesión iniciada pero no terminada ⏱️
  pending, // No hay sesión aún ⬜
  rest, // No hay entrenamiento este día
}
