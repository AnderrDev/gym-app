import 'package:flutter_test/flutter_test.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/presentation/dashboard/widgets/dashboard_weekly_view.dart';

void main() {
  RoutineDay day(
    int dow, {
    DateTime? last,
    WorkoutDayStatus status = WorkoutDayStatus.pending,
  }) => RoutineDay(
    id: 'd$dow',
    routineId: 'r1',
    dayOfWeek: dow,
    name: 'Día $dow',
    lastSessionDate: last,
    status: status,
  );

  // Miércoles 21-oct-2026.
  final wednesday = DateTime(2026, 10, 21);

  test('una sesión en curso manda sobre todo lo demás', () {
    final days = [
      day(1),
      day(5, last: wednesday, status: WorkoutDayStatus.inProgress),
    ];
    expect(recommendedDay(days, wednesday)?.id, 'd5');
  });

  test('el primer día pendiente a partir de hoy', () {
    final days = [day(1), day(3), day(5)];
    expect(recommendedDay(days, wednesday)?.id, 'd3');
  });

  test('si los de hoy en adelante están hechos, el primero pendiente', () {
    final days = [day(1), day(3, last: wednesday), day(5, last: wednesday)];
    expect(recommendedDay(days, wednesday)?.id, 'd1');
  });

  test('semana completa → ninguno', () {
    final days = [day(1, last: wednesday), day(3, last: wednesday)];
    expect(recommendedDay(days, wednesday), isNull);
  });
}
