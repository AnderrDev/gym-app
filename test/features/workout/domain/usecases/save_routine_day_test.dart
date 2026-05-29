import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_flutter/features/workout/domain/entities/routine_day.dart';
import 'package:gym_flutter/features/workout/domain/usecases/save_routine_day.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockWorkoutRepository repository;
  late SaveRoutineDay usecase;

  const tDay = RoutineDay(
    id: '',
    routineId: 'r1',
    dayOfWeek: 1,
    name: 'Día 1',
  );
  const tSaved = RoutineDay(
    id: 'd1',
    routineId: 'r1',
    dayOfWeek: 1,
    name: 'Día 1',
  );

  setUpAll(() {
    registerFallbackValue(tDay);
  });

  setUp(() {
    repository = MockWorkoutRepository();
    usecase = SaveRoutineDay(repository);
  });

  test('delega en repository.saveRoutineDay y devuelve el día persistido',
      () async {
    when(
      () => repository.saveRoutineDay(any()),
    ).thenAnswer((_) async => const Right(tSaved));

    final result = await usecase(tDay);

    expect(result.isRight(), isTrue);
    result.fold((_) => fail('expected right'), (r) => expect(r.id, 'd1'));
    verify(() => repository.saveRoutineDay(tDay)).called(1);
  });
}
