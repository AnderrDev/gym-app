import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gym_flutter/features/workout/domain/usecases/delete_routine_day.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockWorkoutRepository repository;
  late DeleteRoutineDay usecase;

  setUp(() {
    repository = MockWorkoutRepository();
    usecase = DeleteRoutineDay(repository);
  });

  test('delega en repository.deleteRoutineDay', () async {
    when(
      () => repository.deleteRoutineDay('d1'),
    ).thenAnswer((_) async => const Right(null));

    final result = await usecase('d1');

    expect(result.isRight(), isTrue);
    verify(() => repository.deleteRoutineDay('d1')).called(1);
  });
}
