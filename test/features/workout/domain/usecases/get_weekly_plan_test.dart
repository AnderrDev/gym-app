import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gym_flutter/features/workout/domain/usecases/get_weekly_plan.dart';
import 'package:gym_flutter/core/error/failures.dart';
import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/entities/workout_session.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockWorkoutRepository mockRepository;
  late GetWeeklyPlan usecase;

  setUp(() {
    mockRepository = MockWorkoutRepository();
    usecase = GetWeeklyPlan(mockRepository);
  });

  test('retorna lista vacia si no hay dias', () async {
    when(
      () => mockRepository.getRoutineDays('r1'),
    ).thenAnswer((_) async => const Right(<RoutineDay>[]));

    final result = await usecase(
      userId: 'user-1',
      routineId: 'r1',
      weekStart: DateTime(2024, 1, 1),
    );

    expect(result, const Right(<RoutineDay>[]));
  });

  test('marca inProgress cuando hay sesion abierta', () async {
    final day = const RoutineDay(
      id: 'd1',
      routineId: 'r1',
      dayOfWeek: 1,
      name: 'Lunes',
      targetSetsCount: 6,
    );
    when(
      () => mockRepository.getRoutineDays('r1'),
    ).thenAnswer((_) async => Right([day]));
    when(
      () => mockRepository.getWeekSessions(
        'user-1',
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 7),
      ),
    ).thenAnswer(
      (_) async => Right([
        WorkoutSession(
          id: 's1',
          userId: 'user-1',
          routineDayId: 'd1',
          sessionDate: DateTime(2024, 1, 1),
          completedAt: null,
          completedSetsCount: 2,
          totalTargetSets: 6,
        ),
      ]),
    );

    final result = await usecase(
      userId: 'user-1',
      routineId: 'r1',
      weekStart: DateTime(2024, 1, 1),
    );

    final days = result.getOrElse((_) => []);
    expect(days.first.status, WorkoutDayStatus.inProgress);
  });

  test('marca completed cuando la sesion cerrada cumple objetivo', () async {
    final day = const RoutineDay(
      id: 'd1',
      routineId: 'r1',
      dayOfWeek: 1,
      name: 'Lunes',
      targetSetsCount: 4,
    );
    when(
      () => mockRepository.getRoutineDays('r1'),
    ).thenAnswer((_) async => Right([day]));
    when(
      () => mockRepository.getWeekSessions(
        'user-1',
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 7),
      ),
    ).thenAnswer(
      (_) async => Right([
        WorkoutSession(
          id: 's1',
          userId: 'user-1',
          routineDayId: 'd1',
          sessionDate: DateTime(2024, 1, 2),
          completedAt: DateTime(2024, 1, 2, 10),
          completedSetsCount: 4,
          totalTargetSets: 4,
        ),
      ]),
    );

    final result = await usecase(
      userId: 'user-1',
      routineId: 'r1',
      weekStart: DateTime(2024, 1, 1),
    );

    final days = result.getOrElse((_) => []);
    expect(days.first.status, WorkoutDayStatus.completed);
  });

  test(
    'marca completedPartial cuando la sesion cerrada no cumple objetivo',
    () async {
      final day = const RoutineDay(
        id: 'd1',
        routineId: 'r1',
        dayOfWeek: 1,
        name: 'Lunes',
        targetSetsCount: 5,
      );
      when(
        () => mockRepository.getRoutineDays('r1'),
      ).thenAnswer((_) async => Right([day]));
      when(
        () => mockRepository.getWeekSessions(
          'user-1',
          DateTime(2024, 1, 1),
          DateTime(2024, 1, 7),
        ),
      ).thenAnswer(
        (_) async => Right([
          WorkoutSession(
            id: 's1',
            userId: 'user-1',
            routineDayId: 'd1',
            sessionDate: DateTime(2024, 1, 3),
            completedAt: DateTime(2024, 1, 3, 10),
            completedSetsCount: 3,
            totalTargetSets: 5,
          ),
        ]),
      );

      final result = await usecase(
        userId: 'user-1',
        routineId: 'r1',
        weekStart: DateTime(2024, 1, 1),
      );

      final days = result.getOrElse((_) => []);
      expect(days.first.status, WorkoutDayStatus.completedPartial);
    },
  );

  test('retorna Failure cuando falla la carga de dias', () async {
    when(
      () => mockRepository.getRoutineDays('r1'),
    ).thenAnswer((_) async => const Left(ServerFailure('boom')));

    final result = await usecase(
      userId: 'user-1',
      routineId: 'r1',
      weekStart: DateTime(2024, 1, 1),
    );

    expect(result, const Left(ServerFailure('boom')));
  });
}
